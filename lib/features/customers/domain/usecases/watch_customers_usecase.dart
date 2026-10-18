import '../entities/customer.dart';
import '../repositories/customer_repository.dart';

class WatchCustomersUseCase {
  final CustomerRepository _repository;

  const WatchCustomersUseCase(this._repository);

  Stream<List<Customer>> call({
    String? query,
    bool? isActiveOnly,
  }) {
    return _repository.watchCustomers(
      query: query,
      isActiveOnly: isActiveOnly,
    );
  }
}
