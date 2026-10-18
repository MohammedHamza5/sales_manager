import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';

enum SupplierLedgerEntryType {
  purchase('purchase', 'فاتورة مشتريات'),
  payment('payment', 'سند صرف نقدية'),
  supplierReturn('return', 'مرتجع مشتريات'),
  openingBalance('opening_balance', 'رصيد افتتاحي'),
  reversal('reversal', 'إلغاء وعكس عملية');

  final String value;
  final String arabicTitle;
  const SupplierLedgerEntryType(this.value, this.arabicTitle);

  static SupplierLedgerEntryType fromValue(String value) {
    return SupplierLedgerEntryType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SupplierLedgerEntryType.purchase,
    );
  }
}

enum SupplierLedgerEffect {
  increase('increase', 'دائن (+) زيادة مستحقات المورد'),
  decrease('decrease', 'مدين (-) سداد وخفض المستحقات');

  final String value;
  final String arabicTitle;
  const SupplierLedgerEffect(this.value, this.arabicTitle);

  static SupplierLedgerEffect fromValue(String value) {
    return SupplierLedgerEffect.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SupplierLedgerEffect.increase,
    );
  }
}

/// Pure Dart entity for supplier statement ledger entry.
class SupplierLedgerEntry extends Equatable {
  final int id;
  final int supplierId;
  final SupplierLedgerEntryType entryType;
  final Money amount; // دائمًا موجب
  final SupplierLedgerEffect effect;
  final Money balanceAfter;
  final String? referenceType;
  final int? referenceId;
  final String? note;
  final DateTime createdAt;
  final String createdBy;

  const SupplierLedgerEntry({
    required this.id,
    required this.supplierId,
    required this.entryType,
    required this.amount,
    required this.effect,
    required this.balanceAfter,
    this.referenceType,
    this.referenceId,
    this.note,
    required this.createdAt,
    this.createdBy = 'admin',
  });

  /// Returns true if this entry increases the supplier's due balance (يزيد ما له علينا).
  bool get isDueIncrease => effect == SupplierLedgerEffect.increase;

  /// Returns true if this entry decreases the supplier's due balance (يقلل ما له علينا).
  bool get isDueDecrease => effect == SupplierLedgerEffect.decrease;

  @override
  List<Object?> get props => [
        id,
        supplierId,
        entryType,
        amount,
        effect,
        balanceAfter,
        referenceType,
        referenceId,
        note,
        createdAt,
        createdBy,
      ];
}
