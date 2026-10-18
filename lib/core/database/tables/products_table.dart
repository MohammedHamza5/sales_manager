import 'package:drift/drift.dart';
import '../converters/decimal_converter.dart';

@DataClassName('ProductEntry')
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get code => text().nullable()();
  TextColumn get unit => text()();
  IntColumn get currentSalePrice => integer()();
  IntColumn get currentPurchasePrice => integer()();
  TextColumn get currentQuantity =>
      text().map(const DecimalConverter()).withDefault(const Constant('0'))();
  TextColumn get lowStockThreshold =>
      text().map(const DecimalConverter()).nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get createdBy => text().withDefault(const Constant('admin'))();
}
