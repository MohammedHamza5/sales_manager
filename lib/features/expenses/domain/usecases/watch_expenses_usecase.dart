import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class WatchExpensesUseCase {
  final ExpenseRepository _repository;

  const WatchExpensesUseCase(this._repository);

  Stream<List<Expense>> call({
    DateTime? from,
    DateTime? to,
    String? category,
  }) {
    return _repository.watchExpenses(
      from: from,
      to: to,
      category: category,
    );
  }
}
