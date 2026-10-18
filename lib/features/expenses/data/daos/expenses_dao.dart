import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/payments_cashbox_tables.dart';

part 'expenses_dao.g.dart';

@DriftAccessor(tables: [Expenses])
class ExpensesDao extends DatabaseAccessor<AppDatabase> with _$ExpensesDaoMixin {
  ExpensesDao(super.db);

  /// Inserts a new expense row.
  Future<int> insertExpense(ExpensesCompanion companion) {
    return into(expenses).insert(companion);
  }

  SimpleSelectStatement<Expenses, ExpenseEntry> _buildExpensesQuery({
    DateTime? from,
    DateTime? to,
    String? category,
  }) {
    final query = select(expenses);
    query.where((t) {
      Expression<bool> predicate = const Constant(true);
      if (category != null && category.isNotEmpty) {
        predicate = predicate & t.category.equals(category);
      }
      if (from != null) {
        predicate = predicate & t.expenseDate.isBiggerOrEqualValue(from);
      }
      if (to != null) {
        predicate = predicate & t.expenseDate.isSmallerOrEqualValue(to);
      }
      return predicate;
    });
    query.orderBy([(t) => OrderingTerm.desc(t.expenseDate), (t) => OrderingTerm.desc(t.id)]);
    return query;
  }

  /// Fetches expenses matching criteria.
  Future<List<ExpenseEntry>> getExpenses({
    DateTime? from,
    DateTime? to,
    String? category,
  }) {
    return _buildExpensesQuery(from: from, to: to, category: category).get();
  }

  /// Watches expenses matching criteria.
  Stream<List<ExpenseEntry>> watchExpenses({
    DateTime? from,
    DateTime? to,
    String? category,
  }) {
    return _buildExpensesQuery(from: from, to: to, category: category).watch();
  }
}
