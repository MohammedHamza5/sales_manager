import '../../../../core/money/money.dart';
import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class RecordExpenseUseCase {
  final ExpenseRepository _repository;

  const RecordExpenseUseCase(this._repository);

  Future<Result<Expense>> call({
    required String category,
    required Money amount,
    required DateTime expenseDate,
    String? note,
    String createdBy = 'admin',
  }) async {
    final cleanCategory = category.trim();
    if (cleanCategory.isEmpty) {
      return const FailureResult(
        ValidationFailure(field: 'category', message: 'يرجى اختيار أو تحديد بند المصروف'),
      );
    }

    if (amount.piastres <= 0) {
      return const FailureResult(
        ValidationFailure(field: 'amount', message: 'مبلغ المصروف يجب أن يكون أكبر من الصفر'),
      );
    }

    return _repository.recordExpense(
      category: cleanCategory,
      amount: amount,
      expenseDate: expenseDate,
      note: note?.trim(),
      createdBy: createdBy,
    );
  }
}
