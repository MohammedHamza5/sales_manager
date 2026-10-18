import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_manager/core/database/app_database.dart';
import 'package:sales_manager/features/dashboard/data/repositories/dashboard_repository_impl.dart';

void main() {
  late AppDatabase db;
  late DashboardRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.memory();
    repository = DashboardRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('DashboardRepositoryImpl Integration Tests', () {
    test('getDashboardData computes foundation stats correctly', () async {
      final now = DateTime.now();

      // 1. Customer with positive balance (debt)
      final customerId = await db.into(db.customers).insert(
            CustomersCompanion.insert(
              name: 'عميل آجل',
              currentBalance: const Value(15000), // 150 EGP
            ),
          );

      // 2. Supplier with balance
      await db.into(db.suppliers).insert(
            SuppliersCompanion.insert(
              name: 'مورد دائن',
              currentBalance: const Value(25000), // 250 EGP
            ),
          );

      // 3. Products: 1 normal, 1 low stock
      await db.into(db.products).insert(
            ProductsCompanion.insert(
              name: 'منتج طبيعي',
              unit: 'قطعة',
              currentPurchasePrice: 5000,
              currentSalePrice: 7000,
              currentQuantity: Value(Decimal.fromInt(50)),
              lowStockThreshold: Value(Decimal.fromInt(10)),
            ),
          );

      await db.into(db.products).insert(
            ProductsCompanion.insert(
              name: 'منتج ناقص',
              unit: 'علبة',
              currentPurchasePrice: 1000,
              currentSalePrice: 1500,
              currentQuantity: Value(Decimal.fromInt(3)),
              lowStockThreshold: Value(Decimal.fromInt(10)), // low stock!
            ),
          );

      // 4. Today's sale
      await db.into(db.sales).insert(
            SalesCompanion.insert(
              invoiceNo: 501,
              customerId: customerId,
              saleDate: now,
              totalAmount: 40000,
              paidAmountAtCreation: 20000,
              status: const Value('confirmed'),
              createdAt: Value(now),
            ),
          );

      // 5. Cashbox transaction
      await db.into(db.cashboxTransactions).insert(
            CashboxTransactionsCompanion.insert(
              transactionType: 'sale_cash_in',
              amount: 20000,
              direction: 'in',
              balanceAfter: 20000,
              note: const Value('مبيعات نقدية'),
              createdAt: Value(now),
            ),
          );

      // 6. Expense
      await db.into(db.expenses).insert(
            ExpensesCompanion.insert(
              category: 'نثريات',
              amount: 5000,
              expenseDate: now,
              createdAt: Value(now),
            ),
          );

      final data = await repository.getDashboardData();

      expect(data.cashboxBalance.piastres, equals(20000));
      expect(data.totalCustomerDebt.piastres, equals(15000));
      expect(data.totalSupplierPayables.piastres, equals(25000));
      expect(data.dailyStats.todaySales.piastres, equals(40000));
      expect(data.dailyStats.todaySalesCount, equals(1));
      expect(data.dailyStats.todayExpenses.piastres, equals(5000));
      expect(data.lowStockProducts.length, equals(1));
      expect(data.lowStockProducts.first.name, equals('منتج ناقص'));
      expect(data.recentActivities.length, equals(1));
      expect(data.recentActivities.first.type, equals('sale'));
    });

    test('watchCashboxBalance streams balance changes', () async {
      final balanceStream = repository.watchCashboxBalance();

      final expectation = expectLater(
        balanceStream,
        emitsInOrder([
          predicate((money) => (money as dynamic).piastres == 0),
          predicate((money) => (money as dynamic).piastres == 30000),
        ]),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      await db.into(db.cashboxTransactions).insert(
            CashboxTransactionsCompanion.insert(
              transactionType: 'opening_balance',
              amount: 30000,
              direction: 'in',
              balanceAfter: 30000,
            ),
          );

      await expectation;
    });
  });
}
