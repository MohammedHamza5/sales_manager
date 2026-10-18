import '../../../../core/result/result.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class GetExpensesUseCase {
  final ExpenseRepository _repository;

  const GetExpensesUseCase(this._repository);

  Future<Result<List<Expense>>> call({
    DateTime? from,
    DateTime? to,
    String? category,
  }) {
    return _repository.getExpenses(
      from: from,
      to: to,
      category: category,
    );
  }
}
