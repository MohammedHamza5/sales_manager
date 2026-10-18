import 'package:equatable/equatable.dart';

import '../../domain/entities/cashbox_report.dart';
import '../../domain/entities/collections_report.dart';
import '../../domain/entities/customer_account_report.dart';
import '../../domain/entities/inventory_report.dart';
import '../../domain/entities/profit_report.dart';
import '../../domain/entities/sales_report.dart';
import '../../domain/entities/supplier_account_report.dart';

sealed class ReportsState extends Equatable {
  const ReportsState();

  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {
  const ReportsInitial();
}

class ReportsLoading extends ReportsState {
  const ReportsLoading();
}

class SalesReportLoaded extends ReportsState {
  final SalesReport report;

  const SalesReportLoaded(this.report);

  @override
  List<Object?> get props => [report];
}

class CollectionsReportLoaded extends ReportsState {
  final CollectionsReport report;

  const CollectionsReportLoaded(this.report);

  @override
  List<Object?> get props => [report];
}

class CustomerReportLoaded extends ReportsState {
  final CustomerAccountReport? accountReport;
  final List<CustomerBalanceSummary> allBalances;

  const CustomerReportLoaded({
    this.accountReport,
    required this.allBalances,
  });

  @override
  List<Object?> get props => [accountReport, allBalances];
}

class SupplierReportLoaded extends ReportsState {
  final SupplierAccountReport? accountReport;
  final List<SupplierBalanceSummary> allBalances;

  const SupplierReportLoaded({
    this.accountReport,
    required this.allBalances,
  });

  @override
  List<Object?> get props => [accountReport, allBalances];
}

class InventoryReportLoaded extends ReportsState {
  final InventoryReport report;

  const InventoryReportLoaded(this.report);

  @override
  List<Object?> get props => [report];
}

class CashboxReportLoaded extends ReportsState {
  final CashboxReport report;

  const CashboxReportLoaded(this.report);

  @override
  List<Object?> get props => [report];
}

class ProfitReportLoaded extends ReportsState {
  final ProfitReport report;

  const ProfitReportLoaded(this.report);

  @override
  List<Object?> get props => [report];
}

class ReportsEmpty extends ReportsState {
  final String message;

  const ReportsEmpty(this.message);

  @override
  List<Object?> get props => [message];
}

class ReportsError extends ReportsState {
  final String message;

  const ReportsError(this.message);

  @override
  List<Object?> get props => [message];
}
