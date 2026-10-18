import 'package:drift/drift.dart';
import '../converters/decimal_converter.dart';
import 'products_table.dart';
import 'stakeholders_tables.dart';

@DataClassName('SaleEntry')
class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceNo => integer().unique()();
  IntColumn get customerId => integer().references(Customers, #id)();
  DateTimeColumn get saleDate => dateTime()();
  IntColumn get totalAmount => integer()(); // بالقرش
  IntColumn get paidAmountAtCreation => integer()(); // بالقرش
  TextColumn get status => text().withDefault(const Constant('confirmed'))(); // confirmed, reversed
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get createdBy => text().withDefault(const Constant('admin'))();
}

@DataClassName('SaleItemEntry')
class SaleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(Sales, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get quantity => text().map(const DecimalConverter())();
  IntColumn get unitPriceAtSale => integer()(); // Snapshot بالقرش
  IntColumn get lineTotal => integer()(); // بالقرش
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('PurchaseEntry')
class Purchases extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceNo => integer().unique()();
  IntColumn get supplierId => integer().references(Suppliers, #id)();
  DateTimeColumn get purchaseDate => dateTime()();
  IntColumn get totalAmount => integer()(); // بالقرش
  IntColumn get paidAmountAtCreation => integer()(); // بالقرش
  TextColumn get status => text().withDefault(const Constant('confirmed'))(); // confirmed, reversed
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get createdBy => text().withDefault(const Constant('admin'))();
}

@DataClassName('PurchaseItemEntry')
class PurchaseItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get purchaseId => integer().references(Purchases, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get quantity => text().map(const DecimalConverter())();
  IntColumn get unitCostAtPurchase => integer()(); // Snapshot بالقرش
  IntColumn get lineTotal => integer()(); // بالقرش
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
