import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/products_table.dart';
import '../../../../core/database/tables/inventory_tables.dart';
import '../../../../core/database/tables/system_tables.dart';

part 'products_dao.g.dart';

@DriftAccessor(tables: [Products, InventoryMovements, AuditLog])
class ProductsDao extends DatabaseAccessor<AppDatabase> with _$ProductsDaoMixin {
  ProductsDao(super.db);

  SimpleSelectStatement<Products, ProductEntry> _buildProductsQuery({
    String? query,
    bool? isActiveOnly,
  }) {
    final selectQuery = select(products);

    if (isActiveOnly != null) {
      selectQuery.where((tbl) => tbl.isActive.equals(isActiveOnly));
    }

    if (query != null && query.trim().isNotEmpty) {
      final sanitized = query.trim();
      selectQuery.where((tbl) =>
          tbl.name.contains(sanitized) | tbl.code.contains(sanitized));
    }

    selectQuery.orderBy([
      (tbl) => OrderingTerm(expression: tbl.name, mode: OrderingMode.asc),
    ]);

    return selectQuery;
  }

  Future<List<ProductEntry>> getProductsList({
    String? query,
    bool? isActiveOnly,
  }) {
    return _buildProductsQuery(query: query, isActiveOnly: isActiveOnly).get();
  }

  Stream<List<ProductEntry>> watchProductsList({
    String? query,
    bool? isActiveOnly,
  }) {
    return _buildProductsQuery(query: query, isActiveOnly: isActiveOnly).watch();
  }

  Future<ProductEntry?> getProductById(int id) {
    return (select(products)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<ProductEntry?> getProductByCode(String code) {
    return (select(products)..where((tbl) => tbl.code.equals(code))).getSingleOrNull();
  }

  Future<int> insertProduct(ProductsCompanion companion) {
    return into(products).insert(companion);
  }

  Future<bool> updateProductEntry(ProductsCompanion companion) {
    return update(products).replace(companion);
  }

  Future<int> toggleProductStatus(int id, bool isActive) {
    return (update(products)..where((tbl) => tbl.id.equals(id))).write(
      ProductsCompanion(isActive: Value(isActive)),
    );
  }
}
