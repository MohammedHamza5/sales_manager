import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/money/money.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/expense.dart';
import '../../domain/usecases/record_expense_usecase.dart';
import '../../domain/usecases/watch_expenses_usecase.dart';
import 'expenses_state.dart';

class ExpensesCubit extends Cubit<ExpensesState> {
  final WatchExpensesUseCase _watchExpenses;
  final RecordExpenseUseCase _recordExpense;

  StreamSubscription<List<Expense>>? _expensesSub;

  ExpensesCubit({
    required WatchExpensesUseCase watchExpenses,
    required RecordExpenseUseCase recordExpense,
  })  : _watchExpenses = watchExpenses,
        _recordExpense = recordExpense,
        super(const ExpensesInitial());

  void init() {
    emit(const ExpensesLoading());

    _expensesSub?.cancel();
    _expensesSub = _watchExpenses().listen(
      (expenses) {
        final currentState = state;
        if (currentState is ExpensesLoaded) {
          emit(currentState.copyWith(expenses: expenses));
        } else {
          emit(ExpensesLoaded(expenses: expenses));
        }
      },
      onError: (Object error) {
        emit(ExpensesError(message: 'حدث خطأ أثناء تحميل المصروفات: $error'));
      },
    );
  }

  void setCategoryFilter(String? category) {
    final currentState = state;
    if (currentState is ExpensesLoaded) {
      emit(currentState.copyWith(categoryFilter: () => category));
    }
  }

  void setDateRange(DateTime? from, DateTime? to) {
    final currentState = state;
    if (currentState is ExpensesLoaded) {
      emit(currentState.copyWith(
        fromDate: () => from,
        toDate: () => to,
      ));
    }
  }

  void setSearchQuery(String query) {
    final currentState = state;
    if (currentState is ExpensesLoaded) {
      emit(currentState.copyWith(searchQuery: query));
    }
  }

  void resetFilters() {
    final currentState = state;
    if (currentState is ExpensesLoaded) {
      emit(currentState.copyWith(
        categoryFilter: () => null,
        fromDate: () => null,
        toDate: () => null,
        searchQuery: '',
      ));
    }
  }

  Future<Result<Expense>> recordExpense({
    required String category,
    required Money amount,
    required DateTime expenseDate,
    String? note,
    String createdBy = 'admin',
  }) {
    return _recordExpense(
      category: category,
      amount: amount,
      expenseDate: expenseDate,
      note: note,
      createdBy: createdBy,
    );
  }

  @override
  Future<void> close() {
    _expensesSub?.cancel();
    return super.close();
  }
}
