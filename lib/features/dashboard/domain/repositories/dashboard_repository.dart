import '../../../../core/money/money.dart';
import '../../../products/domain/entities/product.dart';
import '../entities/daily_stats.dart';
import '../entities/dashboard_data.dart';
import '../entities/recent_activity.dart';

abstract interface class DashboardRepository {
  Stream<Money> watchCashboxBalance();
  Stream<DailyStats> watchTodayStats();
  Stream<Money> watchTotalCustomerDebt();
  Stream<Money> watchTotalSupplierPayables();
  Stream<List<Product>> watchLowStockAlerts();
  Stream<List<RecentActivity>> watchRecentActivities();
  Stream<DashboardData> watchDashboardData();
  Future<DashboardData> getDashboardData();
}
