import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';

class SupplierLedgerReportItem extends Equatable {
  final int id;
  final DateTime date;
  final String entryType;
  final String description;
  final Money debit;
  final Money credit;
  final Money balanceAfter;

  const SupplierLedgerReportItem({
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

class SupplierBalanceSummary extends Equatable {
  final int supplierId;
  final String supplierName;
  final String? phone;
  final Money balance;

  const SupplierBalanceSummary({
    required this.supplierId,
    required this.supplierName,
    this.phone,
    required this.balance,
  });

  bool get hasBalanceDue => balance.piastres > 0;

  @override
  List<Object?> get props => [supplierId, supplierName, phone, balance];
}

class SupplierAccountReport extends Equatable {
  final int supplierId;
  final String supplierName;
  final DateTime from;
  final DateTime to;
  final Money openingBalance;
  final Money closingBalance;
  final Money totalDebit;
  final Money totalCredit;
  final List<SupplierLedgerReportItem> entries;

  const SupplierAccountReport({
    required this.supplierId,
    required this.supplierName,
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
        supplierId,
        supplierName,
        from,
        to,
        openingBalance,
        closingBalance,
        totalDebit,
        totalCredit,
        entries,
      ];
}
