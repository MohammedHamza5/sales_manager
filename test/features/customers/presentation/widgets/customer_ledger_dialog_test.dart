import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/di/injector.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/widgets/states/empty_view.dart';
import 'package:sales_manager/features/customers/domain/entities/customer.dart';
import 'package:sales_manager/features/customers/domain/entities/customer_ledger_entry.dart';
import 'package:sales_manager/features/customers/domain/usecases/watch_customer_ledger_usecase.dart';
import 'package:sales_manager/features/customers/presentation/widgets/customer_ledger_dialog.dart';

class MockWatchCustomerLedgerUseCase extends Mock
    implements WatchCustomerLedgerUseCase {}

void main() {
  late MockWatchCustomerLedgerUseCase mockWatch;

  final sampleCustomer = Customer(
    id: 10,
    name: 'عميل الحسابات',
    phone: '01012345678',
    address: 'القاهرة',
    notes: 'ملاحظة',
    currentBalance: const Money.fromPiastres(20000), // 200.00 EGP debt
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
    createdBy: 'admin',
  );

  final sampleEntries = [
    CustomerLedgerEntry(
      id: 1,
      customerId: 10,
      entryType: CustomerLedgerEntryType.openingBalance,
      amount: const Money.fromPiastres(10000), // 100.00
      effect: LedgerEffect.increase,
      balanceAfter: const Money.fromPiastres(10000),
      referenceType: 'opening_balance',
      referenceId: null,
      note: 'رصيد افتتاحي سابق',
      createdAt: DateTime(2026, 1, 1, 10, 30),
      createdBy: 'admin',
    ),
    CustomerLedgerEntry(
      id: 2,
      customerId: 10,
      entryType: CustomerLedgerEntryType.payment,
      amount: const Money.fromPiastres(4000), // 40.00
      effect: LedgerEffect.decrease,
      balanceAfter: const Money.fromPiastres(6000),
      referenceType: 'receipt',
      referenceId: 88,
      note: 'دفعة نقدية',
      createdAt: DateTime(2026, 1, 2, 14, 0),
      createdBy: 'admin',
    ),
  ];

  setUp(() async {
    await getIt.reset();
    mockWatch = MockWatchCustomerLedgerUseCase();
    getIt.registerSingleton<WatchCustomerLedgerUseCase>(mockWatch);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => CustomerLedgerDialog.show(context, sampleCustomer),
              child: const Text('Open Ledger'),
            ),
          ),
        ),
      ),
    );
  }

  group('CustomerLedgerDialog Widget Tests', () {
    testWidgets('Renders empty view when customer has no ledger entries',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      when(() => mockWatch(10)).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Ledger'));
      await tester.pumpAndSettle();

      expect(find.text('عميل الحسابات'), findsOneWidget);
      expect(find.byType(EmptyView), findsOneWidget);
      expect(
        find.text('لا توجد حركات مسجلة بكشف حساب العميل حتى الآن'),
        findsOneWidget,
      );
    });

    testWidgets('Renders summary metrics and data table with debit/credit entries',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      when(() => mockWatch(10)).thenAnswer((_) => Stream.value(sampleEntries));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Ledger'));
      await tester.pumpAndSettle();

      // Header
      expect(find.text('عميل الحسابات'), findsOneWidget);
      expect(find.text('01012345678'), findsOneWidget);

      // KPI Metric Cards
      expect(find.text('إجمالي المسحوبات والديون (مدين +)'), findsOneWidget);
      expect(find.text('إجمالي المدفوعات والسداد (دائن -)'), findsOneWidget);
      expect(find.text('صافي الرصيد الحالي'), findsOneWidget);

      // DataTable Columns
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('التاريخ والوقت'), findsOneWidget);
      expect(find.text('نوع الحركة'), findsOneWidget);
      expect(find.text('مدين (يزيد الدين)'), findsOneWidget);
      expect(find.text('دائن (سداد)'), findsOneWidget);
      expect(find.text('الرصيد بعدها'), findsOneWidget);

      // Badges and content
      expect(find.text('رصيد افتتاحي'), findsNWidgets(2)); // chip and badge
      expect(find.text('سند تحصيل نقدية'), findsNWidgets(2)); // chip and badge
      expect(find.text('رصيد افتتاحي سابق'), findsOneWidget);
      expect(find.text('دفعة نقدية'), findsOneWidget);
    });

    testWidgets('Filter chip filters table rows', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      when(() => mockWatch(10)).thenAnswer((_) => Stream.value(sampleEntries));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Ledger'));
      await tester.pumpAndSettle();

      // Click on 'سند تحصيل نقدية' chip
      final paymentChip = find.byKey(const ValueKey('chip_payment'));
      await tester.tap(paymentChip);
      await tester.pumpAndSettle();

      // Now only payment row should be present
      expect(find.text('دفعة نقدية'), findsOneWidget);
      expect(find.text('رصيد افتتاحي سابق'), findsNothing);
    });
  });
}
