import 'package:drift/drift.dart';

@DataClassName('SyncQueueEntry')
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()(); // products, customers, suppliers, sales, purchases, customer_payments, supplier_payments, cashbox_transactions, expenses, inventory_movements, stock_adjustments, returns_customer, returns_supplier, audit_log
  TextColumn get entityUuid => text()();
  TextColumn get action => text()(); // insert, update, delete
  TextColumn get payload => text()(); // JSON string representation
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, syncing, synced, failed
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
}
