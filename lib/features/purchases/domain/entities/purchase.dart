import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';
import 'purchase_item.dart';

enum PurchaseStatus {
  confirmed('confirmed', 'مؤكدة'),
  reversed('reversed', 'معكوسة ومُلغاة');

  final String value;
  final String arabicTitle;
  const PurchaseStatus(this.value, this.arabicTitle);

  static PurchaseStatus fromValue(String value) {
    return PurchaseStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PurchaseStatus.confirmed,
    );
  }
}

/// Pure Dart entity representing a purchase invoice.
class Purchase extends Equatable {
  final int id;
  final int invoiceNo;
  final int supplierId;
  final String supplierName;
  final DateTime purchaseDate;
  final Money totalAmount;
  final Money paidAmountAtCreation;
  final PurchaseStatus status;
  final String? note;
  final List<PurchaseItem> items;
  final DateTime createdAt;
  final String createdBy;

  const Purchase({
    required this.id,
    required this.invoiceNo,
    required this.supplierId,
    this.supplierName = '',
    required this.purchaseDate,
    required this.totalAmount,
    required this.paidAmountAtCreation,
    this.status = PurchaseStatus.confirmed,
    this.note,
    this.items = const [],
    required this.createdAt,
    this.createdBy = 'admin',
  });

  /// Amount remaining as debt to the supplier.
  Money get remainingAmount => totalAmount - paidAmountAtCreation;

  /// True if invoice was fully paid in cash at creation.
  bool get isFullyPaid => remainingAmount.piastres <= 0;

  /// True if invoice was partially paid.
  bool get isPartial =>
      paidAmountAtCreation.piastres > 0 && remainingAmount.piastres > 0;

  /// True if invoice was entirely on credit (no upfront cash paid).
  bool get isFullyCredit => paidAmountAtCreation.piastres == 0;

  /// True if invoice is active/confirmed.
  bool get isConfirmed => status == PurchaseStatus.confirmed;

  /// True if invoice has been reversed.
  bool get isReversed => status == PurchaseStatus.reversed;

  Purchase copyWith({
    int? id,
    int? invoiceNo,
    int? supplierId,
    String? supplierName,
    DateTime? purchaseDate,
    Money? totalAmount,
    Money? paidAmountAtCreation,
    PurchaseStatus? status,
    String? note,
    List<PurchaseItem>? items,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return Purchase(
      id: id ?? this.id,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmountAtCreation: paidAmountAtCreation ?? this.paidAmountAtCreation,
      status: status ?? this.status,
      note: note ?? this.note,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        invoiceNo,
        supplierId,
        supplierName,
        purchaseDate,
        totalAmount,
        paidAmountAtCreation,
        status,
        note,
        items,
        createdAt,
        createdBy,
      ];
}
