import 'package:drift/drift.dart';
import 'stakeholders_tables.dart';
import 'trading_tables.dart';

@DataClassName('CustomerPaymentEntry')
class CustomerPayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get customerId => integer().references(Customers, #id)();
  IntColumn get amount => integer()(); // بالقرش
  DateTimeColumn get paymentDate => dateTime()();
  IntColumn get linkedSaleId => integer().nullable().references(Sales, #id)();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get createdBy => text().withDefault(const Constant('admin'))();
}

@DataClassName('SupplierPaymentEntry')
class SupplierPayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get supplierId => integer().references(Suppliers, #id)();
  IntColumn get amount => integer()(); // بالقرش
  DateTimeColumn get paymentDate => dateTime()();
  IntColumn get linkedPurchaseId => integer().nullable().references(Purchases, #id)();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get createdBy => text().withDefault(const Constant('admin'))();
}

@DataClassName('CashboxTransactionEntry')
class CashboxTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get transactionType => text()(); // sale_cash_in, customer_payment_in, purchase_cash_out, supplier_payment_out, expense_out, opening_balance, reversal
  IntColumn get amount => integer()(); // بالقرش دائمًا موجب
  TextColumn get direction => text()(); // in, out
  IntColumn get balanceAfter => integer()(); // بالقرش
  TextColumn get referenceType => text().nullable()();
  IntColumn get referenceId => integer().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get createdBy => text().withDefault(const Constant('admin'))();
}

@DataClassName('ExpenseEntry')
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get category => text()(); // إيجار، كهرباء، مرتبات، بوفيه، إلخ
  IntColumn get amount => integer()(); // بالقرش
  DateTimeColumn get expenseDate => dateTime()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get createdBy => text().withDefault(const Constant('admin'))();
}
