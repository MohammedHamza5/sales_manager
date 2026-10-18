import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/stakeholders_tables.dart';
import '../../../../core/database/tables/system_tables.dart';

part 'suppliers_dao.g.dart';

@DriftAccessor(tables: [Suppliers, SupplierLedgerEntries, AuditLog])
class SuppliersDao extends DatabaseAccessor<AppDatabase> with _$SuppliersDaoMixin {
  SuppliersDao(super.db);

  SimpleSelectStatement<Suppliers, SupplierEntry> _buildSuppliersQuery({
    String? query,
    bool? isActiveOnly,
  }) {
    final selectQuery = select(suppliers);

    if (isActiveOnly != null) {
      selectQuery.where((tbl) => tbl.isActive.equals(isActiveOnly));
    }

    if (query != null && query.trim().isNotEmpty) {
      final sanitized = query.trim();
      selectQuery.where((tbl) =>
          tbl.name.contains(sanitized) |
          (tbl.phone.isNotNull() & tbl.phone.contains(sanitized)));
    }

    selectQuery.orderBy([
      (tbl) => OrderingTerm(expression: tbl.name, mode: OrderingMode.asc),
    ]);

    return selectQuery;
  }

  Future<List<SupplierEntry>> getSuppliersList({
    String? query,
    bool? isActiveOnly,
  }) {
    return _buildSuppliersQuery(query: query, isActiveOnly: isActiveOnly).get();
  }

  Stream<List<SupplierEntry>> watchSuppliersList({
    String? query,
    bool? isActiveOnly,
  }) {
    return _buildSuppliersQuery(query: query, isActiveOnly: isActiveOnly).watch();
  }

  Future<SupplierEntry?> getSupplierById(int id) {
    return (select(suppliers)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertSupplier(SuppliersCompanion companion) {
    return into(suppliers).insert(companion);
  }

  Future<bool> updateSupplierEntry(SuppliersCompanion companion) {
    return update(suppliers).replace(companion);
  }

  Future<int> updateSupplierBalance(int id, int newBalance) {
    return (update(suppliers)..where((tbl) => tbl.id.equals(id))).write(
      SuppliersCompanion(currentBalance: Value(newBalance)),
    );
  }

  Future<int> updateSupplierStatus(int id, bool isActive) {
    return (update(suppliers)..where((tbl) => tbl.id.equals(id))).write(
      SuppliersCompanion(isActive: Value(isActive)),
    );
  }

  Future<int> insertLedgerEntry(SupplierLedgerEntriesCompanion entry) {
    return into(supplierLedgerEntries).insert(entry);
  }

  Future<List<SupplierLedgerEntryData>> getSupplierLedgerEntries(int supplierId) {
    return (select(supplierLedgerEntries)
          ..where((tbl) => tbl.supplierId.equals(supplierId))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  Stream<List<SupplierLedgerEntryData>> watchSupplierLedgerEntries(int supplierId) {
    return (select(supplierLedgerEntries)
          ..where((tbl) => tbl.supplierId.equals(supplierId))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }
}
