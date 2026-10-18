import '../entities/customer_payment.dart';
import '../repositories/customer_payment_repository.dart';

class WatchCustomerPaymentsUseCase {
  final CustomerPaymentRepository _repository;

  const WatchCustomerPaymentsUseCase(this._repository);

  Stream<List<CustomerPayment>> call({int? customerId}) {
    return _repository.watchCustomerPayments(customerId: customerId);
  }
}
