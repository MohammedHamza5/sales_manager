import '../../../../core/money/money.dart';
import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/supplier_payment.dart';
import '../repositories/supplier_payment_repository.dart';

class RecordSupplierPaymentUseCase {
  final SupplierPaymentRepository _repository;

  const RecordSupplierPaymentUseCase(this._repository);

  Future<Result<SupplierPayment>> call({
    required int supplierId,
    required Money amount,
    required DateTime paymentDate,
    int? linkedPurchaseId,
    String? note,
    String createdBy = 'admin',
  }) async {
    if (supplierId <= 0) {
      return const FailureResult(
        ValidationFailure(
          field: 'supplierId',
          message: 'يجب اختيار مورد صحيح لتسجيل السداد',
        ),
      );
    }

    if (amount.piastres <= 0) {
      return const FailureResult(
        ValidationFailure(
          field: 'amount',
          message: 'مبلغ السداد يجب أن يكون أكبر من الصفر',
        ),
      );
    }

    return _repository.recordPayment(
      supplierId: supplierId,
      amount: amount,
      paymentDate: paymentDate,
      linkedPurchaseId: linkedPurchaseId,
      note: note,
      createdBy: createdBy,
    );
  }
}
