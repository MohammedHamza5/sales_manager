import 'dart:convert';
import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/money/money.dart';
import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../../../../core/sync/sync_dispatcher.dart';
import '../../domain/entities/customer_return.dart';
import '../../domain/entities/customer_return_item.dart';
import '../../domain/entities/supplier_return.dart';
import '../../domain/entities/supplier_return_item.dart';
import '../../domain/repositories/return_repository.dart';
import '../daos/returns_dao.dart';
import '../models/return_mapper.dart';

class ReturnRepositoryImpl implements ReturnRepository {
  final AppDatabase _db;
  final ReturnsDao _dao;
  final SyncDispatcher? _syncDispatcher;

  ReturnRepositoryImpl({
    required AppDatabase db,
    required ReturnsDao dao,
    SyncDispatcher? syncDispatcher,
  })  : _db = db,
        _dao = dao,
        _syncDispatcher = syncDispatcher;

  // -------------------------------------------------------------
  // CUSTOMER RETURNS
  // -------------------------------------------------------------

  @override
  Future<Result<CustomerReturn>> createCustomerReturn(
    CreateCustomerReturnParams params,
  ) async {
    try {
      return await _db.transaction(() async {
        final now = DateTime.now();

        // 1. Verify customer exists
        final customerEntry = await (_db.select(_db.customers)
              ..where((tbl) => tbl.id.equals(params.customerId)))
            .getSingleOrNull();

        if (customerEntry == null) {
          return const FailureResult(
            NotFoundFailure(message: 'العميل المحدد غير موجود في النظام'),
          );
        }

        // 2. Fetch and verify products
        final productEntries = <int, ProductEntry>{};
        for (final item in params.items) {
          final p = await (_db.select(_db.products)
                ..where((tbl) => tbl.id.equals(item.productId)))
              .getSingleOrNull();

          if (p == null) {
            return FailureResult(
              NotFoundFailure(
                message: 'المنتج برقم ${item.productId} غير موجود في النظام',
              ),
            );
          }
          productEntries[item.productId] = p;
        }

        // 3. Verify original sale if specified
        int? originalInvoiceNo;
        if (params.originalSaleId != null) {
          final saleEntry = await (_db.select(_db.sales)
                ..where((tbl) => tbl.id.equals(params.originalSaleId!)))
              .getSingleOrNull();
          if (saleEntry != null) {
            originalInvoiceNo = saleEntry.invoiceNo;
          }
        }

        // 4. Financial verification: verify cashbox balance BEFORE modifying database
        final refundCash = params.refundCashAmount;
        final totalPiastres = params.totalAmount.piastres;
        if (refundCash.piastres > totalPiastres) {
          return FailureResult(
            ValidationFailure(
              field: 'cashAmount',
              message:
                  'المبلغ النقدي المطلوب صرفه (${refundCash.formatArabic()}) لا يمكن أن يتجاوز إجمالي قيمة المرتجع (${params.totalAmount.formatArabic()})',
            ),
          );
        }
        final cashPiastres = refundCash.piastres;
        final creditPiastres = totalPiastres - cashPiastres;

        int currentCashbox = 0;
        if (cashPiastres > 0) {
          final latestTx = await (_db.select(_db.cashboxTransactions)
                ..orderBy([(t) => OrderingTerm.desc(t.id)])
                ..limit(1))
              .getSingleOrNull();
          currentCashbox = latestTx?.balanceAfter ?? 0;
          if (currentCashbox < cashPiastres) {
            return FailureResult(
              ValidationFailure(
                field: 'cashAmount',
                message:
                    'رصيد الخزينة الحالي (${Money.fromPiastres(currentCashbox).formatArabic()}) لا يكفي لصرف مبلغ المرتجع نقداً (${Money.fromPiastres(cashPiastres).formatArabic()})',
              ),
            );
          }
        }

        // 5. Insert returns_customer row
        final returnCompanion = ReturnMapper.customerReturnToCompanion(
          originalSaleId: params.originalSaleId,
          customerId: params.customerId,
          returnDate: params.returnDate,
          totalAmount: params.totalAmount,
          note: params.note,
          createdAt: now,
          createdBy: params.createdBy,
        );
        final returnId = await _dao.insertCustomerReturn(returnCompanion);

        // 6. Insert return items and increase stock
        final domainItems = <CustomerReturnItem>[];
        for (final item in params.items) {
          final currentProduct = productEntries[item.productId]!;
          final newQuantity = currentProduct.currentQuantity + item.quantity;

          final itemId = await _dao.insertCustomerReturnItem(
            ReturnMapper.customerReturnItemToCompanion(
              returnId: returnId,
              itemParam: item,
            ),
          );

          // Inventory movement: customer_return (positive)
          await _db.into(_db.inventoryMovements).insert(
                InventoryMovementsCompanion.insert(
                  productId: item.productId,
                  movementType: 'customer_return',
                  quantityDelta: item.quantity,
                  balanceAfter: newQuantity,
                  referenceType: const Value('customer_return'),
                  referenceId: Value(returnId),
                  note: Value('مرتجع عميل إذن رقم $returnId'),
                  createdAt: Value(now),
                  createdBy: Value(params.createdBy),
                ),
              );

          // Update product current_quantity
          await (_db.update(_db.products)
                ..where((tbl) => tbl.id.equals(item.productId)))
              .write(ProductsCompanion(currentQuantity: Value(newQuantity)));

          domainItems.add(
            CustomerReturnItem(
              id: itemId,
              returnId: returnId,
              productId: item.productId,
              productName: currentProduct.name,
              productCode: currentProduct.code ?? '',
              productUnit: currentProduct.unit,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
              lineTotal: item.lineTotal,
            ),
          );
        }

        // 7. Execute Financial settlement
        // a. If cash was refunded, insert customer_return_out
        if (cashPiastres > 0) {
          final newCashboxBalance = currentCashbox - cashPiastres;
          await _db.into(_db.cashboxTransactions).insert(
                CashboxTransactionsCompanion.insert(
                  transactionType: 'customer_return_out',
                  amount: cashPiastres,
                  direction: 'out',
                  balanceAfter: newCashboxBalance,
                  referenceType: const Value('customer_return'),
                  referenceId: Value(returnId),
                  note: Value('صرف نقدي لمرتجع مبيعات إذن #$returnId للعميل ${customerEntry.name}'),
                  createdAt: Value(now),
                  createdBy: Value(params.createdBy),
                ),
              );
        }

        // b. If credit to customer balance > 0
        if (creditPiastres > 0) {
          final newCustomerBalance =
              customerEntry.currentBalance - creditPiastres;

          await _db.into(_db.customerLedgerEntries).insert(
                CustomerLedgerEntriesCompanion.insert(
                  customerId: params.customerId,
                  entryType: 'return',
                  amount: creditPiastres,
                  effect: 'decrease',
                  balanceAfter: newCustomerBalance,
                  referenceType: const Value('customer_return'),
                  referenceId: Value(returnId),
                  note: Value(cashPiastres > 0
                      ? 'مرتجع مبيعات إذن #$returnId (تسوية رصيد بعد صرف نقدي)'
                      : 'مرتجع مبيعات إذن رقم #$returnId'),
                  createdAt: Value(now),
                  createdBy: Value(params.createdBy),
                ),
              );

          await (_db.update(_db.customers)
                ..where((tbl) => tbl.id.equals(params.customerId)))
              .write(
            CustomersCompanion(currentBalance: Value(newCustomerBalance)),
          );
        }

        // 7. Audit log
        await _db.into(_db.auditLog).insert(
              AuditLogCompanion.insert(
                entityType: 'customer_return',
                entityId: returnId,
                action: 'create',
                payloadAfter: Value(
                  jsonEncode({
                    'return_id': returnId,
                    'customer_id': params.customerId,
                    'original_sale_id': params.originalSaleId,
                    'total_amount': params.totalAmount.piastres,
                    'items_count': params.items.length,
                  }),
                ),
                performedAt: Value(now),
                userId: Value(params.createdBy),
              ),
            );

        // 8. Cloud Sync Outbox Dispatch
        if (_syncDispatcher != null) {
          await _syncDispatcher.dispatchInsert(
            entityType: 'returns_customer',
            localId: returnId,
            data: {
              'customer_id': SyncDispatcher.getEntityUuid('customer', params.customerId),
              if (params.originalSaleId != null)
                'original_sale_id': SyncDispatcher.getEntityUuid('sale', params.originalSaleId!),
              'return_date': params.returnDate.toIso8601String(),
              'total_amount': params.totalAmount.piastres,
              'note': params.note,
              'created_by': params.createdBy,
            },
          );

          for (final item in domainItems) {
            await _syncDispatcher.dispatchInsert(
              entityType: 'return_customer_item',
              localId: item.id,
              data: {
                'return_id': SyncDispatcher.getEntityUuid('returns_customer', returnId),
                'product_id': SyncDispatcher.getEntityUuid('product', item.productId),
                'quantity': item.quantity.toDouble(),
                'unit_price': item.unitPrice.piastres,
                'line_total': item.lineTotal.piastres,
              },
            );
          }

          for (final item in params.items) {
            final p = productEntries[item.productId]!;
            final newQ = p.currentQuantity + item.quantity;
            await _syncDispatcher.dispatchUpdate(
              entityType: 'product',
              localId: item.productId,
              data: {'current_quantity': newQ.toDouble()},
            );
          }

          if (creditPiastres > 0) {
            final newBalance = customerEntry.currentBalance - creditPiastres;
            await _syncDispatcher.dispatchUpdate(
              entityType: 'customer',
              localId: params.customerId,
              data: {'current_balance': newBalance},
            );
          }
        }

        final createdReturnEntry = await (_db.select(_db.returnsCustomer)
              ..where((tbl) => tbl.id.equals(returnId)))
            .getSingle();

        return Success(
          ReturnMapper.customerReturnToDomain(
            createdReturnEntry,
            customerName: customerEntry.name,
            originalInvoiceNo: originalInvoiceNo,
            items: domainItems,
          ),
        );
      });
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في حفظ مرتجع العميل',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Future<Result<List<CustomerReturn>>> getCustomerReturns({
    int? customerId,
    DateTime? fromDate,
    DateTime? toDate,
    String? query,
  }) async {
    try {
      final rows = await _dao.getCustomerReturnsList(
        customerId: customerId,
        fromDate: fromDate,
        toDate: toDate,
        query: query,
      );

      final list = <CustomerReturn>[];
      for (final row in rows) {
        final entry = row.readTable(_db.returnsCustomer);
        final customer = row.readTable(_db.customers);
        final sale = row.readTableOrNull(_db.sales);

        list.add(
          ReturnMapper.customerReturnToDomain(
            entry,
            customerName: customer.name,
            originalInvoiceNo: sale?.invoiceNo,
          ),
        );
      }

      return Success(list);
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في جلب قائمة مرتجعات العملاء',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Stream<List<CustomerReturn>> watchCustomerReturns({
    int? customerId,
    DateTime? fromDate,
    DateTime? toDate,
    String? query,
  }) {
    return _dao
        .watchCustomerReturnsList(
          customerId: customerId,
          fromDate: fromDate,
          toDate: toDate,
          query: query,
        )
        .map((rows) {
      return rows.map((row) {
        final entry = row.readTable(_db.returnsCustomer);
        final customer = row.readTable(_db.customers);
        final sale = row.readTableOrNull(_db.sales);

        return ReturnMapper.customerReturnToDomain(
          entry,
          customerName: customer.name,
          originalInvoiceNo: sale?.invoiceNo,
        );
      }).toList();
    });
  }

