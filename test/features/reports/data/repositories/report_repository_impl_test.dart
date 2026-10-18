import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_manager/core/database/app_database.dart';
import 'package:sales_manager/features/reports/data/repositories/report_repository_impl.dart';

void main() {
  late AppDatabase db;
  late ReportRepositoryImpl repository;

  setUp(() async {
    db = AppDatabase.memory();
    repository = ReportRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ReportRepositoryImpl Integration Tests', () {
    test('getSalesReport aggregates sales and paid amounts accurately', () async {
      final customerId = await db.into(db.customers).insert(
            CustomersCompanion.insert(
              name: 'عميل التقارير 1',
              currentBalance: const Value(0),
            ),
          );

      final now = DateTime.now();

      await db.into(db.sales).insert(
            SalesCompanion.insert(
              invoiceNo: 101,
              customerId: customerId,
              saleDate: now,
              totalAmount: 50000,
              paidAmountAtCreation: 20000,
              status: const Value('confirmed'),
              createdAt: Value(now),
            ),
          );

      await db.into(db.sales).insert(
            SalesCompanion.insert(
              invoiceNo: 102,
              customerId: customerId,
              saleDate: now,
              totalAmount: 30000,
              paidAmountAtCreation: 30000,
              status: const Value('reversed'),
              createdAt: Value(now),
            ),
          );

      final result = await repository.getSalesReport(
        from: now.subtract(const Duration(days: 1)),
        to: now.add(const Duration(days: 1)),
      );

      expect(result.isSuccess, isTrue);
      final report = result.dataOrNull!;
      expect(report.salesCount, equals(2));
      expect(report.totalSales.piastres, equals(50000));
      expect(report.totalPaid.piastres, equals(20000));
      expect(report.totalRemaining.piastres, equals(30000));
    });

    test('getCollectionsReport aggregates payments accurately', () async {
      final customerId = await db.into(db.customers).insert(
            CustomersCompanion.insert(
              name: 'عميل التحصيلات',
              currentBalance: const Value(0),
            ),
          );

      final now = DateTime.now();

      await db.into(db.customerPayments).insert(
            CustomerPaymentsCompanion.insert(
              customerId: customerId,
              amount: 15000,
              paymentDate: now,
              createdAt: Value(now),
              note: const Value('دفعة أولى'),
            ),
          );

      await db.into(db.customerPayments).insert(
            CustomerPaymentsCompanion.insert(
              customerId: customerId,
              amount: 25000,
              paymentDate: now,
              createdAt: Value(now),
              note: const Value('دفعة ثانية'),
            ),
          );

      final result = await repository.getCollectionsReport(
        from: now.subtract(const Duration(days: 1)),
        to: now.add(const Duration(days: 1)),
      );

      expect(result.isSuccess, isTrue);
      final report = result.dataOrNull!;
      expect(report.paymentsCount, equals(2));
      expect(report.totalCollected.piastres, equals(40000));
    });

    test('getCustomerReport and getAllCustomerBalances work correctly', () async {
      final customerId = await db.into(db.customers).insert(
            CustomersCompanion.insert(
              name: 'عميل كشف الحساب',
              phone: const Value('01012345678'),
              currentBalance: const Value(12000),
            ),
          );

      final now = DateTime.now();

      await db.into(db.customerLedgerEntries).insert(
            CustomerLedgerEntriesCompanion.insert(
              customerId: customerId,
              entryType: 'sale',
              amount: 20000,
              effect: 'increase',
              balanceAfter: 20000,
              createdAt: Value(now),
            ),
          );

      await db.into(db.customerLedgerEntries).insert(
            CustomerLedgerEntriesCompanion.insert(
              customerId: customerId,
              entryType: 'payment',
              amount: 8000,
              effect: 'decrease',
              balanceAfter: 12000,
              createdAt: Value(now.add(const Duration(minutes: 5))),
            ),
          );

      final balancesResult = await repository.getAllCustomerBalances();
      expect(balancesResult.isSuccess, isTrue);
      expect(balancesResult.dataOrNull!.length, equals(1));
      expect(balancesResult.dataOrNull!.first.hasDebt, isTrue);
      expect(balancesResult.dataOrNull!.first.balance.piastres, equals(12000));

      final reportResult = await repository.getCustomerReport(
        customerId: customerId,
        from: now.subtract(const Duration(days: 1)),
        to: now.add(const Duration(days: 1)),
      );

      expect(reportResult.isSuccess, isTrue);
      final report = reportResult.dataOrNull!;
      expect(report.customerName, equals('عميل كشف الحساب'));
      expect(report.totalDebit.piastres, equals(20000));
      expect(report.totalCredit.piastres, equals(8000));
      expect(report.closingBalance.piastres, equals(12000));
      expect(report.entries.length, equals(2));
    });

    test('getInventoryReport computes valuation and low stock correctly', () async {
      await db.into(db.products).insert(
            ProductsCompanion.insert(
              name: 'سكر أبيض',
              unit: 'كيلو',
              currentPurchasePrice: 2000,
              currentSalePrice: 2500,
              currentQuantity: Value(Decimal.fromInt(10)),
              lowStockThreshold: Value(Decimal.fromInt(15)),
            ),
          );

      await db.into(db.products).insert(
            ProductsCompanion.insert(
              name: 'زيت ذرة',
              unit: 'لتر',
              currentPurchasePrice: 5000,
              currentSalePrice: 6000,
              currentQuantity: Value(Decimal.fromInt(50)),
              lowStockThreshold: Value(Decimal.fromInt(10)),
            ),
          );

      final result = await repository.getInventoryReport();
      expect(result.isSuccess, isTrue);
      final report = result.dataOrNull!;
      expect(report.totalProductsCount, equals(2));
      expect(report.lowStockProductsCount, equals(1));
      expect(report.totalValuationAtCost.piastres, equals(270000));
    });

    test('getCashboxReport computes inflow, outflow and net flow correctly', () async {
      final now = DateTime.now();

      await db.into(db.cashboxTransactions).insert(
            CashboxTransactionsCompanion.insert(
              transactionType: 'sale_cash_in',
              amount: 50000,
              direction: 'in',
              balanceAfter: 50000,
              createdAt: Value(now),
            ),
          );

      await db.into(db.cashboxTransactions).insert(
            CashboxTransactionsCompanion.insert(
              transactionType: 'expense_out',
              amount: 15000,
              direction: 'out',
              balanceAfter: 35000,
              createdAt: Value(now.add(const Duration(minutes: 10))),
            ),
          );

      final result = await repository.getCashboxReport(
        from: now.subtract(const Duration(days: 1)),
        to: now.add(const Duration(days: 1)),
      );

      expect(result.isSuccess, isTrue);
      final report = result.dataOrNull!;
      expect(report.totalIn.piastres, equals(50000));
      expect(report.totalOut.piastres, equals(15000));
      expect(report.netCashflow.piastres, equals(35000));
      expect(report.closingBalance.piastres, equals(35000));
      expect(report.transactions.length, equals(2));
    });

    test('getProfitReport computes revenue, COGS and gross profit margin accurately', () async {
      final now = DateTime.now();

      final customerId = await db.into(db.customers).insert(
            CustomersCompanion.insert(
              name: 'عميل أرباح',
              currentBalance: const Value(0),
            ),
          );

      final p1 = await db.into(db.products).insert(
            ProductsCompanion.insert(
              name: 'منتج أ',
              unit: 'قطعة',
              currentPurchasePrice: 6000, // 60 EGP cost
              currentSalePrice: 10000, // 100 EGP price
              currentQuantity: Value(Decimal.fromInt(10)),
            ),
          );

      final saleId = await db.into(db.sales).insert(
            SalesCompanion.insert(
              invoiceNo: 201,
              customerId: customerId,
              saleDate: now,
              totalAmount: 20000, // 2 items = 200 EGP
              paidAmountAtCreation: 20000,
              status: const Value('confirmed'),
              createdAt: Value(now),
            ),
          );

      await db.into(db.saleItems).insert(
            SaleItemsCompanion.insert(
              saleId: saleId,
              productId: p1,
              quantity: Decimal.fromInt(2),
              unitPriceAtSale: 10000,
              lineTotal: 20000,
            ),
          );

      final result = await repository.getProfitReport(
        from: now.subtract(const Duration(days: 1)),
        to: now.add(const Duration(days: 1)),
      );

      expect(result.isSuccess, isTrue);
      final report = result.dataOrNull!;
      expect(report.totalRevenue.piastres, equals(20000));
      expect(report.totalCost.piastres, equals(12000)); // 2 * 6000
      expect(report.totalGrossProfit.piastres, equals(8000)); // 20000 - 12000
      expect(report.overallMarginPercentage, equals(40.0)); // 8000 / 20000 * 100
      expect(report.items.length, equals(1));
      expect(report.items.first.productName, equals('منتج أ'));
      expect(report.items.first.grossProfit.piastres, equals(8000));
      expect(report.items.first.marginPercentage, equals(40.0));
    });
  });
}
