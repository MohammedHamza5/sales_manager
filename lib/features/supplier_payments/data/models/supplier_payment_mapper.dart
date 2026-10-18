import '../../../../core/money/money.dart';
import '../../domain/entities/supplier_payment.dart';
import '../daos/supplier_payments_dao.dart';

class SupplierPaymentMapper {
  static SupplierPayment fromDetails(SupplierPaymentWithDetails details) {
    return SupplierPayment(
      id: details.payment.id,
      supplierId: details.payment.supplierId,
      supplierName: details.supplierName,
      amount: Money(details.payment.amount),
      paymentDate: details.payment.paymentDate,
      linkedPurchaseId: details.payment.linkedPurchaseId,
      linkedPurchaseInvoiceNo: details.purchaseInvoiceNo,
      note: details.payment.note,
      createdAt: details.payment.createdAt,
      createdBy: details.payment.createdBy,
    );
  }
}
