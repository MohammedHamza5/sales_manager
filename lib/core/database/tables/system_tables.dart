import 'package:drift/drift.dart';

@DataClassName('AuditLogEntry')
class AuditLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()(); // product, customer, supplier, sale, purchase, payment, cashbox, expense, return, adjustment
  IntColumn get entityId => integer()();
  TextColumn get action => text()(); // create, update, cancel, reverse
  TextColumn get payloadBefore => text().nullable()();
  TextColumn get payloadAfter => text().nullable()();
  DateTimeColumn get performedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get note => text().nullable()();
  TextColumn get userId => text().withDefault(const Constant('admin'))();
}

@DataClassName('SettingEntry')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}

@DataClassName('BackupMetaEntry')
class BackupsMeta extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get filePath => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get sizeBytes => integer()();
  TextColumn get type => text()(); // manual, auto
  IntColumn get schemaVersion => integer()();
}
