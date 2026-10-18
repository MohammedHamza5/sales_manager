import 'dart:io';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'converters/decimal_converter.dart';
import 'tables/products_table.dart';
import 'tables/inventory_tables.dart';
import 'tables/stakeholders_tables.dart';
import 'tables/trading_tables.dart';
import 'tables/payments_cashbox_tables.dart';
import 'tables/returns_tables.dart';
import 'tables/system_tables.dart';
import 'tables/sync_tables.dart';

import '../../features/products/data/daos/products_dao.dart';
import '../../features/inventory/data/daos/inventory_movements_dao.dart';
import '../../features/customers/data/daos/customers_dao.dart';
import '../../features/suppliers/data/daos/suppliers_dao.dart';
import '../../features/purchases/data/daos/purchases_dao.dart';
import '../../features/sales/data/daos/sales_dao.dart';
import '../../features/returns/data/daos/returns_dao.dart';
import '../../features/audit_log/data/daos/audit_log_dao.dart';
import '../../features/cashbox/data/daos/cashbox_dao.dart';
import '../../features/expenses/data/daos/expenses_dao.dart';
import '../../features/customer_payments/data/daos/customer_payments_dao.dart';
import '../../features/supplier_payments/data/daos/supplier_payments_dao.dart';
import 'daos/sync_queue_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Products,
    InventoryMovements,
    StockAdjustments,
    Customers,
    Suppliers,
    CustomerLedgerEntries,
    SupplierLedgerEntries,
    Sales,
    SaleItems,
    Purchases,
    PurchaseItems,
    CustomerPayments,
    SupplierPayments,
    CashboxTransactions,
    Expenses,
    ReturnsCustomer,
    ReturnCustomerItems,
    ReturnsSupplier,
    ReturnSupplierItems,
    AuditLog,
    Settings,
    BackupsMeta,
    SyncQueue,
  ],
  daos: [
    ProductsDao,
    InventoryMovementsDao,
    CustomersDao,
    SuppliersDao,
    PurchasesDao,
    SalesDao,
    ReturnsDao,
    AuditLogDao,
    CashboxDao,
    ExpensesDao,
    CustomerPaymentsDao,
    SupplierPaymentsDao,
    SyncQueueDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  AppDatabase.forTesting(super.e);

  factory AppDatabase.memory() {
    return AppDatabase(NativeDatabase.memory());
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(syncQueue);
          }
        },
        beforeOpen: (details) async {
          // Enable Foreign Keys in SQLite
          await customStatement('PRAGMA foreign_keys = ON');
          await customStatement('''
            CREATE TABLE IF NOT EXISTS entity_cloud_mappings (
              entity_type TEXT NOT NULL,
              local_id INTEGER NOT NULL,
              cloud_uuid TEXT NOT NULL,
              PRIMARY KEY (entity_type, local_id)
            );
          ''');
          await customStatement('''
            CREATE INDEX IF NOT EXISTS idx_entity_cloud_mappings_uuid 
            ON entity_cloud_mappings(entity_type, cloud_uuid);
          ''');
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationSupportDirectory();
    final file = File(p.join(dbFolder.path, 'sales_manager.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
