import '../../../../core/money/money.dart';
import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/customer_payment.dart';
import '../repositories/customer_payment_repository.dart';

class RecordCustomerPaymentUseCase {
  final CustomerPaymentRepository _repository;

  const RecordCustomerPaymentUseCase(this._repository);

  Future<Result<CustomerPayment>> call({
    required int customerId,
    required Money amount,
    required DateTime paymentDate,
    int? linkedSaleId,
    String? note,
    String createdBy = 'admin',
  }) async {
    if (customerId <= 0) {
      return const FailureResult(
        ValidationFailure(
          field: 'customerId',
          message: 'يجب اختيار عميل صحيح لتسجيل التحصيل',
        ),
      );
    }

    if (amount.piastres <= 0) {
      return const FailureResult(
        ValidationFailure(
          field: 'amount',
          message: 'مبلغ التحصيل يجب أن يكون أكبر من الصفر',
        ),
      );
    }

    return _repository.recordPayment(
      customerId: customerId,
      amount: amount,
      paymentDate: paymentDate,
      linkedSaleId: linkedSaleId,
      note: note,
      createdBy: createdBy,
    );
  }
}
