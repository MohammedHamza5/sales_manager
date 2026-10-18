import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';

/// Pure Dart entity representing a payment received from a customer (تحصيل).
class CustomerPayment extends Equatable {
  final int id;
  final int customerId;
  final String customerName;
  final Money amount; // بالقرش
  final DateTime paymentDate;
  final int? linkedSaleId;
  final int? linkedSaleInvoiceNo;
  final String? note;
  final DateTime createdAt;
  final String createdBy;

  const CustomerPayment({
    required this.id,
    required this.customerId,
    this.customerName = '',
    required this.amount,
    required this.paymentDate,
    this.linkedSaleId,
    this.linkedSaleInvoiceNo,
    this.note,
    required this.createdAt,
    this.createdBy = 'admin',
  });

  @override
  List<Object?> get props => [
        id,
        customerId,
        customerName,
        amount,
        paymentDate,
        linkedSaleId,
        linkedSaleInvoiceNo,
        note,
        createdAt,
        createdBy,
      ];
}
