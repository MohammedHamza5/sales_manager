import '../../../../core/result/result.dart';
import '../entities/customer_return.dart';
import '../repositories/return_repository.dart';

class GetCustomerReturnsUseCase {
  final ReturnRepository _repository;

  const GetCustomerReturnsUseCase(this._repository);

  Future<Result<List<CustomerReturn>>> call({
    int? customerId,
    DateTime? fromDate,
    DateTime? toDate,
    String? query,
  }) {
    return _repository.getCustomerReturns(
      customerId: customerId,
      fromDate: fromDate,
      toDate: toDate,
      query: query,
    );
  }
}
