import '../../../../core/result/result.dart';
import '../entities/inventory_movement.dart';
import '../repositories/inventory_repository.dart';

class GetInventoryMovementsUseCase {
  final InventoryRepository _repository;

  const GetInventoryMovementsUseCase(this._repository);

  Future<Result<List<InventoryMovement>>> call({
    int? productId,
    MovementType? type,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return _repository.getMovements(
      productId: productId,
      type: type,
      fromDate: fromDate,
      toDate: toDate,
    );
  }
}
