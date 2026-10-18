import 'dart:convert';
import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/money/money.dart';
import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../../../../core/sync/sync_dispatcher.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/sale_item.dart';
import '../../domain/repositories/sale_repository.dart';
import '../daos/sales_dao.dart';
import '../models/sale_mapper.dart';

class SaleRepositoryImpl implements SaleRepository {
  final AppDatabase _db;
  final SalesDao _dao;
  final SyncDispatcher? _syncDispatcher;

  SaleRepositoryImpl({
    required AppDatabase db,
    required SalesDao dao,
    SyncDispatcher? syncDispatcher,
  })  : _db = db,
        _dao = dao,
        _syncDispatcher = syncDispatcher;

  @override
  Future<Result<Sale>> createSale(CreateSaleParams params) async {
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

          // STRICT NEGATIVE STOCK PREVENTION (Locked Decision #6)
          if (item.quantity > p.currentQuantity) {
            return FailureResult(
              InsufficientStockFailure(
                productName: p.name,
                requestedQuantity: item.quantity.toString(),
                availableQuantity: p.currentQuantity.toString(),
                message:
                    'الكمية المطلوبة (${item.quantity}) للمنتج "${p.name}" تتجاوز الرصيد المتاح (${p.currentQuantity}) بالمخزن',
              ),
            );
          }

          productEntries[item.productId] = p;
        }

        // 3. Compute next invoice number
        final invoiceNo = await _dao.getNextInvoiceNo();

        // 4. Insert sales header row
        final saleCompanion = SaleMapper.toCompanion(
          invoiceNo: invoiceNo,
          customerId: params.customerId,
          saleDate: params.saleDate,
          totalAmount: params.totalAmount,
          paidAmountAtCreation: params.paidAmountAtCreation,
          status: 'confirmed',
          note: params.note,
          createdAt: now,
          createdBy: params.createdBy,
        );
        final saleId = await _dao.insertSale(saleCompanion);

        // Dispatch sale header to Sync Queue
        await _syncDispatcher?.dispatchInsert(
          entityType: 'sale',
          localId: saleId,
          data: {
            'invoice_no': invoiceNo,
            'customer_id':
                SyncDispatcher.getEntityUuid('customer', params.customerId),
            'sale_date': params.saleDate.toIso8601String(),
            'total_amount': params.totalAmount.piastres,
            'paid_amount_at_creation': params.paidAmountAtCreation.piastres,
            'status': 'confirmed',
            'note': params.note,
            'created_at': now.toIso8601String(),
            'created_by': params.createdBy,
          },
        );

        // 5. Insert sale items & update product stock with inventory movement
        final domainItems = <SaleItem>[];
        for (final item in params.items) {
          final currentProduct = productEntries[item.productId]!;
          final newQuantity = currentProduct.currentQuantity - item.quantity;

          // a. Insert sale_items row
          final itemId = await _dao.insertSaleItem(
            SaleMapper.itemToCompanion(
              saleId: saleId,
              itemParam: item,
              createdAt: now,
            ),
          );

          // Dispatch sale item to Sync Queue
          await _syncDispatcher?.dispatchInsert(
            entityType: 'sale_item',
            localId: itemId,
            data: {
              'sale_id': SyncDispatcher.getEntityUuid('sale', saleId),
              'product_id':
                  SyncDispatcher.getEntityUuid('product', item.productId),
              'quantity': item.quantity.toDouble(),
              'unit_price_at_sale': item.unitPrice.piastres,
              'line_total': item.lineTotal.piastres,
              'created_at': now.toIso8601String(),
            },
          );

          // b. Insert inventory_movements (sale, negative delta)
          await _db.into(_db.inventoryMovements).insert(
                InventoryMovementsCompanion.insert(
                  productId: item.productId,
                  movementType: 'sale',
                  quantityDelta: -item.quantity,
                  balanceAfter: newQuantity,
                  referenceType: const Value('sale'),
                  referenceId: Value(saleId),
                  note: Value('فاتورة بيع رقم $invoiceNo'),
                  createdAt: Value(now),
                  createdBy: Value(params.createdBy),
                ),
              );

          // c. Atomically update product current_quantity
          await (_db.update(_db.products)
                ..where((tbl) => tbl.id.equals(item.productId)))
              .write(ProductsCompanion(currentQuantity: Value(newQuantity)));

          await _syncDispatcher?.dispatchUpdate(
            entityType: 'product',
            localId: item.productId,
            data: {
              'current_quantity': newQuantity.toDouble(),
            },
          );

          domainItems.add(
            SaleItem(
              id: itemId,
              saleId: saleId,
              productId: item.productId,
              productName: currentProduct.name,
              productCode: currentProduct.code ?? '',
              productUnit: currentProduct.unit,
              quantity: item.quantity,
              unitPriceAtSale: item.unitPrice,
              lineTotal: item.lineTotal,
              createdAt: now,
            ),
          );
        }

