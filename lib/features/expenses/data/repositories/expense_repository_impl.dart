import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/money/money.dart';
import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../../../../core/sync/sync_dispatcher.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../daos/expenses_dao.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final AppDatabase _db;
  final ExpensesDao _dao;
  final SyncDispatcher? _syncDispatcher;

  ExpenseRepositoryImpl({
    required AppDatabase db,
    required ExpensesDao dao,
    SyncDispatcher? syncDispatcher,
  })  : _db = db,
        _dao = dao,
        _syncDispatcher = syncDispatcher;

  @override
  Future<Result<Expense>> recordExpense({
    required String category,
    required Money amount,
    required DateTime expenseDate,
    String? note,
    String createdBy = 'admin',
  }) async {
    try {
      final cleanCategory = category.trim();
      if (cleanCategory.isEmpty) {
        return const FailureResult(
          ValidationFailure(field: 'category', message: 'يرجى تحديد بند المصروف'),
        );
      }

      if (amount.piastres <= 0) {
        return const FailureResult(
          ValidationFailure(field: 'amount', message: 'مبلغ المصروف يجب أن يكون أكبر من صفر'),
        );
      }

      final expense = await _db.transaction<Expense>(() async {
        // 1. Insert into expenses table
        final expenseId = await _db.into(_db.expenses).insert(
              ExpensesCompanion.insert(
                category: cleanCategory,
                amount: amount.piastres,
                expenseDate: expenseDate,
                note: Value(note),
                createdBy: Value(createdBy),
              ),
            );

        // 2. Read latest cashbox transaction to calculate balanceAfter
        final latestTx = await (_db.select(_db.cashboxTransactions)
              ..orderBy([(t) => OrderingTerm.desc(t.id)])
              ..limit(1))
            .getSingleOrNull();

        final lastBalance = latestTx?.balanceAfter ?? 0;
        final newCashboxBalance = lastBalance - amount.piastres;

        // 3. Insert into cashbox_transactions (direction: out)
        final txNote = (note != null && note.isNotEmpty)
            ? '$cleanCategory - $note'
            : cleanCategory;

        await _db.into(_db.cashboxTransactions).insert(
              CashboxTransactionsCompanion.insert(
                transactionType: 'expense_out',
                amount: amount.piastres,
                direction: 'out',
                balanceAfter: newCashboxBalance,
                referenceType: const Value('expense'),
                referenceId: Value(expenseId),
                note: Value(txNote),
                createdBy: Value(createdBy),
              ),
            );

        // 4. Record in audit_log
        await _db.into(_db.auditLog).insert(
              AuditLogCompanion.insert(
                entityType: 'expense',
                entityId: expenseId,
                action: 'create',
                userId: Value(createdBy),
                payloadAfter: Value(jsonEncode({
                  'category': cleanCategory,
                  'amount': amount.piastres,
                  'expenseDate': expenseDate.toIso8601String(),
                  'note': note,
                })),
              ),
            );

        // 5. Cloud Sync Outbox Dispatch
        if (_syncDispatcher != null) {
          await _syncDispatcher.dispatchInsert(
            entityType: 'expense',
            localId: expenseId,
            data: {
              'category': cleanCategory,
              'amount': amount.piastres,
              'expense_date': expenseDate.toIso8601String(),
              'note': note,
              'created_by': createdBy,
            },
          );
        }

        return Expense(
          id: expenseId,
          category: cleanCategory,
          amount: amount,
          expenseDate: expenseDate,
          note: note,
          createdAt: DateTime.now(),
          createdBy: createdBy,
        );
      });

      return Success(expense);
    } catch (e) {
      return FailureResult(
        DatabaseFailure(message: 'فشل تسجيل المصروف: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<List<Expense>>> getExpenses({
    DateTime? from,
    DateTime? to,
    String? category,
  }) async {
    try {
      final rows = await _dao.getExpenses(from: from, to: to, category: category);
      return Success(rows.map(_toDomain).toList());
    } catch (e) {
      return FailureResult(
        DatabaseFailure(message: 'فشل استعلام المصروفات: ${e.toString()}'),
      );
    }
  }

  @override
  Stream<List<Expense>> watchExpenses({
    DateTime? from,
    DateTime? to,
    String? category,
  }) {
    return _dao
        .watchExpenses(from: from, to: to, category: category)
        .map((rows) => rows.map(_toDomain).toList());
  }

  Expense _toDomain(ExpenseEntry row) {
    return Expense(
      id: row.id,
      category: row.category,
      amount: Money.fromPiastres(row.amount),
      expenseDate: row.expenseDate,
      note: row.note,
      createdAt: row.createdAt,
      createdBy: row.createdBy,
    );
  }
}
