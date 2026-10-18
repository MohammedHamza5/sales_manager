import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';

class ProfitReportItem extends Equatable {
  final int productId;
  final String productName;
  final String unit;
  final Decimal soldQuantity;
  final Money totalRevenue;
  final Money totalCost;
  final Money grossProfit;
  final double marginPercentage;

  const ProfitReportItem({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.soldQuantity,
    required this.totalRevenue,
    required this.totalCost,
    required this.grossProfit,
    required this.marginPercentage,
  });

  @override
  List<Object?> get props => [
        productId,
        productName,
        unit,
        soldQuantity,
        totalRevenue,
        totalCost,
        grossProfit,
        marginPercentage,
      ];
}

class ProfitReport extends Equatable {
  final DateTime from;
  final DateTime to;
  final Money totalRevenue;
  final Money totalCost;
  final Money totalGrossProfit;
  final double overallMarginPercentage;
  final List<ProfitReportItem> items;

  const ProfitReport({
    required this.from,
    required this.to,
    required this.totalRevenue,
    required this.totalCost,
    required this.totalGrossProfit,
    required this.overallMarginPercentage,
    required this.items,
  });

  @override
  List<Object?> get props => [
        from,
        to,
        totalRevenue,
        totalCost,
        totalGrossProfit,
        overallMarginPercentage,
        items,
      ];
}
