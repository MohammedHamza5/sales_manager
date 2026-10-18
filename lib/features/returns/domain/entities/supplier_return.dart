import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';
import 'supplier_return_item.dart';

/// Pure Dart entity representing a return to supplier.
class SupplierReturn extends Equatable {
  final int id;
  final int? originalPurchaseId;
  final int? originalInvoiceNo;
  final int supplierId;
  final String supplierName;
  final DateTime returnDate;
  final Money totalAmount;
  final String? note;
  final List<SupplierReturnItem> items;
  final DateTime createdAt;
  final String createdBy;

  const SupplierReturn({
    required this.id,
    this.originalPurchaseId,
    this.originalInvoiceNo,
    required this.supplierId,
    this.supplierName = '',
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
        originalPurchaseId,
        originalInvoiceNo,
        supplierId,
        supplierName,
        returnDate,
        totalAmount,
        note,
        items,
        createdAt,
        createdBy,
      ];
}
