import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/di/injector.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/widgets/states/empty_view.dart';
import 'package:sales_manager/features/suppliers/domain/entities/supplier.dart';
import 'package:sales_manager/features/suppliers/domain/usecases/add_supplier_usecase.dart';
import 'package:sales_manager/features/suppliers/domain/usecases/toggle_supplier_status_usecase.dart';
import 'package:sales_manager/features/suppliers/domain/usecases/update_supplier_usecase.dart';
import 'package:sales_manager/features/suppliers/domain/usecases/watch_supplier_ledger_usecase.dart';
import 'package:sales_manager/features/suppliers/domain/usecases/watch_suppliers_usecase.dart';
import 'package:sales_manager/features/suppliers/presentation/pages/suppliers_page.dart';

class MockWatchSuppliersUseCase extends Mock implements WatchSuppliersUseCase {}

class MockAddSupplierUseCase extends Mock implements AddSupplierUseCase {}

class MockUpdateSupplierUseCase extends Mock implements UpdateSupplierUseCase {}

class MockToggleSupplierStatusUseCase extends Mock
    implements ToggleSupplierStatusUseCase {}

class MockWatchSupplierLedgerUseCase extends Mock
    implements WatchSupplierLedgerUseCase {}

void main() {
  late MockWatchSuppliersUseCase mockWatch;
  late MockAddSupplierUseCase mockAdd;
  late MockUpdateSupplierUseCase mockUpdate;
  late MockToggleSupplierStatusUseCase mockToggle;
  late MockWatchSupplierLedgerUseCase mockWatchLedger;

  final sampleSuppliers = [
    Supplier(
      id: 1,
      name: 'شركة الأمل للتوريدات',
      phone: '01011111111',
      address: 'العاشر من رمضان',
      notes: 'مورد رئيسي',
      currentBalance: const Money.fromPiastres(150000), // 1500.00 EGP due
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
      createdBy: 'admin',
    ),
    Supplier(
      id: 2,
      name: 'مؤسسة السلام',
      phone: '01022222222',
      address: 'العتبة',
      notes: null,
      currentBalance: Money.zero, // Settled
      isActive: true,
      createdAt: DateTime(2026, 1, 2),
      createdBy: 'admin',
    ),
  ];

  setUp(() async {
    await getIt.reset();
    mockWatch = MockWatchSuppliersUseCase();
    mockAdd = MockAddSupplierUseCase();
    mockUpdate = MockUpdateSupplierUseCase();
    mockToggle = MockToggleSupplierStatusUseCase();
    mockWatchLedger = MockWatchSupplierLedgerUseCase();

    getIt.registerSingleton<WatchSuppliersUseCase>(mockWatch);
    getIt.registerSingleton<AddSupplierUseCase>(mockAdd);
    getIt.registerSingleton<UpdateSupplierUseCase>(mockUpdate);
    getIt.registerSingleton<ToggleSupplierStatusUseCase>(mockToggle);
    getIt.registerSingleton<WatchSupplierLedgerUseCase>(mockWatchLedger);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: SuppliersPage(),
      ),
    );
  }

  group('SuppliersPage Widget Tests', () {
    testWidgets('Renders empty view when there are no suppliers', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      when(() => mockWatch()).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('الموردون والحسابات الجارية'), findsOneWidget);
      expect(find.byType(EmptyView), findsOneWidget);
      expect(find.text('لا يوجد موردون مسجلون بالنظام حتى الآن'), findsOneWidget);
    });

    testWidgets('Renders KPI metrics and data table when suppliers are loaded',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      when(() => mockWatch()).thenAnswer((_) => Stream.value(sampleSuppliers));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Header
      expect(find.text('الموردون والحسابات الجارية'), findsOneWidget);

      // KPI Metric Cards
      expect(find.text('إجمالي الموردين المسجلين'), findsOneWidget);
      expect(find.text('موردون مستحق لهم مبالغ'), findsOneWidget);
      expect(find.text('إجمالي المبالغ المستحقة للموردين'), findsOneWidget);

      // DataTable Supplier entries
      expect(find.text('شركة الأمل للتوريدات'), findsOneWidget);
      expect(find.text('01011111111'), findsOneWidget);
      expect(find.text('مؤسسة السلام'), findsOneWidget);
      expect(find.text('01022222222'), findsOneWidget);
      expect(find.byType(DataTable), findsOneWidget);
    });

    testWidgets('Clicking add supplier button opens SupplierFormDialog',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      when(() => mockWatch()).thenAnswer((_) => Stream.value(sampleSuppliers));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final addButton = find.text('تسجيل مورد جديد').first;
      expect(addButton, findsOneWidget);

      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Form dialog opened
      expect(find.widgetWithText(TextFormField, 'اسم المورد أو الشركة *'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'رقم الهاتف (اختياري)'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'العنوان / المركز الرئيسي (اختياري)'), findsOneWidget);
      expect(
        find.widgetWithText(
          TextFormField,
          'رصيد المديونية الافتتاحي للمورد بالجنيه (اختياري)',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Clicking edit supplier opens dialog in edit mode',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      when(() => mockWatch()).thenAnswer((_) => Stream.value(sampleSuppliers));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final editButton = find.byIcon(Icons.edit_outlined).first;
      await tester.ensureVisible(editButton);
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      expect(find.text('تعديل بيانات المورد'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'اسم المورد أو الشركة *'), findsOneWidget);
      // In edit mode, initial balance input must NOT be present
      expect(
        find.text('رصيد المديونية الافتتاحي للمورد بالجنيه (اختياري)'),
        findsNothing,
      );
    });

    testWidgets('Clicking statement icon button opens SupplierLedgerDialog',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      when(() => mockWatch()).thenAnswer((_) => Stream.value(sampleSuppliers));
      when(() => mockWatchLedger(any())).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final statementButton = find.byIcon(Icons.receipt_long_rounded).first;
      await tester.ensureVisible(statementButton);
      await tester.tap(statementButton);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'كشف حساب تفصيلي: المشتريات، سندات الصرف، المرتجعات، والأرصدة المستحقة',
        ),
        findsOneWidget,
      );
    });
  });
}
