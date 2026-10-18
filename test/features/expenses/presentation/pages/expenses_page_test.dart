import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/di/injector.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/widgets/states/empty_view.dart';
import 'package:sales_manager/features/expenses/domain/entities/expense.dart';
import 'package:sales_manager/features/expenses/domain/usecases/record_expense_usecase.dart';
import 'package:sales_manager/features/expenses/domain/usecases/watch_expenses_usecase.dart';
import 'package:sales_manager/features/expenses/presentation/pages/expenses_page.dart';
import 'package:sales_manager/features/expenses/presentation/widgets/record_expense_dialog.dart';

class MockWatchExpensesUseCase extends Mock implements WatchExpensesUseCase {}

class MockRecordExpenseUseCase extends Mock implements RecordExpenseUseCase {}

void main() {
  late MockWatchExpensesUseCase mockWatchExpenses;
  late MockRecordExpenseUseCase mockRecordExpense;

  final now = DateTime.now();
  final sampleExpenses = [
    Expense(
      id: 1,
      category: 'إيجار',
      amount: Money.fromPounds(2000),
      expenseDate: now,
      note: 'إيجار المحل للشهر الحالي',
      createdAt: now,
    ),
    Expense(
      id: 2,
      category: 'كهرباء ومياه',
      amount: Money.fromPounds(400),
      expenseDate: now,
      note: 'فاتورة الكهرباء',
      createdAt: now,
    ),
  ];

  setUpAll(() {
    registerFallbackValue(Money.zero);
    registerFallbackValue(DateTime.now());
  });

  setUp(() async {
    await getIt.reset();
    mockWatchExpenses = MockWatchExpensesUseCase();
    mockRecordExpense = MockRecordExpenseUseCase();

    getIt.registerSingleton<WatchExpensesUseCase>(mockWatchExpenses);
    getIt.registerSingleton<RecordExpenseUseCase>(mockRecordExpense);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: ExpensesPage(),
      ),
    );
  }

  testWidgets('ExpensesPage renders empty view when no expenses exist', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    when(() => mockWatchExpenses(
          from: any(named: 'from'),
          to: any(named: 'to'),
          category: any(named: 'category'),
        )).thenAnswer((_) => Stream.value([]));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('دفتر المصروفات والنثريات'), findsOneWidget);
    expect(find.byType(EmptyView), findsOneWidget);
    expect(find.text('لا توجد مصروفات مسجلة'), findsOneWidget);
    expect(find.text('تسجيل مصروف جديد'), findsOneWidget);
  });

  testWidgets('ExpensesPage renders KPI cards and DataTable when expenses exist', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    when(() => mockWatchExpenses(
          from: any(named: 'from'),
          to: any(named: 'to'),
          category: any(named: 'category'),
        )).thenAnswer((_) => Stream.value(sampleExpenses));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('دفتر المصروفات والنثريات'), findsOneWidget);
    expect(find.text('إجمالي المصروفات المعروضة'), findsOneWidget);
    expect(find.text('مصروفات اليوم'), findsOneWidget);
    expect(find.text('إيجار المحل للشهر الحالي'), findsOneWidget);
    expect(find.text('فاتورة الكهرباء'), findsOneWidget);
    expect(find.byType(DataTable), findsOneWidget);
  });

  testWidgets('Clicking new expense button opens RecordExpenseDialog', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    when(() => mockWatchExpenses(
          from: any(named: 'from'),
          to: any(named: 'to'),
          category: any(named: 'category'),
        )).thenAnswer((_) => Stream.value(sampleExpenses));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final button = find.text('تسجيل مصروف جديد');
    expect(button, findsOneWidget);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.byType(RecordExpenseDialog), findsOneWidget);
    expect(find.text('تسجيل مصروف نقدي'), findsOneWidget);
  });
}
