import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../repositories/customer_repository.dart';

class ToggleCustomerStatusUseCase {
  final CustomerRepository _repository;

  const ToggleCustomerStatusUseCase(this._repository);

  Future<Result<void>> call(int id, bool isActive) async {
    if (id <= 0) {
      return const FailureResult(
        ValidationFailure(
          field: 'id',
          message: 'معرف العميل غير صالح',
        ),
      );
    }
    return _repository.toggleCustomerStatus(id, isActive);
  }
}
