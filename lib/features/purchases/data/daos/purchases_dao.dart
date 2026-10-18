import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/trading_tables.dart';
import '../../../../core/database/tables/stakeholders_tables.dart';
import '../../../../core/database/tables/products_table.dart';

part 'purchases_dao.g.dart';

@DriftAccessor(tables: [Purchases, PurchaseItems, Suppliers, Products])
class PurchasesDao extends DatabaseAccessor<AppDatabase>
    with _$PurchasesDaoMixin {
  PurchasesDao(super.db);

  /// Computes the next consecutive invoice number atomically (MAX + 1).
  Future<int> getNextInvoiceNo() async {
    final maxExp = purchases.invoiceNo.max();
    final query = selectOnly(purchases)..addColumns([maxExp]);
    final result = await query.map((row) => row.read(maxExp)).getSingleOrNull();
    return (result ?? 0) + 1;
  }

  /// Inserts a new purchase header row.
  Future<int> insertPurchase(PurchasesCompanion companion) {
    return into(purchases).insert(companion);
  }

  /// Inserts a purchase item row.
  Future<int> insertPurchaseItem(PurchaseItemsCompanion companion) {
    return into(purchaseItems).insert(companion);
  }

  /// Updates status of a purchase (e.g. 'reversed').
  Future<int> updatePurchaseStatus(int id, String status) {
    return (update(purchases)..where((tbl) => tbl.id.equals(id))).write(
      PurchasesCompanion(status: Value(status)),
    );
  }

  /// Builds query joining purchases and suppliers.
  JoinedSelectStatement<HasResultSet, dynamic> _buildPurchasesQuery({
    int? supplierId,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
    String? query,
  }) {
    final joined = select(purchases).join([
      innerJoin(suppliers, suppliers.id.equalsExp(purchases.supplierId)),
    ]);

    if (supplierId != null) {
      joined.where(purchases.supplierId.equals(supplierId));
    }

    if (status != null) {
      joined.where(purchases.status.equals(status));
    }

    if (fromDate != null) {
      joined.where(purchases.purchaseDate.isBiggerOrEqualValue(fromDate));
    }

    if (toDate != null) {
      joined.where(purchases.purchaseDate.isSmallerOrEqualValue(toDate));
    }

    if (query != null && query.trim().isNotEmpty) {
      final sanitized = query.trim();
      final asInt = int.tryParse(sanitized);
      if (asInt != null) {
        joined.where(purchases.invoiceNo.equals(asInt) |
            suppliers.name.contains(sanitized));
      } else {
        joined.where(suppliers.name.contains(sanitized));
      }
    }

    joined.orderBy([
      OrderingTerm(expression: purchases.purchaseDate, mode: OrderingMode.desc),
      OrderingTerm(expression: purchases.invoiceNo, mode: OrderingMode.desc),
      OrderingTerm(expression: purchases.id, mode: OrderingMode.desc),
    ]);

    return joined;
  }

  /// Fetches purchases list with supplier details.
  Future<List<TypedResult>> getPurchasesList({
    int? supplierId,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
    String? query,
  }) {
    return _buildPurchasesQuery(
      supplierId: supplierId,
      fromDate: fromDate,
      toDate: toDate,
      status: status,
      query: query,
    ).get();
  }

  /// Watches purchases list reactively.
  Stream<List<TypedResult>> watchPurchasesList({
    int? supplierId,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
    String? query,
  }) {
    return _buildPurchasesQuery(
      supplierId: supplierId,
      fromDate: fromDate,
      toDate: toDate,
      status: status,
      query: query,
    ).watch();
  }

  /// Gets single purchase header joined with supplier.
  Future<TypedResult?> getPurchaseById(int id) {
    return (select(purchases).join([
      innerJoin(suppliers, suppliers.id.equalsExp(purchases.supplierId)),
    ])..where(purchases.id.equals(id)))
        .getSingleOrNull();
  }

  /// Gets purchase items joined with product for a given purchase.
  Future<List<TypedResult>> getPurchaseItemsWithProduct(int purchaseId) {
    return (select(purchaseItems).join([
      innerJoin(products, products.id.equalsExp(purchaseItems.productId)),
    ])
          ..where(purchaseItems.purchaseId.equals(purchaseId))
          ..orderBy([
            OrderingTerm(expression: purchaseItems.id, mode: OrderingMode.asc),
          ]))
        .get();
  }
}
