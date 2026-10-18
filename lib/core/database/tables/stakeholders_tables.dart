import 'package:drift/drift.dart';

@DataClassName('CustomerEntry')
class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get currentBalance => integer().withDefault(const Constant(0))(); // بالقرش
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get createdBy => text().withDefault(const Constant('admin'))();
}

@DataClassName('SupplierEntry')
class Suppliers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get currentBalance => integer().withDefault(const Constant(0))(); // بالقرش
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get createdBy => text().withDefault(const Constant('admin'))();
}

@DataClassName('CustomerLedgerEntryData')
class CustomerLedgerEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get customerId => integer().references(Customers, #id)();
  TextColumn get entryType => text()(); // sale, payment, return, opening_balance, reversal
  IntColumn get amount => integer()(); // بالقرش دائمًا موجب
  TextColumn get effect => text()(); // increase, decrease
  IntColumn get balanceAfter => integer()(); // بالقرش
  TextColumn get referenceType => text().nullable()();
  IntColumn get referenceId => integer().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get createdBy => text().withDefault(const Constant('admin'))();
}

@DataClassName('SupplierLedgerEntryData')
class SupplierLedgerEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get supplierId => integer().references(Suppliers, #id)();
  TextColumn get entryType => text()(); // purchase, payment, return, opening_balance, reversal
  IntColumn get amount => integer()(); // بالقرش دائمًا موجب
  TextColumn get effect => text()(); // increase, decrease
  IntColumn get balanceAfter => integer()(); // بالقرش
  TextColumn get referenceType => text().nullable()();
  IntColumn get referenceId => integer().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get createdBy => text().withDefault(const Constant('admin'))();
}
