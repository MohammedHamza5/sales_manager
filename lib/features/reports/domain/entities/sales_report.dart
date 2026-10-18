import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';

class SalesReportItem extends Equatable {
  final int invoiceNo;
  final DateTime saleDate;
  final String customerName;
  final Money totalAmount;
  final Money paidAmount;
  final Money remainingAmount;
  final String status;

  const SalesReportItem({
    required this.invoiceNo,
    required this.saleDate,
    required this.customerName,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.status,
  });

  @override
  List<Object?> get props => [
        invoiceNo,
        saleDate,
        customerName,
        totalAmount,
        paidAmount,
        remainingAmount,
        status,
      ];
}

class SalesReport extends Equatable {
  final DateTime from;
  final DateTime to;
  final Money totalSales;
  final Money totalPaid;
  final Money totalRemaining;
  final int salesCount;
  final List<SalesReportItem> items;

  const SalesReport({
    required this.from,
    required this.to,
    required this.totalSales,
    required this.totalPaid,
    required this.totalRemaining,
    required this.salesCount,
    required this.items,
  });

  @override
  List<Object?> get props => [
        from,
        to,
        totalSales,
        totalPaid,
        totalRemaining,
        salesCount,
        items,
      ];
}
