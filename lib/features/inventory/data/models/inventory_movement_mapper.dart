import '../../../../core/database/app_database.dart';
import '../../domain/entities/inventory_movement.dart';

abstract final class InventoryMovementMapper {
  static InventoryMovement toDomain(
    InventoryMovementEntry entry, {
    String? productName,
    String? productUnit,
  }) {
    return InventoryMovement(
      id: entry.id,
      productId: entry.productId,
      productName: productName,
      productUnit: productUnit,
      type: MovementType.fromString(entry.movementType),
      quantityDelta: entry.quantityDelta,
      balanceAfter: entry.balanceAfter,
      referenceType: entry.referenceType,
      referenceId: entry.referenceId,
      note: entry.note,
      createdAt: entry.createdAt,
      createdBy: entry.createdBy,
    );
  }
}
