import '../entities/inventory_movement.dart';
import '../repositories/inventory_repository.dart';

class WatchInventoryMovementsUseCase {
  final InventoryRepository _repository;

  const WatchInventoryMovementsUseCase(this._repository);

  Stream<List<InventoryMovement>> call({
    int? productId,
    MovementType? type,
  }) {
    return _repository.watchMovements(
      productId: productId,
      type: type,
    );
  }
}