  // -------------------------------------------------------------
  // SUPPLIER RETURNS
  // -------------------------------------------------------------

  @override
  Future<Result<SupplierReturn>> createSupplierReturn(
    CreateSupplierReturnParams params,
  ) async {
    try {
      return await _db.transaction(() async {
        final now = DateTime.now();

        // 1. Verify supplier exists
        final supplierEntry = await (_db.select(_db.suppliers)
              ..where((tbl) => tbl.id.equals(params.supplierId)))
            .getSingleOrNull();

        if (supplierEntry == null) {
          return const FailureResult(
            NotFoundFailure(message: 'المورد المحدد غير موجود في النظام'),
          );
        }

        // 2. Fetch and strictly verify products and stock levels
        final productEntries = <int, ProductEntry>{};
        for (final item in params.items) {
          final p = await (_db.select(_db.products)
                ..where((tbl) => tbl.id.equals(item.productId)))
              .getSingleOrNull();

          if (p == null) {
            return FailureResult(
              NotFoundFailure(
                message: 'المنتج برقم ${item.productId} غير موجود في النظام',
              ),
            );
          }

          // STRICT NEGATIVE STOCK PREVENTION: cannot return more than available
          if (item.quantity > p.currentQuantity) {
            return FailureResult(
              InsufficientStockFailure(
                productName: p.name,
                requestedQuantity: item.quantity.toString(),
                availableQuantity: p.currentQuantity.toString(),
                message:
                    'الكمية المراد إرجاعها للمورد (${item.quantity}) للمنتج "${p.name}" تتجاوز الرصيد المتوفر بالمخزن (${p.currentQuantity})',
              ),
            );
          }

          productEntries[item.productId] = p;
        }

        // 3. Verify original purchase if specified
        int? originalInvoiceNo;
        if (params.originalPurchaseId != null) {
          final purchaseEntry = await (_db.select(_db.purchases)
                ..where((tbl) => tbl.id.equals(params.originalPurchaseId!)))
              .getSingleOrNull();
          if (purchaseEntry != null) {
            originalInvoiceNo = purchaseEntry.invoiceNo;
          }
        }

        // 4. Insert returns_supplier row
        final returnCompanion = ReturnMapper.supplierReturnToCompanion(
          originalPurchaseId: params.originalPurchaseId,
          supplierId: params.supplierId,
          returnDate: params.returnDate,
          totalAmount: params.totalAmount,
          note: params.note,
          createdAt: now,
          createdBy: params.createdBy,
        );
        final returnId = await _dao.insertSupplierReturn(returnCompanion);

        // 5. Insert return items and deduct stock
        final domainItems = <SupplierReturnItem>[];
        for (final item in params.items) {
          final currentProduct = productEntries[item.productId]!;
          final newQuantity = currentProduct.currentQuantity - item.quantity;

          final itemId = await _dao.insertSupplierReturnItem(
            ReturnMapper.supplierReturnItemToCompanion(
              returnId: returnId,
              itemParam: item,
            ),
          );

          // Inventory movement: supplier_return (negative delta)
          await _db.into(_db.inventoryMovements).insert(
                InventoryMovementsCompanion.insert(
                  productId: item.productId,
                  movementType: 'supplier_return',
                  quantityDelta: -item.quantity,
                  balanceAfter: newQuantity,
                  referenceType: const Value('supplier_return'),
                  referenceId: Value(returnId),
                  note: Value('مرتجع لمورد إذن رقم $returnId'),
                  createdAt: Value(now),
                  createdBy: Value(params.createdBy),
                ),
              );

          // Update product current_quantity
          await (_db.update(_db.products)
                ..where((tbl) => tbl.id.equals(item.productId)))
              .write(ProductsCompanion(currentQuantity: Value(newQuantity)));

          domainItems.add(
            SupplierReturnItem(
              id: itemId,
              returnId: returnId,
              productId: item.productId,
              productName: currentProduct.name,
              productCode: currentProduct.code ?? '',
              productUnit: currentProduct.unit,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
              lineTotal: item.lineTotal,
            ),
          );
        }

        // 6. Financial settlement: cash received into cashbox vs supplier dues reduction
        final refundCash = params.refundCashAmount;
        final totalPiastres = params.totalAmount.piastres;
        if (refundCash.piastres > totalPiastres) {
          return FailureResult(
            ValidationFailure(
              field: 'cashAmount',
              message:
                  'المبلغ النقدي المحصل (${refundCash.formatArabic()}) لا يمكن أن يتجاوز إجمالي قيمة المرتجع (${params.totalAmount.formatArabic()})',
            ),
          );
        }
        final cashPiastres = refundCash.piastres;
        final creditPiastres = totalPiastres - cashPiastres;

        // a. If cash was received from supplier into cashbox
        if (cashPiastres > 0) {
          final latestTx = await (_db.select(_db.cashboxTransactions)
                ..orderBy([(t) => OrderingTerm.desc(t.id)])
                ..limit(1))
              .getSingleOrNull();
          final currentCashbox = latestTx?.balanceAfter ?? 0;
          final newCashboxBalance = currentCashbox + cashPiastres;

          await _db.into(_db.cashboxTransactions).insert(
                CashboxTransactionsCompanion.insert(
                  transactionType: 'supplier_return_in',
                  amount: cashPiastres,
                  direction: 'in',
                  balanceAfter: newCashboxBalance,
                  referenceType: const Value('supplier_return'),
                  referenceId: Value(returnId),
                  note: Value('تحصيل نقدي لمرتجع مشتريات إذن #$returnId من المورد ${supplierEntry.name}'),
                  createdAt: Value(now),
                  createdBy: Value(params.createdBy),
                ),
              );
        }

        // b. If reduction of supplier balance > 0
        if (creditPiastres > 0) {
          final newSupplierBalance =
              supplierEntry.currentBalance - creditPiastres;

          await _db.into(_db.supplierLedgerEntries).insert(
                SupplierLedgerEntriesCompanion.insert(
                  supplierId: params.supplierId,
                  entryType: 'return',
                  amount: creditPiastres,
                  effect: 'decrease',
                  balanceAfter: newSupplierBalance,
                  referenceType: const Value('supplier_return'),
                  referenceId: Value(returnId),
                  note: Value(cashPiastres > 0
                      ? 'مرتجع مشتريات إذن #$returnId (تسوية رصيد بعد تحصيل نقدي)'
                      : 'مرتجع مشتريات إذن رقم #$returnId'),
                  createdAt: Value(now),
                  createdBy: Value(params.createdBy),
                ),
              );

          await (_db.update(_db.suppliers)
                ..where((tbl) => tbl.id.equals(params.supplierId)))
              .write(
            SuppliersCompanion(currentBalance: Value(newSupplierBalance)),
          );
        }

        // 7. Audit log
        await _db.into(_db.auditLog).insert(
              AuditLogCompanion.insert(
                entityType: 'supplier_return',
                entityId: returnId,
                action: 'create',
                payloadAfter: Value(
                  jsonEncode({
                    'return_id': returnId,
                    'supplier_id': params.supplierId,
                    'original_purchase_id': params.originalPurchaseId,
                    'total_amount': params.totalAmount.piastres,
                    'items_count': params.items.length,
                  }),
                ),
                performedAt: Value(now),
                userId: Value(params.createdBy),
              ),
            );

        // 8. Cloud Sync Outbox Dispatch
        if (_syncDispatcher != null) {
          await _syncDispatcher.dispatchInsert(
            entityType: 'returns_supplier',
            localId: returnId,
            data: {
              'supplier_id': SyncDispatcher.getEntityUuid('supplier', params.supplierId),
              if (params.originalPurchaseId != null)
                'original_purchase_id': SyncDispatcher.getEntityUuid('purchase', params.originalPurchaseId!),
              'return_date': params.returnDate.toIso8601String(),
              'total_amount': params.totalAmount.piastres,
              'note': params.note,
              'created_by': params.createdBy,
            },
          );

          for (final item in domainItems) {
            await _syncDispatcher.dispatchInsert(
              entityType: 'return_supplier_item',
              localId: item.id,
              data: {
                'return_id': SyncDispatcher.getEntityUuid('returns_supplier', returnId),
                'product_id': SyncDispatcher.getEntityUuid('product', item.productId),
                'quantity': item.quantity.toDouble(),
                'unit_price': item.unitPrice.piastres,
                'line_total': item.lineTotal.piastres,
              },
            );
          }

          for (final item in params.items) {
            final p = productEntries[item.productId]!;
            final newQ = p.currentQuantity - item.quantity;
            await _syncDispatcher.dispatchUpdate(
              entityType: 'product',
              localId: item.productId,
              data: {'current_quantity': newQ.toDouble()},
            );
          }

          if (creditPiastres > 0) {
            final newBalance = supplierEntry.currentBalance - creditPiastres;
            await _syncDispatcher.dispatchUpdate(
              entityType: 'supplier',
              localId: params.supplierId,
              data: {'current_balance': newBalance},
            );
          }
        }

        final createdReturnEntry = await (_db.select(_db.returnsSupplier)
              ..where((tbl) => tbl.id.equals(returnId)))
            .getSingle();

        return Success(
          ReturnMapper.supplierReturnToDomain(
            createdReturnEntry,
            supplierName: supplierEntry.name,
            originalInvoiceNo: originalInvoiceNo,
            items: domainItems,
          ),
        );
      });
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في حفظ مرتجع المورد',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Future<Result<List<SupplierReturn>>> getSupplierReturns({
    int? supplierId,
    DateTime? fromDate,
    DateTime? toDate,
    String? query,
  }) async {
    try {
      final rows = await _dao.getSupplierReturnsList(
        supplierId: supplierId,
        fromDate: fromDate,
        toDate: toDate,
        query: query,
      );

      final list = <SupplierReturn>[];
      for (final row in rows) {
        final entry = row.readTable(_db.returnsSupplier);
        final supplier = row.readTable(_db.suppliers);
        final purchase = row.readTableOrNull(_db.purchases);

        list.add(
          ReturnMapper.supplierReturnToDomain(
            entry,
            supplierName: supplier.name,
            originalInvoiceNo: purchase?.invoiceNo,
          ),
        );
      }

      return Success(list);
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في جلب قائمة مرتجعات الموردين',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Stream<List<SupplierReturn>> watchSupplierReturns({
    int? supplierId,
    DateTime? fromDate,
    DateTime? toDate,
    String? query,
  }) {
    return _dao
        .watchSupplierReturnsList(
          supplierId: supplierId,
          fromDate: fromDate,
          toDate: toDate,
          query: query,
        )
        .map((rows) {
      return rows.map((row) {
        final entry = row.readTable(_db.returnsSupplier);
        final supplier = row.readTable(_db.suppliers);
        final purchase = row.readTableOrNull(_db.purchases);

        return ReturnMapper.supplierReturnToDomain(
          entry,
          supplierName: supplier.name,
          originalInvoiceNo: purchase?.invoiceNo,
        );
      }).toList();
    });
  }
}
