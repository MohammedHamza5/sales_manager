import '../../../../core/result/result.dart';
import '../entities/supplier_payment.dart';
import '../repositories/supplier_payment_repository.dart';

class GetSupplierPaymentsUseCase {
  final SupplierPaymentRepository _repository;

  const GetSupplierPaymentsUseCase(this._repository);

  Future<Result<List<SupplierPayment>>> call({
    int? supplierId,
    DateTime? from,
    DateTime? to,
  }) {
    if (supplierId != null) {
      return _repository.getSupplierPayments(supplierId: supplierId);
    }
    return _repository.getAllPayments(from: from, to: to);
  }
}