        // 6. Handle customer debt ledger entry if remaining > 0
        final remainingPiastres =
            params.totalAmount.piastres - params.paidAmountAtCreation.piastres;
        if (remainingPiastres > 0) {
          final newCustomerBalance =
              customerEntry.currentBalance + remainingPiastres;

          await _db.into(_db.customerLedgerEntries).insert(
                CustomerLedgerEntriesCompanion.insert(
                  customerId: params.customerId,
                  entryType: 'sale',
                  amount: remainingPiastres,
                  effect: 'increase',
                  balanceAfter: newCustomerBalance,
                  referenceType: const Value('sale'),
                  referenceId: Value(saleId),
                  note: Value('متبقي فاتورة بيع رقم $invoiceNo'),
                  createdAt: Value(now),
                  createdBy: Value(params.createdBy),
                ),
              );

          await (_db.update(_db.customers)
                ..where((tbl) => tbl.id.equals(params.customerId)))
              .write(
            CustomersCompanion(currentBalance: Value(newCustomerBalance)),
          );

          await _syncDispatcher?.dispatchUpdate(
            entityType: 'customer',
            localId: params.customerId,
            data: {
              'current_balance': newCustomerBalance,
            },
          );
        }

        // 7. Handle cashbox transaction if paidAmountAtCreation > 0
        if (params.paidAmountAtCreation.piastres > 0) {
          final lastCashboxTx = await (_db.select(_db.cashboxTransactions)
                ..orderBy([(tbl) => OrderingTerm(expression: tbl.id, mode: OrderingMode.desc)])
                ..limit(1))
              .getSingleOrNull();

          final currentCashboxBalance = lastCashboxTx?.balanceAfter ?? 0;
          final newCashboxBalance =
              currentCashboxBalance + params.paidAmountAtCreation.piastres;

          await _db.into(_db.cashboxTransactions).insert(
                CashboxTransactionsCompanion.insert(
                  transactionType: 'sale_cash_in',
                  amount: params.paidAmountAtCreation.piastres,
                  direction: 'in',
                  balanceAfter: newCashboxBalance,
                  referenceType: const Value('sale'),
                  referenceId: Value(saleId),
                  note: Value('تحصيل نقدي عند إنشاء فاتورة بيع رقم $invoiceNo'),
                  createdAt: Value(now),
                  createdBy: Value(params.createdBy),
                ),
              );
        }

        // 8. Record audit log
        await _db.into(_db.auditLog).insert(
              AuditLogCompanion.insert(
                entityType: 'sale',
                entityId: saleId,
                action: 'create',
                payloadAfter: Value(
                  jsonEncode({
                    'invoice_no': invoiceNo,
                    'customer_id': params.customerId,
                    'total_amount': params.totalAmount.piastres,
                    'paid_amount': params.paidAmountAtCreation.piastres,
                    'items_count': params.items.length,
                  }),
                ),
                performedAt: Value(now),
                userId: Value(params.createdBy),
              ),
            );

        // Fetch the created sale record
        final createdEntry = await (_db.select(_db.sales)
              ..where((tbl) => tbl.id.equals(saleId)))
            .getSingle();

