import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';

/// Pure Dart entity representing a cashbox transaction (حركة خزينة).
class CashboxTransactionEntity extends Equatable {
  final int id;
  final String transactionType; // sale_cash_in, customer_payment_in, purchase_cash_out, supplier_payment_out, expense_out, opening_balance, reversal
  final Money amount; // بالقرش دائمًا موجب
  final String direction; // 'in' | 'out'
  final Money balanceAfter; // الرصيد بعد الحركة
  final String? referenceType; // sale, purchase, customer_payment, supplier_payment, expense, system
  final int? referenceId;
  final String? note;
  final DateTime createdAt;
  final String createdBy;

  const CashboxTransactionEntity({
    required this.id,
    required this.transactionType,
    required this.amount,
    required this.direction,
    required this.balanceAfter,
    this.referenceType,
    this.referenceId,
    this.note,
    required this.createdAt,
    this.createdBy = 'admin',
  });

  bool get isIn => direction == 'in';
  bool get isOut => direction == 'out';

  /// Returns friendly Arabic label for the transaction type.
  String get transactionTypeArabic {
    switch (transactionType) {
      case 'opening_balance':
        return 'رصيد افتتاحي';
      case 'sale_cash_in':
        return 'بيع نقدي';
      case 'customer_payment_in':
        return 'تحصيل من عميل';
      case 'purchase_cash_out':
        return 'شراء نقدي';
      case 'supplier_payment_out':
        return 'سداد لمورد';
      case 'expense_out':
        return 'مصروف نقدي';
      case 'sale_reverse_out':
      case 'sale_refund_out':
        return 'استرداد مبيعات ملغاة';
      case 'purchase_reverse_in':
      case 'purchase_refund_in':
        return 'استرداد مشتريات ملغاة';
      case 'customer_return_out':
        return 'مرتجع مبيعات نقدي';
      case 'supplier_return_in':
        return 'مرتجع مشتريات نقدي';
      default:
        if (isIn) return 'إيداع نقدي';
        if (isOut) return 'صرف نقدي';
        return transactionType;
    }
  }

  @override
  List<Object?> get props => [
        id,
        transactionType,
        amount,
        direction,
        balanceAfter,
        referenceType,
        referenceId,
        note,
        createdAt,
        createdBy,
      ];
}
