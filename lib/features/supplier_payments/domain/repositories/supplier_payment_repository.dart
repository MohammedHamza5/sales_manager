import '../../../../core/money/money.dart';
import '../../../../core/result/result.dart';
import '../entities/supplier_payment.dart';

abstract interface class SupplierPaymentRepository {
  Future<Result<SupplierPayment>> recordPayment({
    required int supplierId,
    required Money amount,
    required DateTime paymentDate,
    int? linkedPurchaseId,
    String? note,
    String createdBy = 'admin',
  });

  Future<Result<List<SupplierPayment>>> getSupplierPayments({int? supplierId});

  Stream<List<SupplierPayment>> watchSupplierPayments({int? supplierId});

  Future<Result<List<SupplierPayment>>> getAllPayments({
    DateTime? from,
    DateTime? to,
  });
}
