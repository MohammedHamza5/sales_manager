import '../entities/customer_ledger_entry.dart';
import '../repositories/customer_repository.dart';

class WatchCustomerLedgerUseCase {
  final CustomerRepository _repository;

  const WatchCustomerLedgerUseCase(this._repository);

  Stream<List<CustomerLedgerEntry>> call(int customerId) {
    return _repository.watchCustomerLedger(customerId);
  }
}
