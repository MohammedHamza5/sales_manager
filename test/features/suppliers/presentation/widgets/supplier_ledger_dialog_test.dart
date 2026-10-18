import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/di/injector.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/widgets/states/empty_view.dart';
import 'package:sales_manager/features/suppliers/domain/entities/supplier.dart';
import 'package:sales_manager/features/suppliers/domain/entities/supplier_ledger_entry.dart';
import 'package:sales_manager/features/suppliers/domain/usecases/watch_supplier_ledger_usecase.dart';
import 'package:sales_manager/features/suppliers/presentation/widgets/supplier_ledger_dialog.dart';

class MockWatchSupplierLedgerUseCase extends Mock
    implements WatchSupplierLedgerUseCase {}

void main() {
  late MockWatchSupplierLedgerUseCase mockWatch;

  final sampleSupplier = Supplier(
    id: 10,
    name: 'مورد البضائع',
    phone: '01012345678',
    address: 'العاشر من رمضان',
    notes: 'ملاحظة',
    currentBalance: const Money.fromPiastres(200000), // 2000.00 EGP due to them
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
    createdBy: 'admin',
  );

  final sampleEntries = [
    SupplierLedgerEntry(
      id: 1,
      supplierId: 10,
      entryType: SupplierLedgerEntryType.openingBalance,
      amount: const Money.fromPiastres(100000), // 1000.00
      effect: SupplierLedgerEffect.increase,
      balanceAfter: const Money.fromPiastres(100000),
      referenceType: 'opening_balance',
      referenceId: null,
      note: 'رصيد افتتاحي سابق',
      createdAt: DateTime(2026, 1, 1, 10, 30),
      createdBy: 'admin',
    ),
    SupplierLedgerEntry(
      id: 2,
      supplierId: 10,
      entryType: SupplierLedgerEntryType.payment,
      amount: const Money.fromPiastres(40000), // 400.00
      effect: SupplierLedgerEffect.decrease,
      balanceAfter: const Money.fromPiastres(60000),
      referenceType: 'payment_voucher',
      referenceId: 88,
      note: 'دفعة نقدية مسددة',
      createdAt: DateTime(2026, 1, 2, 14, 0),
      createdBy: 'admin',
    ),
  ];

  setUp(() async {
    await getIt.reset();
    mockWatch = MockWatchSupplierLedgerUseCase();
    getIt.registerSingleton<WatchSupplierLedgerUseCase>(mockWatch);
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
              onPressed: () => SupplierLedgerDialog.show(context, sampleSupplier),
              child: const Text('Open Ledger'),
            ),
          ),
        ),
      ),
    );
  }

  group('SupplierLedgerDialog Widget Tests', () {
    testWidgets('Renders empty view when supplier has no ledger entries',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      when(() => mockWatch(10)).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Ledger'));
      await tester.pumpAndSettle();

      expect(find.text('مورد البضائع'), findsOneWidget);
      expect(find.byType(EmptyView), findsOneWidget);
      expect(
        find.text('لا توجد حركات مسجلة بكشف حساب المورد حتى الآن'),
        findsOneWidget,
      );
    });

    testWidgets('Renders summary metrics and data table with credit/debit entries',
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
      expect(find.text('مورد البضائع'), findsOneWidget);
      expect(find.text('01012345678'), findsOneWidget);

      // KPI Metric Cards
      expect(find.text('إجمالي المشتريات والمستحقات (دائن +)'), findsOneWidget);
      expect(find.text('إجمالي المدفوعات والسداد (مدين -)'), findsOneWidget);
      expect(find.text('صافي الرصيد المستحق'), findsOneWidget);

      // DataTable Columns
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('التاريخ والوقت'), findsOneWidget);
      expect(find.text('نوع الحركة'), findsOneWidget);
      expect(find.text('مستحق له (دائن +)'), findsOneWidget);
      expect(find.text('مدفوع له (مدين -)'), findsOneWidget);
      expect(find.text('الرصيد بعدها'), findsOneWidget);

      // Badges and content
      expect(find.text('رصيد افتتاحي'), findsNWidgets(2)); // chip and badge
      expect(find.text('سند صرف نقدية'), findsNWidgets(2)); // chip and badge
      expect(find.text('رصيد افتتاحي سابق'), findsOneWidget);
      expect(find.text('دفعة نقدية مسددة'), findsOneWidget);
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

      // Click on 'سند صرف نقدية' chip
      final paymentChip = find.byKey(const ValueKey('chip_payment'));
      await tester.tap(paymentChip);
      await tester.pumpAndSettle();

      // Now only payment row should be present
      expect(find.text('دفعة نقدية مسددة'), findsOneWidget);
      expect(find.text('رصيد افتتاحي سابق'), findsNothing);
    });
  });
}
