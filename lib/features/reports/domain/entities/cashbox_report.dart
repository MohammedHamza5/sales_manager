import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';

class CashboxReportItem extends Equatable {
  final int id;
  final DateTime date;
  final String transactionType;
  final String direction; // 'in' or 'out'
  final Money amount;
  final Money balanceAfter;
  final String? note;

  const CashboxReportItem({
    required this.id,
    required this.date,
    required this.transactionType,
    required this.direction,
    required this.amount,
    required this.balanceAfter,
    this.note,
  });

  @override
  List<Object?> get props => [
        id,
        date,
        transactionType,
        direction,
        amount,
        balanceAfter,
        note,
      ];
}

class CashboxReport extends Equatable {
  final DateTime from;
  final DateTime to;
  final Money openingBalance;
  final Money closingBalance;
  final Money totalIn;
  final Money totalOut;
  final Money netCashflow;
  final List<CashboxReportItem> transactions;

  const CashboxReport({
    required this.from,
    required this.to,
    required this.openingBalance,
    required this.closingBalance,
    required this.totalIn,
    required this.totalOut,
    required this.netCashflow,
    required this.transactions,
  });

  @override
  List<Object?> get props => [
        from,
        to,
        openingBalance,
        closingBalance,
        totalIn,
        totalOut,
        netCashflow,
        transactions,
      ];
}
