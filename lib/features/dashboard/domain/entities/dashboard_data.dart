import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';
import '../../../products/domain/entities/product.dart';
import 'daily_stats.dart';
import 'recent_activity.dart';

class DashboardData extends Equatable {
  final Money cashboxBalance;
  final DailyStats dailyStats;
  final Money totalCustomerDebt;
  final Money totalCustomerCredit;
  final Money totalSupplierPayables;
  final List<Product> lowStockProducts;
  final List<RecentActivity> recentActivities;

  const DashboardData({
    required this.cashboxBalance,
    required this.dailyStats,
    required this.totalCustomerDebt,
    this.totalCustomerCredit = Money.zero,
    required this.totalSupplierPayables,
    required this.lowStockProducts,
    required this.recentActivities,
  });

  static const empty = DashboardData(
    cashboxBalance: Money.zero,
    dailyStats: DailyStats.empty,
    totalCustomerDebt: Money.zero,
    totalCustomerCredit: Money.zero,
    totalSupplierPayables: Money.zero,
    lowStockProducts: [],
    recentActivities: [],
  );

  @override
  List<Object?> get props => [
        cashboxBalance,
        dailyStats,
        totalCustomerDebt,
        totalCustomerCredit,
        totalSupplierPayables,
        lowStockProducts,
        recentActivities,
      ];
}
