import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/stakeholders_tables.dart';
import '../../../../core/database/tables/system_tables.dart';

part 'customers_dao.g.dart';

@DriftAccessor(tables: [Customers, CustomerLedgerEntries, AuditLog])
class CustomersDao extends DatabaseAccessor<AppDatabase> with _$CustomersDaoMixin {
  CustomersDao(super.db);

  SimpleSelectStatement<Customers, CustomerEntry> _buildCustomersQuery({
    String? query,
    bool? isActiveOnly,
  }) {
    final selectQuery = select(customers);

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

  Future<List<CustomerEntry>> getCustomersList({
    String? query,
    bool? isActiveOnly,
  }) {
    return _buildCustomersQuery(query: query, isActiveOnly: isActiveOnly).get();
  }

  Stream<List<CustomerEntry>> watchCustomersList({
    String? query,
    bool? isActiveOnly,
  }) {
    return _buildCustomersQuery(query: query, isActiveOnly: isActiveOnly).watch();
  }

  Future<CustomerEntry?> getCustomerById(int id) {
    return (select(customers)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertCustomer(CustomersCompanion companion) {
    return into(customers).insert(companion);
  }

  Future<bool> updateCustomerEntry(CustomersCompanion companion) {
    return update(customers).replace(companion);
  }

  Future<int> updateCustomerBalance(int id, int newBalance) {
    return (update(customers)..where((tbl) => tbl.id.equals(id))).write(
      CustomersCompanion(currentBalance: Value(newBalance)),
    );
  }

  Future<int> updateCustomerStatus(int id, bool isActive) {
    return (update(customers)..where((tbl) => tbl.id.equals(id))).write(
      CustomersCompanion(isActive: Value(isActive)),
    );
  }

  Future<int> insertLedgerEntry(CustomerLedgerEntriesCompanion entry) {
    return into(customerLedgerEntries).insert(entry);
  }

  Future<List<CustomerLedgerEntryData>> getCustomerLedgerEntries(int customerId) {
    return (select(customerLedgerEntries)
          ..where((tbl) => tbl.customerId.equals(customerId))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  Stream<List<CustomerLedgerEntryData>> watchCustomerLedgerEntries(int customerId) {
    return (select(customerLedgerEntries)
          ..where((tbl) => tbl.customerId.equals(customerId))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }
}
