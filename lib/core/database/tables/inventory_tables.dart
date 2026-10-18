import 'package:drift/drift.dart';
import '../converters/decimal_converter.dart';
import 'products_table.dart';

@DataClassName('InventoryMovementEntry')
class InventoryMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get movementType => text()(); // opening_balance, purchase, sale, customer_return, supplier_return, adjustment, reversal
  TextColumn get quantityDelta => text().map(const DecimalConverter())();
  TextColumn get balanceAfter => text().map(const DecimalConverter())();
  TextColumn get referenceType => text().nullable()();
  IntColumn get referenceId => integer().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get createdBy => text().withDefault(const Constant('admin'))();
}

@DataClassName('StockAdjustmentEntry')
class StockAdjustments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get quantityDelta => text().map(const DecimalConverter())();
  TextColumn get reason => text()(); // إلزامي حسب الـ PRD
  DateTimeColumn get adjustmentDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get createdBy => text().withDefault(const Constant('admin'))();
}
