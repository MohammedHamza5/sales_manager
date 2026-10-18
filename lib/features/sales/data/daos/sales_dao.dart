import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/trading_tables.dart';
import '../../../../core/database/tables/stakeholders_tables.dart';
import '../../../../core/database/tables/products_table.dart';

part 'sales_dao.g.dart';

@DriftAccessor(tables: [Sales, SaleItems, Customers, Products])
class SalesDao extends DatabaseAccessor<AppDatabase> with _$SalesDaoMixin {
  SalesDao(super.db);

  /// Computes the next consecutive invoice number atomically (MAX + 1).
  Future<int> getNextInvoiceNo() async {
    final maxExp = sales.invoiceNo.max();
    final query = selectOnly(sales)..addColumns([maxExp]);
    final result = await query.map((row) => row.read(maxExp)).getSingleOrNull();
    return (result ?? 0) + 1;
  }

  /// Inserts a new sales header row.
  Future<int> insertSale(SalesCompanion companion) {
    return into(sales).insert(companion);
  }

  /// Inserts a sale item row.
  Future<int> insertSaleItem(SaleItemsCompanion companion) {
    return into(saleItems).insert(companion);
  }

  /// Updates status of a sale (e.g. 'reversed').
  Future<int> updateSaleStatus(int id, String status) {
    return (update(sales)..where((tbl) => tbl.id.equals(id))).write(
      SalesCompanion(status: Value(status)),
    );
  }

  /// Builds query joining sales and customers.
  JoinedSelectStatement<HasResultSet, dynamic> _buildSalesQuery({
    int? customerId,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
    String? query,
  }) {
    final joined = select(sales).join([
      innerJoin(customers, customers.id.equalsExp(sales.customerId)),
    ]);

    if (customerId != null) {
      joined.where(sales.customerId.equals(customerId));
    }

    if (status != null) {
      joined.where(sales.status.equals(status));
    }

    if (fromDate != null) {
      joined.where(sales.saleDate.isBiggerOrEqualValue(fromDate));
    }

    if (toDate != null) {
      joined.where(sales.saleDate.isSmallerOrEqualValue(toDate));
    }

    if (query != null && query.trim().isNotEmpty) {
      final sanitized = query.trim();
      final asInt = int.tryParse(sanitized);
      if (asInt != null) {
        joined.where(sales.invoiceNo.equals(asInt) |
            customers.name.contains(sanitized) |
            (customers.phone.isNotNull() & customers.phone.contains(sanitized)));
      } else {
        joined.where(customers.name.contains(sanitized) |
            (customers.phone.isNotNull() & customers.phone.contains(sanitized)));
      }
    }

    joined.orderBy([
      OrderingTerm(expression: sales.saleDate, mode: OrderingMode.desc),
      OrderingTerm(expression: sales.invoiceNo, mode: OrderingMode.desc),
      OrderingTerm(expression: sales.id, mode: OrderingMode.desc),
    ]);

    return joined;
  }

  /// Fetches sales list with customer details.
  Future<List<TypedResult>> getSalesList({
    int? customerId,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
    String? query,
  }) {
    return _buildSalesQuery(
      customerId: customerId,
      fromDate: fromDate,
      toDate: toDate,
      status: status,
      query: query,
    ).get();
  }

  /// Watches sales list in real-time with customer details.
  Stream<List<TypedResult>> watchSalesList({
    int? customerId,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
    String? query,
  }) {
    return _buildSalesQuery(
      customerId: customerId,
      fromDate: fromDate,
      toDate: toDate,
      status: status,
      query: query,
    ).watch();
  }

  /// Gets a sale with customer details by sale ID.
  Future<TypedResult?> getSaleHeader(int id) {
    final query = select(sales).join([
      innerJoin(customers, customers.id.equalsExp(sales.customerId)),
    ])..where(sales.id.equals(id));

    return query.getSingleOrNull();
  }

  /// Gets all items belonging to a sale, joined with product details.
  Future<List<TypedResult>> getSaleItems(int saleId) {
    final query = select(saleItems).join([
      innerJoin(products, products.id.equalsExp(saleItems.productId)),
    ])
      ..where(saleItems.saleId.equals(saleId))
      ..orderBy([OrderingTerm(expression: saleItems.id, mode: OrderingMode.asc)]);

    return query.get();
  }
}
