import '../../../../core/result/result.dart';
import '../repositories/product_repository.dart';

class ToggleProductStatusUseCase {
  final ProductRepository _repository;

  const ToggleProductStatusUseCase(this._repository);

  Future<Result<void>> call(int id, bool isActive) {
    return _repository.toggleProductStatus(id, isActive);
  }
}
