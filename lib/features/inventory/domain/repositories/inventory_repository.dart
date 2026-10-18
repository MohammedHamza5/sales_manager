import 'package:decimal/decimal.dart';
import '../../../../core/result/result.dart';
import '../entities/inventory_movement.dart';

abstract class InventoryRepository {
  /// Fetch inventory movements with optional filtering by product, type, or date.
  Future<Result<List<InventoryMovement>>> getMovements({
    int? productId,
    MovementType? type,
    DateTime? fromDate,
    DateTime? toDate,
  });

  /// Real-time stream of movements for a specific product or the whole warehouse.
  Stream<List<InventoryMovement>> watchMovements({
    int? productId,
    MovementType? type,
  });

  /// Records an atomic manual stock adjustment with mandatory reason.
  Future<Result<InventoryMovement>> recordAdjustment({
    required int productId,
    required Decimal quantityDelta,
    required String reason,
    String createdBy = 'admin',
  });
}
