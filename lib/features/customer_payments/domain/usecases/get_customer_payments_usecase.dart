import '../../../../core/result/result.dart';
import '../entities/customer_payment.dart';
import '../repositories/customer_payment_repository.dart';

class GetCustomerPaymentsUseCase {
  final CustomerPaymentRepository _repository;

  const GetCustomerPaymentsUseCase(this._repository);

  Future<Result<List<CustomerPayment>>> call({
    int? customerId,
    DateTime? from,
    DateTime? to,
  }) {
    if (customerId != null) {
      return _repository.getCustomerPayments(customerId: customerId);
    }
    return _repository.getAllPayments(from: from, to: to);
  }
}
