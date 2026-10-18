import '../entities/supplier_ledger_entry.dart';
import '../repositories/supplier_repository.dart';

class WatchSupplierLedgerUseCase {
  final SupplierRepository _repository;

  const WatchSupplierLedgerUseCase(this._repository);

  Stream<List<SupplierLedgerEntry>> call(int supplierId) {
    return _repository.watchSupplierLedger(supplierId);
  }
}
