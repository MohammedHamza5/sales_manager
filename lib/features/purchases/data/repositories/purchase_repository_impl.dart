import 'dart:convert';
import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../../../../core/sync/sync_dispatcher.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/entities/purchase_item.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../daos/purchases_dao.dart';
import '../models/purchase_mapper.dart';

class PurchaseRepositoryImpl implements PurchaseRepository {
  final AppDatabase _db;
  final PurchasesDao _dao;
  final SyncDispatcher? _syncDispatcher;

  PurchaseRepositoryImpl({
    required AppDatabase db,
    required PurchasesDao dao,
    SyncDispatcher? syncDispatcher,
  })  : _db = db,
        _dao = dao,
        _syncDispatcher = syncDispatcher;

  @override
  Future<Result<Purchase>> createPurchase(CreatePurchaseParams params) async {
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

        // 2. Fetch and verify products for all items
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

        // 3. Calculate next invoice number
        final invoiceNo = await _dao.getNextInvoiceNo();

        // 4. Insert purchase row
        final purchaseCompanion = PurchaseMapper.toCompanion(
          invoiceNo: invoiceNo,
          supplierId: params.supplierId,
          purchaseDate: params.purchaseDate,
          totalAmount: params.totalAmount,
          paidAmountAtCreation: params.paidAmountAtCreation,
          status: 'confirmed',
          note: params.note,
          createdAt: now,
          createdBy: params.createdBy,
        );
        final purchaseId = await _dao.insertPurchase(purchaseCompanion);

        // Dispatch purchase header to Sync Queue
        await _syncDispatcher?.dispatchInsert(
          entityType: 'purchase',
          localId: purchaseId,
          data: {
            'invoice_no': invoiceNo,
            'supplier_id':
                SyncDispatcher.getEntityUuid('supplier', params.supplierId),
            'purchase_date': params.purchaseDate.toIso8601String(),
            'total_amount': params.totalAmount.piastres,
            'paid_amount_at_creation': params.paidAmountAtCreation.piastres,
            'status': 'confirmed',
            'note': params.note,
            'created_at': now.toIso8601String(),
            'created_by': params.createdBy,
          },
        );

        // 5. For each item:
        final domainItems = <PurchaseItem>[];
        for (final item in params.items) {
          final currentProduct = productEntries[item.productId]!;
          final newQuantity = currentProduct.currentQuantity + item.quantity;

          // a. Insert purchase_items row
          final itemId = await _dao.insertPurchaseItem(
            PurchaseMapper.itemToCompanion(
              purchaseId: purchaseId,
              itemParam: item,
              createdAt: now,
            ),
          );

          // Dispatch purchase item to Sync Queue
          await _syncDispatcher?.dispatchInsert(
            entityType: 'purchase_item',
            localId: itemId,
            data: {
              'purchase_id': SyncDispatcher.getEntityUuid('purchase', purchaseId),
              'product_id':
                  SyncDispatcher.getEntityUuid('product', item.productId),
              'quantity': item.quantity.toDouble(),
              'unit_cost_at_purchase': item.unitCost.piastres,
              'line_total': item.lineTotal.piastres,
              'created_at': now.toIso8601String(),
            },
          );

          // b. Insert inventory_movements (purchase, positive delta)
          await _db.into(_db.inventoryMovements).insert(
                InventoryMovementsCompanion.insert(
                  productId: item.productId,
                  movementType: 'purchase',
                  quantityDelta: item.quantity,
                  balanceAfter: newQuantity,
                  referenceType: const Value('purchase'),
                  referenceId: Value(purchaseId),
                  note: Value('فاتورة شراء رقم $invoiceNo'),
                  createdAt: Value(now),
                  createdBy: Value(params.createdBy),
                ),
              );

          // c. Update products.current_quantity and current_purchase_price
          await (_db.update(_db.products)
                ..where((tbl) => tbl.id.equals(item.productId)))
              .write(
            ProductsCompanion(
              currentQuantity: Value(newQuantity),
              currentPurchasePrice: Value(item.unitCost.piastres),
            ),
          );

          // Dispatch product stock & cost update to Sync Queue
          await _syncDispatcher?.dispatchUpdate(
            entityType: 'product',
            localId: item.productId,
            data: {
              'current_quantity': newQuantity.toDouble(),
              'current_purchase_price': item.unitCost.piastres,
            },
          );

          // Update local map cache
          productEntries[item.productId] = currentProduct.copyWith(
            currentQuantity: newQuantity,
            currentPurchasePrice: item.unitCost.piastres,
          );

          domainItems.add(
            PurchaseItem(
              id: itemId,
              purchaseId: purchaseId,
              productId: item.productId,
              productName: currentProduct.name,
              productUnit: currentProduct.unit,
              quantity: item.quantity,
              unitCostAtPurchase: item.unitCost,
              lineTotal: item.lineTotal,
              createdAt: now,
            ),
          );
        }

        // 6. Remaining amount = totalAmount - paidAmountAtCreation
        final remaining = params.totalAmount - params.paidAmountAtCreation;
        if (remaining.piastres > 0) {
          final newSupplierBalance =
              supplierEntry.currentBalance + remaining.piastres;

          // a. Insert supplier_ledger_entries (purchase, increase)
          await _db.into(_db.supplierLedgerEntries).insert(
                SupplierLedgerEntriesCompanion.insert(
                  supplierId: params.supplierId,
                  entryType: 'purchase',
                  amount: remaining.piastres,
                  effect: 'increase',
                  balanceAfter: newSupplierBalance,
                  referenceType: const Value('purchase'),
                  referenceId: Value(purchaseId),
                  note: Value('المتبقي من فاتورة شراء رقم $invoiceNo'),
                  createdAt: Value(now),
                  createdBy: Value(params.createdBy),
                ),
              );

          // b. Update suppliers.current_balance
          await (_db.update(_db.suppliers)
                ..where((tbl) => tbl.id.equals(params.supplierId)))
              .write(
            SuppliersCompanion(
              currentBalance: Value(newSupplierBalance),
            ),
          );

          await _syncDispatcher?.dispatchUpdate(
            entityType: 'supplier',
            localId: params.supplierId,
            data: {
              'current_balance': newSupplierBalance,
            },
          );
        }

        // 7. If paidAmountAtCreation > 0, deduct from cashbox
        if (params.paidAmountAtCreation.piastres > 0) {
          final latestTx = await (_db.select(_db.cashboxTransactions)
                ..orderBy([(t) => OrderingTerm.desc(t.id)])
                ..limit(1))
              .getSingleOrNull();
          final currentCashboxBalance = latestTx?.balanceAfter ?? 0;
          final newCashboxBalance =
              currentCashboxBalance - params.paidAmountAtCreation.piastres;

          await _db.into(_db.cashboxTransactions).insert(
                CashboxTransactionsCompanion.insert(
                  transactionType: 'purchase_cash_out',
                  amount: params.paidAmountAtCreation.piastres,
                  direction: 'out',
                  balanceAfter: newCashboxBalance,
                  referenceType: const Value('purchase'),
                  referenceId: Value(purchaseId),
                  note: Value(
                    'سداد نقدي لفاتورة شراء رقم $invoiceNo للمورد ${supplierEntry.name}',
                  ),
                  createdAt: Value(now),
                  createdBy: Value(params.createdBy),
                ),
              );
        }

        // 8. Insert audit_log
        await _db.into(_db.auditLog).insert(
              AuditLogCompanion.insert(
                entityType: 'purchase',
                entityId: purchaseId,
                action: 'create',
                payloadAfter: Value(
                  jsonEncode({
                    'id': purchaseId,
                    'invoice_no': invoiceNo,
                    'supplier_id': params.supplierId,
                    'supplier_name': supplierEntry.name,
                    'total_amount_piastres': params.totalAmount.piastres,
                    'paid_amount_piastres': params.paidAmountAtCreation.piastres,
                    'remaining_piastres': remaining.piastres,
                    'items_count': params.items.length,
                  }),
                ),
                userId: Value(params.createdBy),
              ),
            );

        final createdPurchase = Purchase(
          id: purchaseId,
          invoiceNo: invoiceNo,
          supplierId: params.supplierId,
          supplierName: supplierEntry.name,
          purchaseDate: params.purchaseDate,
          totalAmount: params.totalAmount,
          paidAmountAtCreation: params.paidAmountAtCreation,
          status: PurchaseStatus.confirmed,
          note: params.note,
          items: domainItems,
          createdAt: now,
          createdBy: params.createdBy,
        );

        return Success(createdPurchase);
      });
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في حفظ فاتورة الشراء الذرية',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Future<Result<List<Purchase>>> getPurchases({
    int? supplierId,
    DateTime? fromDate,
    DateTime? toDate,
    PurchaseStatus? status,
    String? query,
  }) async {
    try {
      final rows = await _dao.getPurchasesList(
        supplierId: supplierId,
        fromDate: fromDate,
        toDate: toDate,
        status: status?.value,
        query: query,
      );

      final purchases = <Purchase>[];
      for (final row in rows) {
        final pEntry = row.readTable(_db.purchases);
        final sEntry = row.readTable(_db.suppliers);
        purchases.add(
          PurchaseMapper.toDomain(
            pEntry,
            supplierName: sEntry.name,
          ),
        );
      }

      return Success(purchases);
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في جلب فواتير المشتريات',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Stream<List<Purchase>> watchPurchases({
    int? supplierId,
    DateTime? fromDate,
    DateTime? toDate,
    PurchaseStatus? status,
    String? query,
  }) {
    return _dao
        .watchPurchasesList(
          supplierId: supplierId,
          fromDate: fromDate,
          toDate: toDate,
          status: status?.value,
          query: query,
        )
        .map((rows) {
      return rows.map((row) {
        final pEntry = row.readTable(_db.purchases);
        final sEntry = row.readTable(_db.suppliers);
        return PurchaseMapper.toDomain(
          pEntry,
          supplierName: sEntry.name,
        );
      }).toList();
    });
  }

  @override
  Future<Result<Purchase>> getPurchaseById(int id) async {
    try {
      final row = await _dao.getPurchaseById(id);
      if (row == null) {
        return const FailureResult(
          NotFoundFailure(message: 'فاتورة الشراء غير موجودة'),
        );
      }

      final pEntry = row.readTable(_db.purchases);
      final sEntry = row.readTable(_db.suppliers);

      final itemRows = await _dao.getPurchaseItemsWithProduct(id);
      final items = itemRows.map((iRow) {
        final itemEntry = iRow.readTable(_db.purchaseItems);
        final productEntry = iRow.readTable(_db.products);
        return PurchaseMapper.itemToDomain(
          itemEntry,
          productName: productEntry.name,
          productUnit: productEntry.unit,
        );
      }).toList();

      final purchase = PurchaseMapper.toDomain(
        pEntry,
        supplierName: sEntry.name,
        items: items,
      );

      return Success(purchase);
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في جلب تفاصيل فاتورة الشراء',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Future<Result<Purchase>> reversePurchase({
    required int purchaseId,
    String createdBy = 'admin',
  }) async {
    try {
      return await _db.transaction(() async {
        final now = DateTime.now();

        // 1. Fetch purchase
        final purchaseRow = await (_db.select(_db.purchases)
              ..where((tbl) => tbl.id.equals(purchaseId)))
            .getSingleOrNull();

        if (purchaseRow == null) {
          return const FailureResult(
            NotFoundFailure(message: 'فاتورة الشراء المراد عكسها غير موجودة'),
          );
        }

        if (purchaseRow.status == 'reversed') {
          return const FailureResult(
            ConflictFailure(message: 'فاتورة الشراء مُلغاة ومعكوسة مسبقاً'),
          );
        }

        // 2. Fetch items with product
        final itemsWithProduct =
            await _dao.getPurchaseItemsWithProduct(purchaseId);
        if (itemsWithProduct.isEmpty) {
          return const FailureResult(
            NotFoundFailure(message: 'أصناف فاتورة الشراء غير موجودة'),
          );
        }

        // 3. Stock safety verification:
        // Current stock cannot drop below zero upon reversal
        for (final row in itemsWithProduct) {
          final itemEntry = row.readTable(_db.purchaseItems);
          final productEntry = row.readTable(_db.products);
          if (productEntry.currentQuantity < itemEntry.quantity) {
            return FailureResult(
              InsufficientStockFailure(
                productName: productEntry.name,
                requestedQuantity: itemEntry.quantity.toString(),
                availableQuantity: productEntry.currentQuantity.toString(),
                message:
                    'لا يمكن عكس الفاتورة لأن كمية المنتج (${productEntry.name}) الحالية بالمخزن (${productEntry.currentQuantity} ${productEntry.unit}) أقل من الكمية المشتراة (${itemEntry.quantity} ${productEntry.unit}) نتيجة لعمليات لاحقة',
              ),
            );
          }
        }

        // 4. Update status to 'reversed'
        await _dao.updatePurchaseStatus(purchaseId, 'reversed');

        // 5. For each item:
        // a. insert inventory_movements (reversal, negative delta)
        // b. update products.current_quantity -= item.quantity
        for (final row in itemsWithProduct) {
          final itemEntry = row.readTable(_db.purchaseItems);
          final productEntry = row.readTable(_db.products);
          final newQuantity = productEntry.currentQuantity - itemEntry.quantity;

          await _db.into(_db.inventoryMovements).insert(
                InventoryMovementsCompanion.insert(
                  productId: itemEntry.productId,
                  movementType: 'reversal',
                  quantityDelta: -itemEntry.quantity,
                  balanceAfter: newQuantity,
                  referenceType: const Value('purchase_reversal'),
                  referenceId: Value(purchaseId),
                  note: Value('عكس فاتورة شراء رقم ${purchaseRow.invoiceNo}'),
                  createdAt: Value(now),
                  createdBy: Value(createdBy),
                ),
              );

          await (_db.update(_db.products)
                ..where((tbl) => tbl.id.equals(itemEntry.productId)))
              .write(
            ProductsCompanion(currentQuantity: Value(newQuantity)),
          );

          await _syncDispatcher?.dispatchUpdate(
            entityType: 'product',
            localId: itemEntry.productId,
            data: {
              'current_quantity': newQuantity.toDouble(),
            },
          );
        }

        // 6. Reverse supplier balance if there was debt (remaining > 0)
        final remaining =
            purchaseRow.totalAmount - purchaseRow.paidAmountAtCreation;
        final supplierEntry = await (_db.select(_db.suppliers)
              ..where((tbl) => tbl.id.equals(purchaseRow.supplierId)))
            .getSingleOrNull();

        if (remaining > 0 && supplierEntry != null) {
          final newSupplierBalance = supplierEntry.currentBalance - remaining;
          await _db.into(_db.supplierLedgerEntries).insert(
                SupplierLedgerEntriesCompanion.insert(
                  supplierId: purchaseRow.supplierId,
                  entryType: 'reversal',
                  amount: remaining,
                  effect: 'decrease',
                  balanceAfter: newSupplierBalance,
                  referenceType: const Value('purchase_reversal'),
                  referenceId: Value(purchaseId),
                  note: Value(
                    'عكس مستحقات فاتورة شراء رقم ${purchaseRow.invoiceNo}',
                  ),
                  createdAt: Value(now),
                  createdBy: Value(createdBy),
                ),
              );

          await (_db.update(_db.suppliers)
                ..where((tbl) => tbl.id.equals(purchaseRow.supplierId)))
              .write(
            SuppliersCompanion(currentBalance: Value(newSupplierBalance)),
          );

          await _syncDispatcher?.dispatchUpdate(
            entityType: 'supplier',
            localId: purchaseRow.supplierId,
            data: {
              'current_balance': newSupplierBalance,
            },
          );
        }

        // 7. If paidAmountAtCreation > 0, refund to cashbox
        if (purchaseRow.paidAmountAtCreation > 0) {
          final latestTx = await (_db.select(_db.cashboxTransactions)
                ..orderBy([(t) => OrderingTerm.desc(t.id)])
                ..limit(1))
              .getSingleOrNull();
          final currentCashboxBalance = latestTx?.balanceAfter ?? 0;
          final newCashboxBalance =
              currentCashboxBalance + purchaseRow.paidAmountAtCreation;

          await _db.into(_db.cashboxTransactions).insert(
                CashboxTransactionsCompanion.insert(
                  transactionType: 'reversal',
                  amount: purchaseRow.paidAmountAtCreation,
                  direction: 'in',
                  balanceAfter: newCashboxBalance,
                  referenceType: const Value('purchase_reversal'),
                  referenceId: Value(purchaseId),
                  note: Value(
                    'استرداد نقدية عكس فاتورة شراء رقم ${purchaseRow.invoiceNo}',
                  ),
                  createdAt: Value(now),
                  createdBy: Value(createdBy),
                ),
              );
        }

        // 8. Insert audit_log
        await _db.into(_db.auditLog).insert(
              AuditLogCompanion.insert(
                entityType: 'purchase',
                entityId: purchaseId,
                action: 'reverse',
                payloadBefore:
                    Value(jsonEncode({'status': purchaseRow.status})),
                payloadAfter: Value(jsonEncode({'status': 'reversed'})),
                userId: Value(createdBy),
              ),
            );

        // Dispatch purchase reversal to Sync Queue
        await _syncDispatcher?.dispatchUpdate(
          entityType: 'purchase',
          localId: purchaseId,
          data: {
            'status': 'reversed',
          },
        );

        // Fetch and return the updated purchase
        final updatedResult = await getPurchaseById(purchaseId);
        return updatedResult;
      });
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في إلغاء وعكس فاتورة الشراء',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }
}
