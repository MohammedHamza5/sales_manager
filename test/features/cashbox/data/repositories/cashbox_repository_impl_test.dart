import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_manager/core/database/app_database.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/features/cashbox/data/daos/cashbox_dao.dart';
import 'package:sales_manager/features/cashbox/data/repositories/cashbox_repository_impl.dart';
import 'package:sales_manager/features/cashbox/domain/repositories/cashbox_repository.dart';

void main() {
  late AppDatabase db;
  late CashboxDao dao;
  late CashboxRepository repository;

  setUp(() {
    db = AppDatabase.memory();
    dao = CashboxDao(db);
    repository = CashboxRepositoryImpl(dao);
  });

  tearDown(() async {
    await db.close();
  });

  group('CashboxRepositoryImpl Integration Tests', () {
    test('getCurrentBalance and watchCurrentBalance return zero when empty', () async {
      final balanceRes = await repository.getCurrentBalance();
      expect(balanceRes.isSuccess, isTrue);
      expect(balanceRes.dataOrNull, Money.zero);

      final balanceStream = repository.watchCurrentBalance();
      expect(balanceStream, emits(Money.zero));
    });

    test('balance tracks the latest balance_after accurately', () async {
      // 1. Insert opening balance transaction (500.00 EGP)
      await db.into(db.cashboxTransactions).insert(
            CashboxTransactionsCompanion.insert(
              transactionType: 'opening_balance',
              amount: 50000,
              direction: 'in',
              balanceAfter: 50000,
              createdAt: Value(DateTime(2026, 3, 1, 10, 0)),
            ),
          );

      var balance = (await repository.getCurrentBalance()).dataOrNull;
      expect(balance, const Money.fromPiastres(50000));

      // 2. Insert cash sale in (250.00 EGP) -> balance 750.00 EGP
      await db.into(db.cashboxTransactions).insert(
            CashboxTransactionsCompanion.insert(
              transactionType: 'sale_cash_in',
              amount: 25000,
              direction: 'in',
              balanceAfter: 75000,
              createdAt: Value(DateTime(2026, 3, 1, 12, 0)),
            ),
          );

      balance = (await repository.getCurrentBalance()).dataOrNull;
      expect(balance, const Money.fromPiastres(75000));

      // 3. Insert expense out (100.00 EGP) -> balance 650.00 EGP
      await db.into(db.cashboxTransactions).insert(
            CashboxTransactionsCompanion.insert(
              transactionType: 'expense_out',
              amount: 10000,
              direction: 'out',
              balanceAfter: 65000,
              createdAt: Value(DateTime(2026, 3, 1, 14, 0)),
            ),
          );

      balance = (await repository.getCurrentBalance()).dataOrNull;
      expect(balance, const Money.fromPiastres(65000));
    });

    test('getTransactions filters by direction and type accurately', () async {
      await db.into(db.cashboxTransactions).insert(
            CashboxTransactionsCompanion.insert(
              transactionType: 'sale_cash_in',
              amount: 30000,
              direction: 'in',
              balanceAfter: 30000,
            ),
          );

      await db.into(db.cashboxTransactions).insert(
            CashboxTransactionsCompanion.insert(
              transactionType: 'expense_out',
              amount: 5000,
              direction: 'out',
              balanceAfter: 25000,
            ),
          );

      await db.into(db.cashboxTransactions).insert(
            CashboxTransactionsCompanion.insert(
              transactionType: 'customer_payment_in',
              amount: 10000,
              direction: 'in',
              balanceAfter: 35000,
            ),
          );

      // All transactions
      final all = (await repository.getTransactions()).dataOrNull!;
      expect(all.length, 3);

      // In direction only
      final inTxs = (await repository.getTransactions(direction: 'in')).dataOrNull!;
      expect(inTxs.length, 2);
      expect(inTxs.every((t) => t.direction == 'in'), isTrue);

      // Out direction only
      final outTxs = (await repository.getTransactions(direction: 'out')).dataOrNull!;
      expect(outTxs.length, 1);
      expect(outTxs.first.transactionType, 'expense_out');

      // Filter by specific type
      final salesOnly = (await repository.getTransactions(type: 'sale_cash_in')).dataOrNull!;
      expect(salesOnly.length, 1);
      expect(salesOnly.first.amount, const Money.fromPiastres(30000));
    });

    test('getDailySummary computes totalIn, totalOut, netAmount, and transactionCount correctly', () async {
      final targetDate = DateTime(2026, 3, 15);

      // 1. Transaction on target date (In: 400.00 EGP)
      await db.into(db.cashboxTransactions).insert(
            CashboxTransactionsCompanion.insert(
              transactionType: 'sale_cash_in',
              amount: 40000,
              direction: 'in',
              balanceAfter: 40000,
              createdAt: Value(DateTime(2026, 3, 15, 10, 30)),
            ),
          );

      // 2. Transaction on target date (Out: 150.00 EGP)
      await db.into(db.cashboxTransactions).insert(
            CashboxTransactionsCompanion.insert(
              transactionType: 'expense_out',
              amount: 15000,
              direction: 'out',
              balanceAfter: 25000,
              createdAt: Value(DateTime(2026, 3, 15, 14, 0)),
            ),
          );

      // 3. Transaction on a DIFFERENT date (should be excluded from targetDate summary)
      await db.into(db.cashboxTransactions).insert(
            CashboxTransactionsCompanion.insert(
              transactionType: 'customer_payment_in',
              amount: 90000,
              direction: 'in',
              balanceAfter: 115000,
              createdAt: Value(DateTime(2026, 3, 16, 9, 0)),
            ),
          );

      final summaryRes = await repository.getDailySummary(targetDate);
      expect(summaryRes.isSuccess, isTrue);

      final summary = summaryRes.dataOrNull!;
      expect(summary.totalIn, const Money.fromPiastres(40000));
      expect(summary.totalOut, const Money.fromPiastres(15000));
      expect(summary.netAmount, const Money.fromPiastres(25000));
      expect(summary.transactionCount, 2);
      expect(summary.currentBalance, const Money.fromPiastres(115000));
    });
  });
}
