import '../../../../core/money/money.dart';
import '../../../../core/result/result.dart';
import '../entities/expense.dart';

abstract interface class ExpenseRepository {
  /// Records a new expense atomically in both expenses and cashbox_transactions.
  Future<Result<Expense>> recordExpense({
    required String category,
    required Money amount,
    required DateTime expenseDate,
    String? note,
    String createdBy = 'admin',
  });

  /// Fetches expenses matching optional criteria.
  Future<Result<List<Expense>>> getExpenses({
    DateTime? from,
    DateTime? to,
    String? category,
  });

  /// Watches expenses reactively.
  Stream<List<Expense>> watchExpenses({
    DateTime? from,
    DateTime? to,
    String? category,
  });
}
