import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/features/cashbox/domain/entities/cashbox_summary.dart';
import 'package:sales_manager/features/cashbox/domain/entities/cashbox_transaction_entity.dart';
import 'package:sales_manager/features/cashbox/domain/usecases/watch_cashbox_balance_usecase.dart';
import 'package:sales_manager/features/cashbox/domain/usecases/watch_cashbox_summary_usecase.dart';
import 'package:sales_manager/features/cashbox/domain/usecases/watch_cashbox_transactions_usecase.dart';
import 'package:sales_manager/features/cashbox/presentation/cubit/cashbox_cubit.dart';
import 'package:sales_manager/features/cashbox/presentation/cubit/cashbox_state.dart';

class MockWatchCashboxTransactionsUseCase extends Mock
    implements WatchCashboxTransactionsUseCase {}

class MockWatchCashboxBalanceUseCase extends Mock
    implements WatchCashboxBalanceUseCase {}

class MockWatchCashboxSummaryUseCase extends Mock
    implements WatchCashboxSummaryUseCase {}

void main() {
  late MockWatchCashboxTransactionsUseCase mockWatchTransactions;
  late MockWatchCashboxBalanceUseCase mockWatchBalance;
  late MockWatchCashboxSummaryUseCase mockWatchSummary;
  late CashboxCubit cubit;

  late StreamController<List<CashboxTransactionEntity>> transactionsController;
  late StreamController<Money> balanceController;
  late StreamController<CashboxSummary> summaryController;

  final sampleDate = DateTime(2026, 3, 10, 12, 0);
  final sampleTransactions = [
    CashboxTransactionEntity(
      id: 1,
      transactionType: 'opening_balance',
      amount: Money.fromPounds(1000),
      direction: 'in',
      balanceAfter: Money.fromPounds(1000),
      note: 'رصيد افتتاحي',
      createdAt: sampleDate,
    ),
    CashboxTransactionEntity(
      id: 2,
      transactionType: 'expense_out',
      amount: Money.fromPounds(200),
      direction: 'out',
      balanceAfter: Money.fromPounds(800),
      note: 'إيجار - مصروف شهري',
      createdAt: sampleDate.add(const Duration(hours: 1)),
    ),
    CashboxTransactionEntity(
      id: 3,
      transactionType: 'sale_cash_in',
      amount: Money.fromPounds(500),
      direction: 'in',
      balanceAfter: Money.fromPounds(1300),
      note: 'فاتورة مبيعات #10',
      createdAt: sampleDate.add(const Duration(hours: 2)),
    ),
  ];

  final sampleSummary = CashboxSummary(
    totalIn: Money.fromPounds(1500),
    totalOut: Money.fromPounds(200),
    netAmount: Money.fromPounds(1300),
    currentBalance: Money.fromPounds(1300),
    transactionCount: 3,
  );

  setUp(() {
    mockWatchTransactions = MockWatchCashboxTransactionsUseCase();
    mockWatchBalance = MockWatchCashboxBalanceUseCase();
    mockWatchSummary = MockWatchCashboxSummaryUseCase();

    transactionsController = StreamController<List<CashboxTransactionEntity>>.broadcast();
    balanceController = StreamController<Money>.broadcast();
    summaryController = StreamController<CashboxSummary>.broadcast();

    when(() => mockWatchTransactions()).thenAnswer((_) => transactionsController.stream);
    when(() => mockWatchBalance()).thenAnswer((_) => balanceController.stream);
    when(() => mockWatchSummary(any())).thenAnswer((_) => summaryController.stream);

    cubit = CashboxCubit(
      watchTransactions: mockWatchTransactions,
      watchBalance: mockWatchBalance,
      watchSummary: mockWatchSummary,
    );
  });

  tearDown(() {
    cubit.close();
    transactionsController.close();
    balanceController.close();
    summaryController.close();
  });

  test('initial state is CashboxInitial', () {
    expect(cubit.state, equals(const CashboxInitial()));
  });

  blocTest<CashboxCubit, CashboxState>(
    'emits [CashboxLoading, CashboxLoaded] when initialized and streams emit data',
    build: () => cubit,
    act: (cubit) {
      cubit.init();
      balanceController.add(Money.fromPounds(1300));
      summaryController.add(sampleSummary);
      transactionsController.add(sampleTransactions);
    },
    expect: () => [
      const CashboxLoading(),
      isA<CashboxLoaded>()
          .having((s) => s.currentBalance, 'balance', Money.fromPounds(1300)),
      isA<CashboxLoaded>()
          .having((s) => s.currentBalance, 'balance', Money.fromPounds(1300))
          .having((s) => s.dailySummary, 'summary', sampleSummary),
      isA<CashboxLoaded>()
          .having((s) => s.currentBalance, 'balance', Money.fromPounds(1300))
          .having((s) => s.dailySummary, 'summary', sampleSummary)
          .having((s) => s.transactions.length, 'tx count', 3),
    ],
  );

  blocTest<CashboxCubit, CashboxState>(
    'filters transactions correctly by direction and type',
    build: () => cubit,
    seed: () => CashboxLoaded(
      transactions: sampleTransactions,
      currentBalance: Money.fromPounds(1300),
      dailySummary: sampleSummary,
    ),
    act: (cubit) {
      cubit.setDirectionFilter('out');
    },
    expect: () => [
      isA<CashboxLoaded>()
          .having((s) => s.directionFilter, 'directionFilter', 'out')
          .having((s) => s.filteredTransactions.length, 'filtered length', 1)
          .having((s) => s.filteredTransactions.first.transactionType, 'type', 'expense_out'),
    ],
  );

  blocTest<CashboxCubit, CashboxState>(
    'filters transactions by search query',
    build: () => cubit,
    seed: () => CashboxLoaded(
      transactions: sampleTransactions,
      currentBalance: Money.fromPounds(1300),
      dailySummary: sampleSummary,
    ),
    act: (cubit) {
      cubit.setSearchQuery('إيجار');
    },
    expect: () => [
      isA<CashboxLoaded>()
          .having((s) => s.searchQuery, 'query', 'إيجار')
          .having((s) => s.filteredTransactions.length, 'filtered length', 1),
    ],
  );

  blocTest<CashboxCubit, CashboxState>(
    'resets all filters properly',
    build: () => cubit,
    seed: () => CashboxLoaded(
      transactions: sampleTransactions,
      currentBalance: Money.fromPounds(1300),
      dailySummary: sampleSummary,
      directionFilter: 'in',
      searchQuery: 'مبيعات',
    ),
    act: (cubit) {
      cubit.resetFilters();
    },
    expect: () => [
      isA<CashboxLoaded>()
          .having((s) => s.directionFilter, 'directionFilter', isNull)
          .having((s) => s.searchQuery, 'searchQuery', '')
          .having((s) => s.filteredTransactions.length, 'length', 3),
    ],
  );
}
