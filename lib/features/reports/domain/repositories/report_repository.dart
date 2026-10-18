import '../../../../core/result/result.dart';
import '../entities/sales_report.dart';
import '../entities/collections_report.dart';
import '../entities/customer_account_report.dart';
import '../entities/supplier_account_report.dart';
import '../entities/inventory_report.dart';
import '../entities/cashbox_report.dart';
import '../entities/profit_report.dart';

abstract interface class ReportRepository {
  /// Fetches sales report with optional customer and status filters
  Future<Result<SalesReport>> getSalesReport({
    required DateTime from,
    required DateTime to,
    int? customerId,
    String? status,
  });

  /// Fetches collections report with optional customer filter
  Future<Result<CollectionsReport>> getCollectionsReport({
    required DateTime from,
    required DateTime to,
    int? customerId,
  });

  /// Fetches statement of account for a specific customer over a date range
  Future<Result<CustomerAccountReport>> getCustomerReport({
    required int customerId,
    required DateTime from,
    required DateTime to,
  });

  /// Fetches current balances summary for all customers
  Future<Result<List<CustomerBalanceSummary>>> getAllCustomerBalances();

  /// Fetches statement of account for a specific supplier over a date range
  Future<Result<SupplierAccountReport>> getSupplierReport({
    required int supplierId,
    required DateTime from,
    required DateTime to,
  });

  /// Fetches current balances summary for all suppliers
  Future<Result<List<SupplierBalanceSummary>>> getAllSupplierBalances();

  /// Fetches inventory valuation, low stock alerts, and movements log
  Future<Result<InventoryReport>> getInventoryReport({
    int? productId,
    String? movementType,
    DateTime? from,
    DateTime? to,
  });

  /// Fetches cashbox movement, inflow, outflow, and net cashflow
  Future<Result<CashboxReport>> getCashboxReport({
    required DateTime from,
    required DateTime to,
    String? transactionType,
  });

  /// Fetches gross profit, cost of goods sold, and margin analytics
  Future<Result<ProfitReport>> getProfitReport({
    required DateTime from,
    required DateTime to,
    int? productId,
  });
}
