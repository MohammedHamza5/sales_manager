import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/money/money.dart';
import '../../../products/data/models/product_mapper.dart';
import '../../../products/domain/entities/product.dart';
import '../../domain/entities/daily_stats.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/entities/recent_activity.dart';
import '../../domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final AppDatabase _db;

  DashboardRepositoryImpl(this._db);

  DateTime get _todayStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  Stream<Money> watchCashboxBalance() {
    return (_db.select(_db.cashboxTransactions)
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(1))
        .watchSingleOrNull()
        .map((tx) => tx != null ? Money.fromPiastres(tx.balanceAfter) : Money.zero);
  }

  @override
  Stream<DailyStats> watchTodayStats() {
    final start = _todayStart;
    return _db.tableUpdates().asyncMap((_) async {
      return _computeTodayStats(start);
    });
  }

  Future<DailyStats> _computeTodayStats(DateTime start) async {
    final sales = await (_db.select(_db.sales)
          ..where((s) => s.createdAt.isBiggerOrEqualValue(start) & s.status.equals('confirmed')))
        .get();

    final purchases = await (_db.select(_db.purchases)
          ..where((p) => p.createdAt.isBiggerOrEqualValue(start) & p.status.equals('confirmed')))
        .get();

    final collections = await (_db.select(_db.customerPayments)
          ..where((p) => p.paymentDate.isBiggerOrEqualValue(start)))
        .get();

    final expenses = await (_db.select(_db.expenses)
          ..where((e) => e.expenseDate.isBiggerOrEqualValue(start)))
        .get();

    final returns = await (_db.select(_db.returnsCustomer)
          ..where((r) => r.createdAt.isBiggerOrEqualValue(start)))
        .get();

    final totalSales = sales.fold<int>(0, (sum, s) => sum + s.totalAmount);
    final totalPurchases = purchases.fold<int>(0, (sum, p) => sum + p.totalAmount);
    final totalCollections = collections.fold<int>(0, (sum, c) => sum + c.amount);
    final totalExpenses = expenses.fold<int>(0, (sum, e) => sum + e.amount);
    final totalReturns = returns.fold<int>(0, (sum, r) => sum + r.totalAmount);

    return DailyStats(
      todaySales: Money.fromPiastres(totalSales),
      todayCollections: Money.fromPiastres(totalCollections),
      todayPurchases: Money.fromPiastres(totalPurchases),
      todayExpenses: Money.fromPiastres(totalExpenses),
      todayReturns: Money.fromPiastres(totalReturns),
      todaySalesCount: sales.length,
      todayCollectionsCount: collections.length,
      todayReturnsCount: returns.length,
    );
  }

  @override
  Stream<Money> watchTotalCustomerDebt() {
    return (_db.select(_db.customers)
          ..where((c) => c.currentBalance.isBiggerThanValue(0)))
        .watch()
        .map((customers) {
      final total = customers.fold<int>(0, (sum, c) => sum + c.currentBalance);
      return Money.fromPiastres(total);
    });
  }

  @override
  Stream<Money> watchTotalSupplierPayables() {
    return (_db.select(_db.suppliers)
          ..where((s) => s.currentBalance.isBiggerThanValue(0)))
        .watch()
        .map((suppliers) {
      final total = suppliers.fold<int>(0, (sum, s) => sum + s.currentBalance);
      return Money.fromPiastres(total);
    });
  }

  @override
  Stream<List<Product>> watchLowStockAlerts() {
    return (_db.select(_db.products)..where((p) => p.isActive.equals(true)))
        .watch()
        .map((entries) {
      return entries
          .map(ProductMapper.toDomain)
          .where((p) => p.isLowStock)
          .toList();
    });
  }

  @override
  Stream<List<RecentActivity>> watchRecentActivities() {
    return (_db.select(_db.cashboxTransactions)
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(10))
        .watch()
        .map((entries) => entries.map(_mapTransactionToActivity).toList());
  }

  RecentActivity _mapTransactionToActivity(CashboxTransactionEntry tx) {
    String type;
    String desc;
    switch (tx.transactionType) {
      case 'sale_cash_in':
        type = 'sale';
        desc = tx.note ?? 'مبيعات نقدية #${tx.referenceId ?? ""}';
        break;
      case 'customer_payment_in':
        type = 'customer_payment';
        desc = tx.note ?? 'تحصيل من عميل';
        break;
      case 'purchase_cash_out':
        type = 'purchase';
        desc = tx.note ?? 'مشتريات نقدية #${tx.referenceId ?? ""}';
        break;
      case 'supplier_payment_out':
        type = 'supplier_payment';
        desc = tx.note ?? 'سداد لمورد';
        break;
      case 'expense_out':
        type = 'expense';
        desc = tx.note ?? 'مصروف تشغيلي';
        break;
      case 'customer_return_out':
        type = 'customer_return';
        desc = tx.note ?? 'مرتجع مبيعات';
        break;
      case 'supplier_return_in':
        type = 'supplier_return';
        desc = tx.note ?? 'مرتجع مشتريات';
        break;
      default:
        type = tx.transactionType;
        desc = tx.note ?? 'حركة نقدية';
    }
    return RecentActivity(
      id: tx.id.toString(),
      type: type,
      description: desc,
      amount: Money.fromPiastres(tx.amount),
      time: tx.createdAt,
      direction: tx.direction,
      referenceId: tx.referenceId,
    );
  }

  @override
  Future<DashboardData> getDashboardData() async {
    // 1. Cashbox balance
    final latestTx = await (_db.select(_db.cashboxTransactions)
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(1))
        .getSingleOrNull();
    final cashboxBalance =
        latestTx != null ? Money.fromPiastres(latestTx.balanceAfter) : Money.zero;

    // 2. Today stats
    final dailyStats = await _computeTodayStats(_todayStart);

    // 3. Customer debt & Customer credits
    final debtorCustomers = await (_db.select(_db.customers)
          ..where((c) => c.currentBalance.isBiggerThanValue(0)))
        .get();
    final totalCustomerDebt = Money.fromPiastres(
      debtorCustomers.fold<int>(0, (sum, c) => sum + c.currentBalance),
    );

    final creditorCustomers = await (_db.select(_db.customers)
          ..where((c) => c.currentBalance.isSmallerThanValue(0)))
        .get();
    final totalCustomerCredit = Money.fromPiastres(
      creditorCustomers.fold<int>(0, (sum, c) => sum + c.currentBalance.abs()),
    );

    // 4. Supplier payables
    final suppliers = await (_db.select(_db.suppliers)
          ..where((s) => s.currentBalance.isBiggerThanValue(0)))
        .get();
    final totalSupplierPayables = Money.fromPiastres(
      suppliers.fold<int>(0, (sum, s) => sum + s.currentBalance),
    );

    // 5. Low stock alerts
    final productEntries = await (_db.select(_db.products)
          ..where((p) => p.isActive.equals(true)))
        .get();
    final lowStockProducts = productEntries
        .map(ProductMapper.toDomain)
        .where((p) => p.isLowStock)
        .toList();

    // 6. Recent activities
    final recentTx = await (_db.select(_db.cashboxTransactions)
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(10))
        .get();
    final recentActivities = recentTx.map(_mapTransactionToActivity).toList();

    return DashboardData(
      cashboxBalance: cashboxBalance,
      dailyStats: dailyStats,
      totalCustomerDebt: totalCustomerDebt,
      totalCustomerCredit: totalCustomerCredit,
      totalSupplierPayables: totalSupplierPayables,
      lowStockProducts: lowStockProducts,
      recentActivities: recentActivities,
    );
  }

  @override
  Stream<DashboardData> watchDashboardData() async* {
    yield await getDashboardData();
    await for (final _ in _db.tableUpdates()) {
      yield await getDashboardData();
    }
  }
}
