import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';
import 'sale_item.dart';

enum SaleStatus {
  confirmed('confirmed', 'مؤكدة'),
  reversed('reversed', 'معكوسة ومُلغاة');

  final String value;
  final String arabicTitle;
  const SaleStatus(this.value, this.arabicTitle);

  static SaleStatus fromValue(String value) {
    return SaleStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SaleStatus.confirmed,
    );
  }
}

/// Pure Dart entity representing a sales invoice.
class Sale extends Equatable {
  final int id;
  final int invoiceNo;
  final int customerId;
  final String customerName;
  final String? customerPhone;
  final DateTime saleDate;
  final Money totalAmount;
  final Money paidAmountAtCreation;
  final Money returnedAmount;
  final SaleStatus status;
  final String? note;
  final List<SaleItem> items;
  final DateTime createdAt;
  final String createdBy;

  const Sale({
    required this.id,
    required this.invoiceNo,
    required this.customerId,
    this.customerName = '',
    this.customerPhone,
    required this.saleDate,
    required this.totalAmount,
    required this.paidAmountAtCreation,
    this.returnedAmount = Money.zero,
    this.status = SaleStatus.confirmed,
    this.note,
    this.items = const [],
    required this.createdAt,
    this.createdBy = 'admin',
  });

  /// Net total of invoice after deducting returns.
  Money get netAmount => (totalAmount - returnedAmount).clampToZero();

  /// Amount remaining as debt on the customer for this invoice.
  Money get remainingAmount {
    final rem = (totalAmount - returnedAmount - paidAmountAtCreation).piastres;
    return rem > 0 ? Money.fromPiastres(rem) : Money.zero;
  }

  /// True if any items were returned on this invoice.
  bool get hasReturns => returnedAmount.piastres > 0;

  /// True if invoice was fully paid in cash at creation (or settled by returns).
  bool get isFullyPaid => remainingAmount.piastres <= 0;

  /// True if invoice was partially paid.
  bool get isPartial =>
      paidAmountAtCreation.piastres > 0 && remainingAmount.piastres > 0;

  /// True if completely credit (unpaid).
  bool get isCredit => paidAmountAtCreation.piastres == 0;

  /// Alias for isCredit.
  bool get isFullyCredit => isCredit;

  /// True if the sale is currently active and confirmed.
  bool get isConfirmed => status == SaleStatus.confirmed;

  /// True if the sale was reversed/cancelled.
  bool get isReversed => status == SaleStatus.reversed;

  Sale copyWith({
    int? id,
    int? invoiceNo,
    int? customerId,
    String? customerName,
    String? customerPhone,
    DateTime? saleDate,
    Money? totalAmount,
    Money? paidAmountAtCreation,
    SaleStatus? status,
    String? note,
    List<SaleItem>? items,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return Sale(
      id: id ?? this.id,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      saleDate: saleDate ?? this.saleDate,
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
        customerId,
        customerName,
        customerPhone,
        saleDate,
        totalAmount,
        paidAmountAtCreation,
        status,
        note,
        items,
        createdAt,
        createdBy,
      ];
}