        return Success(
          SaleMapper.toDomain(
            createdEntry,
            customerName: customerEntry.name,
            customerPhone: customerEntry.phone,
            items: domainItems,
          ),
        );
      });
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في حفظ فاتورة البيع',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Future<Result<List<Sale>>> getSales({
    int? customerId,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
    String? query,
  }) async {
    try {
      final rows = await _dao.getSalesList(
        customerId: customerId,
        fromDate: fromDate,
        toDate: toDate,
        status: status,
        query: query,
      );

      final allReturns = await _db.select(_db.returnsCustomer).get();
      final returnMap = <int, int>{};
      for (final r in allReturns) {
        if (r.originalSaleId != null) {
          returnMap[r.originalSaleId!] =
              (returnMap[r.originalSaleId!] ?? 0) + r.totalAmount;
        }
      }

      final salesList = <Sale>[];
      for (final row in rows) {
        final saleEntry = row.readTable(_db.sales);
        final customerEntry = row.readTable(_db.customers);
        final retPiastres = returnMap[saleEntry.id] ?? 0;
        salesList.add(
          SaleMapper.toDomain(
            saleEntry,
            customerName: customerEntry.name,
            customerPhone: customerEntry.phone,
            returnedAmount: Money.fromPiastres(retPiastres),
          ),
        );
      }

      return Success(salesList);
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في جلب قائمة المبيعات',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Stream<List<Sale>> watchSales({
    int? customerId,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
    String? query,
  }) {
    return _dao
        .watchSalesList(
          customerId: customerId,
          fromDate: fromDate,
          toDate: toDate,
          status: status,
          query: query,
        )
        .asyncMap((rows) async {
      final allReturns = await _db.select(_db.returnsCustomer).get();
      final returnMap = <int, int>{};
      for (final r in allReturns) {
        if (r.originalSaleId != null) {
          returnMap[r.originalSaleId!] =
              (returnMap[r.originalSaleId!] ?? 0) + r.totalAmount;
        }
      }

      return rows.map((row) {
        final saleEntry = row.readTable(_db.sales);
        final customerEntry = row.readTable(_db.customers);
        final retPiastres = returnMap[saleEntry.id] ?? 0;
        return SaleMapper.toDomain(
          saleEntry,
          customerName: customerEntry.name,
          customerPhone: customerEntry.phone,
          returnedAmount: Money.fromPiastres(retPiastres),
        );
      }).toList();
    });
  }

  @override
  Future<Result<Sale>> getSaleById(int id) async {
    try {
      final headerRow = await _dao.getSaleHeader(id);
      if (headerRow == null) {
        return const FailureResult(
          NotFoundFailure(message: 'فاتورة البيع غير موجودة'),
        );
      }

      final saleEntry = headerRow.readTable(_db.sales);
      final customerEntry = headerRow.readTable(_db.customers);

      final itemRows = await _dao.getSaleItems(id);
      final items = itemRows.map((row) {
        final itemEntry = row.readTable(_db.saleItems);
        final productEntry = row.readTable(_db.products);
        return SaleMapper.itemToDomain(
          itemEntry,
          productName: productEntry.name,
          productCode: productEntry.code ?? '',
          productUnit: productEntry.unit,
        );
      }).toList();

      final returnsForSale = await (_db.select(_db.returnsCustomer)
            ..where((tbl) => tbl.originalSaleId.equals(id)))
          .get();
      final totalRetPiastres =
          returnsForSale.fold<int>(0, (sum, r) => sum + r.totalAmount);

      return Success(
        SaleMapper.toDomain(
          saleEntry,
          customerName: customerEntry.name,
          customerPhone: customerEntry.phone,
          items: items,
          returnedAmount: Money.fromPiastres(totalRetPiastres),
        ),
      );
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في جلب تفاصيل الفاتورة',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Future<Result<Sale>> reverseSale(int saleId, {String? reason}) async {
    try {
      return await _db.transaction(() async {
        final now = DateTime.now();

        // 1. Fetch sale header
        final saleEntry = await (_db.select(_db.sales)
              ..where((tbl) => tbl.id.equals(saleId)))
            .getSingleOrNull();

        if (saleEntry == null) {
          return const FailureResult(
            NotFoundFailure(message: 'فاتورة البيع غير موجودة'),
          );
        }

        if (saleEntry.status == 'reversed') {
          return const FailureResult(
            ConflictFailure(message: 'تم إلغاء وعكس هذه الفاتورة مسبقاً'),
          );
        }

        // 2. Fetch customer
        final customerEntry = await (_db.select(_db.customers)
              ..where((tbl) => tbl.id.equals(saleEntry.customerId)))
            .getSingle();

        // 3. Fetch sale items
        final itemEntries = await (_db.select(_db.saleItems)
              ..where((tbl) => tbl.saleId.equals(saleId)))
            .get();

        // 4. Update status to 'reversed'
        await _dao.updateSaleStatus(saleId, 'reversed');

        // 5. Reverse inventory for each item
        for (final item in itemEntries) {
          final product = await (_db.select(_db.products)
                ..where((tbl) => tbl.id.equals(item.productId)))
              .getSingle();

          final restoredQuantity = product.currentQuantity + item.quantity;

          await _db.into(_db.inventoryMovements).insert(
                InventoryMovementsCompanion.insert(
                  productId: item.productId,
                  movementType: 'reversal',
                  quantityDelta: item.quantity,
                  balanceAfter: restoredQuantity,
                  referenceType: const Value('sale_reversal'),
                  referenceId: Value(saleId),
                  note: Value(
                    'إلغاء فاتورة بيع رقم ${saleEntry.invoiceNo}${reason != null ? ' - $reason' : ''}',
                  ),
                  createdAt: Value(now),
                  createdBy: const Value('admin'),
                ),
              );

          await (_db.update(_db.products)
                ..where((tbl) => tbl.id.equals(item.productId)))
              .write(
            ProductsCompanion(currentQuantity: Value(restoredQuantity)),
          );

          await _syncDispatcher?.dispatchUpdate(
            entityType: 'product',
            localId: item.productId,
            data: {
              'current_quantity': restoredQuantity.toDouble(),
            },
          );
        }

        // 6. Revert customer debt balance if remaining debt existed
        final remainingPiastres =
            saleEntry.totalAmount - saleEntry.paidAmountAtCreation;
        if (remainingPiastres > 0) {
          final newCustomerBalance =
              customerEntry.currentBalance - remainingPiastres;

          await _db.into(_db.customerLedgerEntries).insert(
                CustomerLedgerEntriesCompanion.insert(
                  customerId: saleEntry.customerId,
                  entryType: 'reversal',
                  amount: remainingPiastres,
                  effect: 'decrease',
                  balanceAfter: newCustomerBalance,
                  referenceType: const Value('sale_reversal'),
                  referenceId: Value(saleId),
                  note: Value('إلغاء أثر فاتورة بيع رقم ${saleEntry.invoiceNo}'),
                  createdAt: Value(now),
                  createdBy: const Value('admin'),
                ),
              );

          await (_db.update(_db.customers)
                ..where((tbl) => tbl.id.equals(saleEntry.customerId)))
              .write(
            CustomersCompanion(currentBalance: Value(newCustomerBalance)),
          );

          await _syncDispatcher?.dispatchUpdate(
            entityType: 'customer',
            localId: saleEntry.customerId,
            data: {
              'current_balance': newCustomerBalance,
            },
          );
        }

        // 7. Revert cashbox if cash was collected
        if (saleEntry.paidAmountAtCreation > 0) {
          final lastCashboxTx = await (_db.select(_db.cashboxTransactions)
                ..orderBy([(tbl) => OrderingTerm(expression: tbl.id, mode: OrderingMode.desc)])
                ..limit(1))
              .getSingleOrNull();

          final currentCashboxBalance = lastCashboxTx?.balanceAfter ?? 0;
          final newCashboxBalance =
              currentCashboxBalance - saleEntry.paidAmountAtCreation;

          await _db.into(_db.cashboxTransactions).insert(
                CashboxTransactionsCompanion.insert(
                  transactionType: 'sale_reverse_out',
                  amount: saleEntry.paidAmountAtCreation,
                  direction: 'out',
                  balanceAfter: newCashboxBalance,
                  referenceType: const Value('sale_reversal'),
                  referenceId: Value(saleId),
                  note: Value(
                    'استرداد نقدية لإلغاء فاتورة بيع رقم ${saleEntry.invoiceNo}',
                  ),
                  createdAt: Value(now),
                  createdBy: const Value('admin'),
                ),
              );
        }

        // 8. Record audit log
        await _db.into(_db.auditLog).insert(
              AuditLogCompanion.insert(
                entityType: 'sale',
                entityId: saleId,
                action: 'reverse',
                payloadBefore: Value(jsonEncode({'status': 'confirmed'})),
                payloadAfter: Value(
                  jsonEncode({'status': 'reversed', 'reason': reason}),
                ),
                performedAt: Value(now),
                userId: const Value('admin'),
              ),
            );

        // Dispatch sale reversal status to Sync Queue
        await _syncDispatcher?.dispatchUpdate(
          entityType: 'sale',
          localId: saleId,
          data: {
            'status': 'reversed',
          },
        );

        final updatedSale = await getSaleById(saleId);
        return updatedSale;
      });
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في إلغاء وعكس فاتورة البيع',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }
}
