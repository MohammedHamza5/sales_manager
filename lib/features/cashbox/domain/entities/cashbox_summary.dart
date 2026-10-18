import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';

/// Financial summary of cashbox operations for a specific period (e.g. today).
class CashboxSummary extends Equatable {
  final Money totalIn;
  final Money totalOut;
  final Money netAmount; // totalIn - totalOut
  final Money currentBalance;
  final int transactionCount;

  const CashboxSummary({
    required this.totalIn,
    required this.totalOut,
    required this.netAmount,
    required this.currentBalance,
    required this.transactionCount,
  });

  static const empty = CashboxSummary(
    totalIn: Money.zero,
    totalOut: Money.zero,
    netAmount: Money.zero,
    currentBalance: Money.zero,
    transactionCount: 0,
  );

  @override
  List<Object?> get props => [
        totalIn,
        totalOut,
        netAmount,
        currentBalance,
        transactionCount,
      ];
}
