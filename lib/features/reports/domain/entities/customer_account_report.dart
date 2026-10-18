import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';

class CustomerLedgerReportItem extends Equatable {
  final int id;
  final DateTime date;
  final String entryType;
  final String description;
  final Money debit;
  final Money credit;
  final Money balanceAfter;

  const CustomerLedgerReportItem({
    required this.id,
    required this.date,
    required this.entryType,
    required this.description,
    required this.debit,
    required this.credit,
    required this.balanceAfter,
  });

  @override
  List<Object?> get props => [
        id,
        date,
        entryType,
        description,
        debit,
        credit,
        balanceAfter,
      ];
}

class CustomerBalanceSummary extends Equatable {
  final int customerId;
  final String customerName;
  final String? phone;
  final Money balance;

  const CustomerBalanceSummary({
    required this.customerId,
    required this.customerName,
    this.phone,
    required this.balance,
  });

  bool get hasDebt => balance.piastres > 0;
  bool get isCreditor => balance.piastres < 0;

  @override
  List<Object?> get props => [customerId, customerName, phone, balance];
}

class CustomerAccountReport extends Equatable {
  final int customerId;
  final String customerName;
  final DateTime from;
  final DateTime to;
  final Money openingBalance;
  final Money closingBalance;
  final Money totalDebit;
  final Money totalCredit;
  final List<CustomerLedgerReportItem> entries;

  const CustomerAccountReport({
    required this.customerId,
    required this.customerName,
    required this.from,
    required this.to,
    required this.openingBalance,
    required this.closingBalance,
    required this.totalDebit,
    required this.totalCredit,
    required this.entries,
  });

  @override
  List<Object?> get props => [
        customerId,
        customerName,
        from,
        to,
        openingBalance,
        closingBalance,
        totalDebit,
        totalCredit,
        entries,
      ];
}
