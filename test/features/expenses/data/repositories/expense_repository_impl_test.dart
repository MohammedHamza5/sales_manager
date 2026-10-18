import 'package:flutter_test/flutter_test.dart';
import 'package:sales_manager/core/database/app_database.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/features/expenses/data/daos/expenses_dao.dart';
import 'package:sales_manager/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:sales_manager/features/expenses/domain/repositories/expense_repository.dart';

void main() {
  late AppDatabase db;
  late ExpensesDao dao;
  late ExpenseRepository repository;

  setUp(() {
    db = AppDatabase.memory();
    dao = ExpensesDao(db);
    repository = ExpenseRepositoryImpl(db: db, dao: dao);
  });

  tearDown(() async {
    await db.close();
  });

  group('ExpenseRepositoryImpl Integration Tests', () {
    test('Fails when category is empty', () async {
      final result = await repository.recordExpense(
        category: '   ',
        amount: const Money.fromPiastres(5000),
        expenseDate: DateTime.now(),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, contains('تحديد بند المصروف'));
    });

    test('Fails when amount is zero or negative', () async {
      final result = await repository.recordExpense(
        category: 'كهرباء',
        amount: Money.zero,
        expenseDate: DateTime.now(),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, contains('أكبر من صفر'));
    });

    test('recordExpense commits atomically across expenses, cashbox_transactions, and audit_log', () async {
      // 1. Initial cashbox balance = 1000.00 EGP
      await db.into(db.cashboxTransactions).insert(
            CashboxTransactionsCompanion.insert(
              transactionType: 'opening_balance',
              amount: 100000,
              direction: 'in',
              balanceAfter: 100000,
            ),
          );

      // 2. Record expense: 200.00 EGP for 'إيجار المحل'
      final expenseDate = DateTime(2026, 3, 10, 11, 0);
      final result = await repository.recordExpense(
        category: 'إيجار المحل',
        amount: const Money.fromPiastres(20000),
        expenseDate: expenseDate,
        note: 'دفعة إيجار شهر مارس',
        createdBy: 'admin_test',
      );

      expect(result.isSuccess, isTrue);
      final expense = result.dataOrNull!;
      expect(expense.category, 'إيجار المحل');
      expect(expense.amount, const Money.fromPiastres(20000));
      expect(expense.note, 'دفعة إيجار شهر مارس');

      // 3. Verify expenses table
      final allExpenses = await db.select(db.expenses).get();
      expect(allExpenses.length, 1);
      expect(allExpenses.first.category, 'إيجار المحل');
      expect(allExpenses.first.amount, 20000);

      // 4. Verify cashbox_transactions: 1000 - 200 = 800.00 EGP (80000 piastres)
      final cashTxs = await db.select(db.cashboxTransactions).get();
      expect(cashTxs.length, 2);
      final expenseTx = cashTxs.last;
      expect(expenseTx.transactionType, 'expense_out');
      expect(expenseTx.direction, 'out');
      expect(expenseTx.amount, 20000);
      expect(expenseTx.balanceAfter, 80000);
      expect(expenseTx.referenceType, 'expense');
      expect(expenseTx.referenceId, expense.id);

      // 5. Verify audit_log
      final auditEntries = await db.select(db.auditLog).get();
      expect(auditEntries.length, 1);
      final audit = auditEntries.first;
      expect(audit.entityType, 'expense');
      expect(audit.entityId, expense.id);
      expect(audit.action, 'create');
      expect(audit.userId, 'admin_test');
    });

    test('getExpenses filters by category and date range', () async {
      await repository.recordExpense(
        category: 'بوفيه وضيافة',
        amount: const Money.fromPiastres(5000),
        expenseDate: DateTime(2026, 3, 1),
      );

      await repository.recordExpense(
        category: 'كهرباء',
        amount: const Money.fromPiastres(12000),
        expenseDate: DateTime(2026, 3, 5),
      );

      await repository.recordExpense(
        category: 'بوفيه وضيافة',
        amount: const Money.fromPiastres(3000),
        expenseDate: DateTime(2026, 3, 10),
      );

      // Filter by category
      final buffetOnly = (await repository.getExpenses(category: 'بوفيه وضيافة')).dataOrNull!;
      expect(buffetOnly.length, 2);

      // Filter by date range
      final rangeFiltered = (await repository.getExpenses(
        from: DateTime(2026, 3, 4),
        to: DateTime(2026, 3, 6),
      )).dataOrNull!;
      expect(rangeFiltered.length, 1);
      expect(rangeFiltered.first.category, 'كهرباء');
    });
  });
}
