import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';

class CollectionReportItem extends Equatable {
  final int paymentId;
  final DateTime paymentDate;
  final String customerName;
  final Money amount;
  final int? linkedSaleInvoiceNo;
  final String? note;

  const CollectionReportItem({
    required this.paymentId,
    required this.paymentDate,
    required this.customerName,
    required this.amount,
    this.linkedSaleInvoiceNo,
    this.note,
  });

  @override
  List<Object?> get props => [
        paymentId,
        paymentDate,
        customerName,
        amount,
        linkedSaleInvoiceNo,
        note,
      ];
}

class CollectionsReport extends Equatable {
  final DateTime from;
  final DateTime to;
  final Money totalCollected;
  final int paymentsCount;
  final List<CollectionReportItem> items;

  const CollectionsReport({
    required this.from,
    required this.to,
    required this.totalCollected,
    required this.paymentsCount,
    required this.items,
  });

  @override
  List<Object?> get props => [
        from,
        to,
        totalCollected,
        paymentsCount,
        items,
      ];
}
