import '../entities/supplier_payment.dart';
import '../repositories/supplier_payment_repository.dart';

class WatchSupplierPaymentsUseCase {
  final SupplierPaymentRepository _repository;

  const WatchSupplierPaymentsUseCase(this._repository);

  Stream<List<SupplierPayment>> call({int? supplierId}) {
    return _repository.watchSupplierPayments(supplierId: supplierId);
  }
}
