import '../../../../core/result/result.dart';
import '../repositories/supplier_repository.dart';

class ToggleSupplierStatusUseCase {
  final SupplierRepository _repository;

  const ToggleSupplierStatusUseCase(this._repository);

  Future<Result<void>> call(int id, bool isActive) {
    return _repository.toggleSupplierStatus(id, isActive);
  }
}
