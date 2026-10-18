import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/di/injector.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/widgets/states/empty_view.dart';
import 'package:sales_manager/features/customers/domain/entities/customer.dart';
import 'package:sales_manager/features/customers/domain/usecases/add_customer_usecase.dart';
import 'package:sales_manager/features/customers/domain/usecases/toggle_customer_status_usecase.dart';
import 'package:sales_manager/features/customers/domain/usecases/update_customer_usecase.dart';
import 'package:sales_manager/features/customers/domain/usecases/watch_customer_ledger_usecase.dart';
import 'package:sales_manager/features/customers/domain/usecases/watch_customers_usecase.dart';
import 'package:sales_manager/features/customers/presentation/pages/customers_page.dart';

class MockWatchCustomersUseCase extends Mock implements WatchCustomersUseCase {}

class MockAddCustomerUseCase extends Mock implements AddCustomerUseCase {}

class MockUpdateCustomerUseCase extends Mock implements UpdateCustomerUseCase {}

class MockToggleCustomerStatusUseCase extends Mock
    implements ToggleCustomerStatusUseCase {}

class MockWatchCustomerLedgerUseCase extends Mock
    implements WatchCustomerLedgerUseCase {}

void main() {
  late MockWatchCustomersUseCase mockWatch;
  late MockAddCustomerUseCase mockAdd;
  late MockUpdateCustomerUseCase mockUpdate;
  late MockToggleCustomerStatusUseCase mockToggle;
  late MockWatchCustomerLedgerUseCase mockWatchLedger;

  final sampleCustomers = [
    Customer(
      id: 1,
      name: 'محمود أحمد',
      phone: '01011111111',
      address: 'شارع التحرير، القاهرة',
      notes: 'عميل مميز',
      currentBalance: const Money.fromPiastres(15000), // 150.00 EGP debt
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
      createdBy: 'admin',
    ),
    Customer(
      id: 2,
      name: 'سارة إبراهيم',
      phone: '01022222222',
      address: 'المعادي',
      notes: null,
      currentBalance: Money.zero, // Settled
      isActive: true,
      createdAt: DateTime(2026, 1, 2),
      createdBy: 'admin',
    ),
  ];

  setUp(() async {
    await getIt.reset();
    mockWatch = MockWatchCustomersUseCase();
    mockAdd = MockAddCustomerUseCase();
    mockUpdate = MockUpdateCustomerUseCase();
    mockToggle = MockToggleCustomerStatusUseCase();
    mockWatchLedger = MockWatchCustomerLedgerUseCase();

    getIt.registerSingleton<WatchCustomersUseCase>(mockWatch);
    getIt.registerSingleton<AddCustomerUseCase>(mockAdd);
    getIt.registerSingleton<UpdateCustomerUseCase>(mockUpdate);
    getIt.registerSingleton<ToggleCustomerStatusUseCase>(mockToggle);
    getIt.registerSingleton<WatchCustomerLedgerUseCase>(mockWatchLedger);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomersPage(),
      ),
    );
  }

  group('CustomersPage Widget Tests', () {
    testWidgets('Renders empty view when there are no customers', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      when(() => mockWatch()).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('العملاء والحسابات الجارية'), findsOneWidget);
      expect(find.byType(EmptyView), findsOneWidget);
      expect(find.text('لا يوجد عملاء مسجلون بالنظام حتى الآن'), findsOneWidget);
    });

    testWidgets('Renders KPI metrics and data table when customers are loaded',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      when(() => mockWatch()).thenAnswer((_) => Stream.value(sampleCustomers));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Header
      expect(find.text('العملاء والحسابات الجارية'), findsOneWidget);

      // KPI Metric Cards
      expect(find.text('إجمالي العملاء المسجلين'), findsOneWidget);
      expect(find.text('عملاء عليهم ديون مستحقة'), findsOneWidget);
      expect(find.text('إجمالي ديون العملاء'), findsOneWidget);

      // DataTable Customer entries
      expect(find.text('محمود أحمد'), findsOneWidget);
      expect(find.text('01011111111'), findsOneWidget);
      expect(find.text('سارة إبراهيم'), findsOneWidget);
      expect(find.text('01022222222'), findsOneWidget);
      expect(find.byType(DataTable), findsOneWidget);
    });

    testWidgets('Clicking add customer button opens CustomerFormDialog',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      when(() => mockWatch()).thenAnswer((_) => Stream.value(sampleCustomers));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final addButton = find.text('تسجيل عميل جديد').first;
      expect(addButton, findsOneWidget);

      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Form dialog opened
      expect(find.widgetWithText(TextFormField, 'اسم العميل *'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'رقم الهاتف (اختياري)'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'العنوان / المنطقة (اختياري)'), findsOneWidget);
      expect(
        find.widgetWithText(
          TextFormField,
          'رصيد المديونية الافتتاحي بالجنيه (اختياري)',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Clicking edit customer opens dialog in edit mode',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      when(() => mockWatch()).thenAnswer((_) => Stream.value(sampleCustomers));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final editButton = find.byIcon(Icons.edit_outlined).first;
      await tester.ensureVisible(editButton);
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      expect(find.text('تعديل بيانات العميل'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'اسم العميل *'), findsOneWidget);
      // In edit mode, initial balance input must NOT be present
      expect(
        find.text('رصيد المديونية الافتتاحي بالجنيه (اختياري)'),
        findsNothing,
      );
    });

    testWidgets('Clicking statement icon button opens CustomerLedgerDialog',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      when(() => mockWatch()).thenAnswer((_) => Stream.value(sampleCustomers));
      when(() => mockWatchLedger(any())).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final statementButton = find.byIcon(Icons.receipt_long_rounded).first;
      await tester.ensureVisible(statementButton);
      await tester.tap(statementButton);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'كشف حساب تفصيلي: الحركات المالية، المبيعات، السدادات النقدية، والأرصدة',
        ),
        findsOneWidget,
      );
    });
  });
}
