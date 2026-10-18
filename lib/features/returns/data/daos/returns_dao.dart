import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/returns_tables.dart';
import '../../../../core/database/tables/stakeholders_tables.dart';
import '../../../../core/database/tables/trading_tables.dart';
import '../../../../core/database/tables/products_table.dart';

part 'returns_dao.g.dart';

@DriftAccessor(tables: [
  ReturnsCustomer,
  ReturnCustomerItems,
  ReturnsSupplier,
  ReturnSupplierItems,
  Customers,
  Suppliers,
  Products,
  Sales,
  Purchases,
])
class ReturnsDao extends DatabaseAccessor<AppDatabase> with _$ReturnsDaoMixin {
  ReturnsDao(super.db);

  // -------------------------------------------------------------
  // CUSTOMER RETURNS
  // -------------------------------------------------------------

  Future<int> insertCustomerReturn(ReturnsCustomerCompanion companion) {
    return into(returnsCustomer).insert(companion);
  }

  Future<int> insertCustomerReturnItem(ReturnCustomerItemsCompanion companion) {
    return into(returnCustomerItems).insert(companion);
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildCustomerReturnsQuery({
    int? customerId,
    DateTime? fromDate,
    DateTime? toDate,
    String? query,
  }) {
    final joined = select(returnsCustomer).join([
      innerJoin(customers, customers.id.equalsExp(returnsCustomer.customerId)),
      leftOuterJoin(sales, sales.id.equalsExp(returnsCustomer.originalSaleId)),
    ]);

    if (customerId != null) {
      joined.where(returnsCustomer.customerId.equals(customerId));
    }

    if (fromDate != null) {
      joined.where(returnsCustomer.returnDate.isBiggerOrEqualValue(fromDate));
    }

    if (toDate != null) {
      joined.where(returnsCustomer.returnDate.isSmallerOrEqualValue(toDate));
    }

    if (query != null && query.trim().isNotEmpty) {
      final sanitized = query.trim();
      joined.where(
        customers.name.contains(sanitized) |
            (customers.phone.isNotNull() & customers.phone.contains(sanitized)),
      );
    }

    joined.orderBy([
      OrderingTerm(expression: returnsCustomer.returnDate, mode: OrderingMode.desc),
      OrderingTerm(expression: returnsCustomer.id, mode: OrderingMode.desc),
    ]);

    return joined;
  }

  Future<List<TypedResult>> getCustomerReturnsList({
    int? customerId,
    DateTime? fromDate,
    DateTime? toDate,
    String? query,
  }) {
    return _buildCustomerReturnsQuery(
      customerId: customerId,
      fromDate: fromDate,
      toDate: toDate,
      query: query,
    ).get();
  }

  Stream<List<TypedResult>> watchCustomerReturnsList({
    int? customerId,
    DateTime? fromDate,
    DateTime? toDate,
    String? query,
  }) {
    return _buildCustomerReturnsQuery(
      customerId: customerId,
      fromDate: fromDate,
      toDate: toDate,
      query: query,
    ).watch();
  }

  Future<List<TypedResult>> getCustomerReturnItems(int returnId) {
    final query = select(returnCustomerItems).join([
      innerJoin(products, products.id.equalsExp(returnCustomerItems.productId)),
    ])
      ..where(returnCustomerItems.returnId.equals(returnId))
      ..orderBy([OrderingTerm(expression: returnCustomerItems.id, mode: OrderingMode.asc)]);

    return query.get();
  }

  // -------------------------------------------------------------
  // SUPPLIER RETURNS
  // -------------------------------------------------------------

  Future<int> insertSupplierReturn(ReturnsSupplierCompanion companion) {
    return into(returnsSupplier).insert(companion);
  }

  Future<int> insertSupplierReturnItem(ReturnSupplierItemsCompanion companion) {
    return into(returnSupplierItems).insert(companion);
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildSupplierReturnsQuery({
    int? supplierId,
    DateTime? fromDate,
    DateTime? toDate,
    String? query,
  }) {
    final joined = select(returnsSupplier).join([
      innerJoin(suppliers, suppliers.id.equalsExp(returnsSupplier.supplierId)),
      leftOuterJoin(purchases, purchases.id.equalsExp(returnsSupplier.originalPurchaseId)),
    ]);

    if (supplierId != null) {
      joined.where(returnsSupplier.supplierId.equals(supplierId));
    }

    if (fromDate != null) {
      joined.where(returnsSupplier.returnDate.isBiggerOrEqualValue(fromDate));
    }

    if (toDate != null) {
      joined.where(returnsSupplier.returnDate.isSmallerOrEqualValue(toDate));
    }

    if (query != null && query.trim().isNotEmpty) {
      final sanitized = query.trim();
      joined.where(
        suppliers.name.contains(sanitized) |
            (suppliers.phone.isNotNull() & suppliers.phone.contains(sanitized)),
      );
    }

    joined.orderBy([
      OrderingTerm(expression: returnsSupplier.returnDate, mode: OrderingMode.desc),
      OrderingTerm(expression: returnsSupplier.id, mode: OrderingMode.desc),
    ]);

    return joined;
  }

  Future<List<TypedResult>> getSupplierReturnsList({
    int? supplierId,
    DateTime? fromDate,
    DateTime? toDate,
    String? query,
  }) {
    return _buildSupplierReturnsQuery(
      supplierId: supplierId,
      fromDate: fromDate,
      toDate: toDate,
      query: query,
    ).get();
  }

  Stream<List<TypedResult>> watchSupplierReturnsList({
    int? supplierId,
    DateTime? fromDate,
    DateTime? toDate,
    String? query,
  }) {
    return _buildSupplierReturnsQuery(
      supplierId: supplierId,
      fromDate: fromDate,
      toDate: toDate,
      query: query,
    ).watch();
  }

  Future<List<TypedResult>> getSupplierReturnItems(int returnId) {
    final query = select(returnSupplierItems).join([
      innerJoin(products, products.id.equalsExp(returnSupplierItems.productId)),
    ])
      ..where(returnSupplierItems.returnId.equals(returnId))
      ..orderBy([OrderingTerm(expression: returnSupplierItems.id, mode: OrderingMode.asc)]);

    return query.get();
  }
}
