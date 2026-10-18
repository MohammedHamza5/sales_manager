import 'dart:convert';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/inventory_movement.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../../../core/sync/sync_dispatcher.dart';
import '../daos/inventory_movements_dao.dart';
import '../models/inventory_movement_mapper.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final AppDatabase _db;
  final InventoryMovementsDao _dao;
  final SyncDispatcher? _syncDispatcher;

  InventoryRepositoryImpl({
    required AppDatabase db,
    required InventoryMovementsDao dao,
    SyncDispatcher? syncDispatcher,
  })  : _db = db,
        _dao = dao,
        _syncDispatcher = syncDispatcher;

  @override
  Future<Result<List<InventoryMovement>>> getMovements({
    int? productId,
    MovementType? type,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final rows = await _dao.getMovementsList(
        productId: productId,
        movementType: type?.value,
        fromDate: fromDate,
        toDate: toDate,
      );

      final movements = rows.map((row) {
        final entry = row.readTable(_db.inventoryMovements);
        final product = row.readTable(_db.products);
        return InventoryMovementMapper.toDomain(
          entry,
          productName: product.name,
          productUnit: product.unit,
        );
      }).toList();

      return Success(movements);
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في جلب سجل حركات المخزون',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Stream<List<InventoryMovement>> watchMovements({
    int? productId,
    MovementType? type,
  }) {
    return _dao
        .watchMovementsList(
          productId: productId,
          movementType: type?.value,
        )
        .map((rows) {
      return rows.map((row) {
        final entry = row.readTable(_db.inventoryMovements);
        final product = row.readTable(_db.products);
        return InventoryMovementMapper.toDomain(
          entry,
          productName: product.name,
          productUnit: product.unit,
        );
      }).toList();
    });
  }

  @override
  Future<Result<InventoryMovement>> recordAdjustment({
    required int productId,
    required Decimal quantityDelta,
    required String reason,
    String createdBy = 'admin',
  }) async {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      return const FailureResult(
        ValidationFailure(
          field: 'reason',
          message: 'سبب التسوية المخزنية مطلوب إلزاميًا حسب معايير النظام',
        ),
      );
    }

    if (quantityDelta == Decimal.zero) {
      return const FailureResult(
        ValidationFailure(
          field: 'quantityDelta',
          message: 'مقدار التسوية يجب ألا يكون صفراً',
        ),
      );
    }

    try {
      return await _db.transaction(() async {
        // 1. Fetch current product
        final productEntry = await (_db.select(_db.products)
              ..where((tbl) => tbl.id.equals(productId)))
            .getSingleOrNull();

        if (productEntry == null) {
          return const FailureResult(
            NotFoundFailure(message: 'المنتج المراد تسوية مخزونه غير موجود'),
          );
        }

        final newQuantity = productEntry.currentQuantity + quantityDelta;
        if (newQuantity < Decimal.zero) {
          return FailureResult(
            InsufficientStockFailure(
              productName: productEntry.name,
              requestedQuantity: quantityDelta.abs().toString(),
              availableQuantity: productEntry.currentQuantity.toString(),
              message:
                  'لا يمكن إنقاص المخزون بأكثر من الكمية المتاحة حالياً (${productEntry.currentQuantity} ${productEntry.unit})',
            ),
          );
        }

        // 2. Insert Stock Adjustment record
        final now = DateTime.now();
        final adjustmentId = await _db.into(_db.stockAdjustments).insert(
              StockAdjustmentsCompanion.insert(
                productId: productId,
                quantityDelta: quantityDelta,
                reason: cleanReason,
                adjustmentDate: now,
                createdBy: Value(createdBy),
              ),
            );

        // 3. Insert Inventory Movement record
        final movementId = await _dao.insertMovement(
          InventoryMovementsCompanion.insert(
            productId: productId,
            movementType: 'adjustment',
            quantityDelta: quantityDelta,
            balanceAfter: newQuantity,
            referenceType: const Value('stock_adjustment'),
            referenceId: Value(adjustmentId),
            note: Value(cleanReason),
            createdBy: Value(createdBy),
          ),
        );

        // 4. Update Product current_quantity cache
        await (_db.update(_db.products)..where((tbl) => tbl.id.equals(productId)))
            .write(
          ProductsCompanion(currentQuantity: Value(newQuantity)),
        );

        // 5. Write Audit Log
        await _db.into(_db.auditLog).insert(
              AuditLogCompanion.insert(
                entityType: 'stock_adjustment',
                entityId: adjustmentId,
                action: 'create',
                payloadAfter: Value(
                  jsonEncode({
                    'product_id': productId,
                    'delta': quantityDelta.toString(),
                    'balance_after': newQuantity.toString(),
                    'reason': cleanReason,
                  }),
                ),
                userId: Value(createdBy),
              ),
            );

        // 6. Cloud Sync Outbox Dispatch
        if (_syncDispatcher != null) {
          await _syncDispatcher.dispatchInsert(
            entityType: 'stock_adjustment',
            localId: adjustmentId,
            data: {
              'product_id': SyncDispatcher.getEntityUuid('product', productId),
              'quantity_delta': quantityDelta.toDouble(),
              'reason': cleanReason,
              'adjustment_date': now.toIso8601String(),
              'created_by': createdBy,
            },
          );
          await _syncDispatcher.dispatchUpdate(
            entityType: 'product',
            localId: productId,
            data: {
              'current_quantity': newQuantity.toDouble(),
            },
          );
        }

        final movement = InventoryMovement(
          id: movementId,
          productId: productId,
          productName: productEntry.name,
          productUnit: productEntry.unit,
          type: MovementType.adjustment,
          quantityDelta: quantityDelta,
          balanceAfter: newQuantity,
          referenceType: 'stock_adjustment',
          referenceId: adjustmentId,
          note: cleanReason,
          createdAt: now,
          createdBy: createdBy,
        );

        return Success(movement);
      });
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في حفظ تسوية المخزون',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }
}
