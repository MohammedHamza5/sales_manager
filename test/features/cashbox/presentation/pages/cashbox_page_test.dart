import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/di/injector.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/widgets/states/empty_view.dart';
import 'package:sales_manager/features/cashbox/domain/entities/cashbox_summary.dart';
import 'package:sales_manager/features/cashbox/domain/entities/cashbox_transaction_entity.dart';
import 'package:sales_manager/features/cashbox/domain/usecases/watch_cashbox_balance_usecase.dart';
import 'package:sales_manager/features/cashbox/domain/usecases/watch_cashbox_summary_usecase.dart';
import 'package:sales_manager/features/cashbox/domain/usecases/watch_cashbox_transactions_usecase.dart';
import 'package:sales_manager/features/cashbox/presentation/pages/cashbox_page.dart';

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

  final sampleDate = DateTime(2026, 3, 10, 10, 0);
  final sampleTransactions = [
    CashboxTransactionEntity(
      id: 1,
      transactionType: 'opening_balance',
      amount: Money.fromPounds(2000),
      direction: 'in',
      balanceAfter: Money.fromPounds(2000),
      note: 'رصيد افتتاحي',
      createdAt: sampleDate,
    ),
    CashboxTransactionEntity(
      id: 2,
      transactionType: 'expense_out',
      amount: Money.fromPounds(150),
      direction: 'out',
      balanceAfter: Money.fromPounds(1850),
      note: 'بوفيه وضيافة',
      createdAt: sampleDate.add(const Duration(hours: 1)),
    ),
  ];

  final sampleSummary = CashboxSummary(
    totalIn: Money.fromPounds(2000),
    totalOut: Money.fromPounds(150),
    netAmount: Money.fromPounds(1850),
    currentBalance: Money.fromPounds(1850),
    transactionCount: 2,
  );

  setUp(() async {
    await getIt.reset();
    mockWatchTransactions = MockWatchCashboxTransactionsUseCase();
    mockWatchBalance = MockWatchCashboxBalanceUseCase();
    mockWatchSummary = MockWatchCashboxSummaryUseCase();

    getIt.registerSingleton<WatchCashboxTransactionsUseCase>(mockWatchTransactions);
    getIt.registerSingleton<WatchCashboxBalanceUseCase>(mockWatchBalance);
    getIt.registerSingleton<WatchCashboxSummaryUseCase>(mockWatchSummary);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: CashboxPage(),
      ),
    );
  }

  testWidgets('CashboxPage renders empty view when no transactions exist', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    when(() => mockWatchTransactions()).thenAnswer((_) => Stream.value([]));
    when(() => mockWatchBalance()).thenAnswer((_) => Stream.value(Money.zero));
    when(() => mockWatchSummary(any())).thenAnswer((_) => Stream.value(CashboxSummary.empty));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('دفتر حركة الخزينة النقدية'), findsOneWidget);
    expect(find.byType(EmptyView), findsOneWidget);
    expect(find.text('لا توجد حركات مسجلة بالخزينة'), findsOneWidget);
  });

  testWidgets('CashboxPage renders balance, metrics and data table when transactions exist', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    when(() => mockWatchTransactions()).thenAnswer((_) => Stream.value(sampleTransactions));
    when(() => mockWatchBalance()).thenAnswer((_) => Stream.value(Money.fromPounds(1850)));
    when(() => mockWatchSummary(any())).thenAnswer((_) => Stream.value(sampleSummary));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('دفتر حركة الخزينة النقدية'), findsOneWidget);
    expect(find.text('الرصيد الفعلي الحالي في الخزينة'), findsOneWidget);
    expect(find.text('وارد اليوم (+)'), findsOneWidget);
    expect(find.text('صادر اليوم (-)'), findsOneWidget);
    expect(find.text('بوفيه وضيافة'), findsOneWidget);
    expect(find.byType(DataTable), findsOneWidget);
  });
}
