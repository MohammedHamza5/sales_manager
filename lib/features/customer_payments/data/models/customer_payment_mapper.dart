import '../../../../core/money/money.dart';
import '../../domain/entities/customer_payment.dart';
import '../daos/customer_payments_dao.dart';

class CustomerPaymentMapper {
  static CustomerPayment fromDetails(CustomerPaymentWithDetails details) {
    return CustomerPayment(
      id: details.payment.id,
      customerId: details.payment.customerId,
      customerName: details.customerName,
      amount: Money(details.payment.amount),
      paymentDate: details.payment.paymentDate,
      linkedSaleId: details.payment.linkedSaleId,
      linkedSaleInvoiceNo: details.saleInvoiceNo,
      note: details.payment.note,
      createdAt: details.payment.createdAt,
      createdBy: details.payment.createdBy,
    );
  }
}
