import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';

enum CustomerLedgerEntryType {
  sale('sale', 'فاتورة مبيعات'),
  payment('payment', 'سند تحصيل نقدية'),
  customerReturn('return', 'مرتجع مبيعات'),
  openingBalance('opening_balance', 'رصيد افتتاحي'),
  reversal('reversal', 'إلغاء وعكس عملية');

  final String value;
  final String arabicTitle;
  const CustomerLedgerEntryType(this.value, this.arabicTitle);

  static CustomerLedgerEntryType fromValue(String value) {
    return CustomerLedgerEntryType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CustomerLedgerEntryType.sale,
    );
  }
}

enum LedgerEffect {
  increase('increase', 'مدين (+) زيادة المديونية'),
  decrease('decrease', 'دائن (-) سداد ونقصان');

  final String value;
  final String arabicTitle;
  const LedgerEffect(this.value, this.arabicTitle);

  static LedgerEffect fromValue(String value) {
    return LedgerEffect.values.firstWhere(
      (e) => e.value == value,
      orElse: () => LedgerEffect.increase,
    );
  }
}

/// Pure Dart entity for customer statement ledger entry.
class CustomerLedgerEntry extends Equatable {
  final int id;
  final int customerId;
  final CustomerLedgerEntryType entryType;
  final Money amount; // دائمًا موجب
  final LedgerEffect effect;
  final Money balanceAfter;
  final String? referenceType;
  final int? referenceId;
  final String? note;
  final DateTime createdAt;
  final String createdBy;

  const CustomerLedgerEntry({
    required this.id,
    required this.customerId,
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

  /// Returns true if this entry increases the customer's debt (مدين).
  bool get isDebtIncrease => effect == LedgerEffect.increase;

  /// Returns true if this entry decreases the customer's debt (دائن).
  bool get isDebtDecrease => effect == LedgerEffect.decrease;

  @override
  List<Object?> get props => [
        id,
        customerId,
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
