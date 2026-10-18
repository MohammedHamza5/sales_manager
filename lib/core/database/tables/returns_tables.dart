import 'package:drift/drift.dart';
import '../converters/decimal_converter.dart';
import 'products_table.dart';
import 'stakeholders_tables.dart';
import 'trading_tables.dart';

@DataClassName('ReturnCustomerEntry')
class ReturnsCustomer extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get originalSaleId => integer().nullable().references(Sales, #id)();
  IntColumn get customerId => integer().references(Customers, #id)();
  DateTimeColumn get returnDate => dateTime()();
  IntColumn get totalAmount => integer()(); // بالقرش
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get createdBy => text().withDefault(const Constant('admin'))();
}

@DataClassName('ReturnCustomerItemEntry')
class ReturnCustomerItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get returnId => integer().references(ReturnsCustomer, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get quantity => text().map(const DecimalConverter())();
  IntColumn get unitPrice => integer()(); // بالقرش
  IntColumn get lineTotal => integer()(); // بالقرش
}

@DataClassName('ReturnSupplierEntry')
class ReturnsSupplier extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get originalPurchaseId => integer().nullable().references(Purchases, #id)();
  IntColumn get supplierId => integer().references(Suppliers, #id)();
  DateTimeColumn get returnDate => dateTime()();
  IntColumn get totalAmount => integer()(); // بالقرش
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get createdBy => text().withDefault(const Constant('admin'))();
}

@DataClassName('ReturnSupplierItemEntry')
class ReturnSupplierItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get returnId => integer().references(ReturnsSupplier, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get quantity => text().map(const DecimalConverter())();
  IntColumn get unitPrice => integer()(); // بالقرش
  IntColumn get lineTotal => integer()(); // بالقرش
}
