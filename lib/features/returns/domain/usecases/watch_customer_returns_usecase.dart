import '../entities/customer_return.dart';
import '../repositories/return_repository.dart';

class WatchCustomerReturnsUseCase {
  final ReturnRepository _repository;

  const WatchCustomerReturnsUseCase(this._repository);

  Stream<List<CustomerReturn>> call({
    int? customerId,
    DateTime? fromDate,
    DateTime? toDate,
    String? query,
  }) {
    return _repository.watchCustomerReturns(
      customerId: customerId,
      fromDate: fromDate,
      toDate: toDate,
      query: query,
    );
  }
}
