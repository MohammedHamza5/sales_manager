import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';

/// Pure Dart entity representing a payment paid to a supplier (سند صرف / دفعة لمورد).
class SupplierPayment extends Equatable {
  final int id;
  final int supplierId;
  final String supplierName;
  final Money amount; // بالقرش
  final DateTime paymentDate;
  final int? linkedPurchaseId;
  final int? linkedPurchaseInvoiceNo;
  final String? note;
  final DateTime createdAt;
  final String createdBy;

  const SupplierPayment({
    required this.id,
    required this.supplierId,
    this.supplierName = '',
    required this.amount,
    required this.paymentDate,
    this.linkedPurchaseId,
    this.linkedPurchaseInvoiceNo,
    this.note,
    required this.createdAt,
    this.createdBy = 'admin',
  });

  @override
  List<Object?> get props => [
        id,
        supplierId,
        supplierName,
        amount,
        paymentDate,
        linkedPurchaseId,
        linkedPurchaseInvoiceNo,
        note,
        createdAt,
        createdBy,
      ];
}
