import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/result/result.dart';
import 'package:sales_manager/features/expenses/domain/entities/expense.dart';
import 'package:sales_manager/features/expenses/domain/usecases/record_expense_usecase.dart';
import 'package:sales_manager/features/expenses/domain/usecases/watch_expenses_usecase.dart';
import 'package:sales_manager/features/expenses/presentation/cubit/expenses_cubit.dart';
import 'package:sales_manager/features/expenses/presentation/cubit/expenses_state.dart';

class MockWatchExpensesUseCase extends Mock implements WatchExpensesUseCase {}

class MockRecordExpenseUseCase extends Mock implements RecordExpenseUseCase {}

void main() {
  late MockWatchExpensesUseCase mockWatchExpenses;
  late MockRecordExpenseUseCase mockRecordExpense;
  late ExpensesCubit cubit;

  late StreamController<List<Expense>> expensesController;

  final now = DateTime.now();
  final sampleExpenses = [
    Expense(
      id: 1,
      category: 'إيجار',
      amount: Money.fromPounds(1500),
      expenseDate: now,
      note: 'إيجار المحل',
      createdAt: now,
    ),
    Expense(
      id: 2,
      category: 'كهرباء ومياه',
      amount: Money.fromPounds(350),
      expenseDate: now,
      note: 'فاتورة الكهرباء',
      createdAt: now,
    ),
    Expense(
      id: 3,
      category: 'بوفيه وضيافة',
      amount: Money.fromPounds(80),
      expenseDate: now.subtract(const Duration(days: 40)), // Previous month
      note: 'شاي وسكر',
      createdAt: now.subtract(const Duration(days: 40)),
    ),
  ];

  setUp(() {
    mockWatchExpenses = MockWatchExpensesUseCase();
    mockRecordExpense = MockRecordExpenseUseCase();

    expensesController = StreamController<List<Expense>>.broadcast();
    when(() => mockWatchExpenses(
          from: any(named: 'from'),
          to: any(named: 'to'),
          category: any(named: 'category'),
        )).thenAnswer((_) => expensesController.stream);

    cubit = ExpensesCubit(
      watchExpenses: mockWatchExpenses,
      recordExpense: mockRecordExpense,
    );
  });

  tearDown(() {
    cubit.close();
    expensesController.close();
  });

  test('initial state is ExpensesInitial', () {
    expect(cubit.state, equals(const ExpensesInitial()));
  });

  blocTest<ExpensesCubit, ExpensesState>(
    'emits [ExpensesLoading, ExpensesLoaded] when initialized and stream emits data',
    build: () => cubit,
    act: (cubit) {
      cubit.init();
      expensesController.add(sampleExpenses);
    },
    expect: () => [
      const ExpensesLoading(),
      isA<ExpensesLoaded>()
          .having((s) => s.expenses.length, 'total count', 3)
          .having((s) => s.totalFilteredAmount, 'total filtered amount', Money.fromPounds(1930))
          .having((s) => s.todayTotalAmount, 'today amount', Money.fromPounds(1850))
          .having((s) => s.thisMonthTotalAmount, 'this month amount', Money.fromPounds(1850)),
    ],
  );

  blocTest<ExpensesCubit, ExpensesState>(
    'filters expenses by category',
    build: () => cubit,
    seed: () => ExpensesLoaded(expenses: sampleExpenses),
    act: (cubit) {
      cubit.setCategoryFilter('إيجار');
    },
    expect: () => [
      isA<ExpensesLoaded>()
          .having((s) => s.categoryFilter, 'category', 'إيجار')
          .having((s) => s.filteredExpenses.length, 'filtered length', 1)
          .having((s) => s.filteredExpenses.first.category, 'first category', 'إيجار'),
    ],
  );

  blocTest<ExpensesCubit, ExpensesState>(
    'filters expenses by search query (note/category/amount)',
    build: () => cubit,
    seed: () => ExpensesLoaded(expenses: sampleExpenses),
    act: (cubit) {
      cubit.setSearchQuery('فاتورة');
    },
    expect: () => [
      isA<ExpensesLoaded>()
          .having((s) => s.searchQuery, 'query', 'فاتورة')
          .having((s) => s.filteredExpenses.length, 'filtered length', 1)
          .having((s) => s.filteredExpenses.first.id, 'id', 2),
    ],
  );

  test('recordExpense calls RecordExpenseUseCase and returns result', () async {
    final newExpense = Expense(
      id: 4,
      category: 'نقل وشحن',
      amount: Money.fromPounds(120),
      expenseDate: now,
      createdAt: now,
    );

    when(() => mockRecordExpense(
          category: 'نقل وشحن',
          amount: Money.fromPounds(120),
          expenseDate: now,
          note: null,
          createdBy: 'admin',
        )).thenAnswer((_) async => Success(newExpense));

    final result = await cubit.recordExpense(
      category: 'نقل وشحن',
      amount: Money.fromPounds(120),
      expenseDate: now,
    );

    expect(result.isSuccess, isTrue);
    expect(result.dataOrNull, equals(newExpense));
    verify(() => mockRecordExpense(
          category: 'نقل وشحن',
          amount: Money.fromPounds(120),
          expenseDate: now,
          note: null,
          createdBy: 'admin',
        )).called(1);
  });
}
