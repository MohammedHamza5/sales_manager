import '../../../../core/money/money.dart';
import '../../../../core/result/result.dart';
import '../entities/customer_payment.dart';

abstract interface class CustomerPaymentRepository {
  Future<Result<CustomerPayment>> recordPayment({
    required int customerId,
    required Money amount,
    required DateTime paymentDate,
    int? linkedSaleId,
    String? note,
    String createdBy = 'admin',
  });

  Future<Result<List<CustomerPayment>>> getCustomerPayments({int? customerId});

  Stream<List<CustomerPayment>> watchCustomerPayments({int? customerId});

  Future<Result<List<CustomerPayment>>> getAllPayments({
    DateTime? from,
    DateTime? to,
  });
}
