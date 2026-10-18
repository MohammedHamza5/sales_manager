import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';
import 'customer_return_item.dart';

/// Pure Dart entity representing a return from customer.
class CustomerReturn extends Equatable {
  final int id;
  final int? originalSaleId;
  final int? originalInvoiceNo;
  final int customerId;
  final String customerName;
  final DateTime returnDate;
  final Money totalAmount;
  final String? note;
  final List<CustomerReturnItem> items;
  final DateTime createdAt;
  final String createdBy;

  const CustomerReturn({
    required this.id,
    this.originalSaleId,
    this.originalInvoiceNo,
    required this.customerId,
    this.customerName = '',
    required this.returnDate,
    required this.totalAmount,
    this.note,
    this.items = const [],
    required this.createdAt,
    this.createdBy = 'admin',
  });

  @override
  List<Object?> get props => [
        id,
        originalSaleId,
        originalInvoiceNo,
        customerId,
        customerName,
        returnDate,
        totalAmount,
        note,
        items,
        createdAt,
        createdBy,
      ];
}
