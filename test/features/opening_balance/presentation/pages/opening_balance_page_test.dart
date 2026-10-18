import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/di/injector.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/result/result.dart';
import 'package:sales_manager/core/widgets/states/loading_view.dart';
import 'package:sales_manager/features/customers/domain/entities/customer.dart';
import 'package:sales_manager/features/customers/domain/usecases/get_customers_usecase.dart';
import 'package:sales_manager/features/opening_balance/domain/entities/opening_balance_input.dart';
import 'package:sales_manager/features/opening_balance/domain/usecases/check_opening_balance_status_usecase.dart';
import 'package:sales_manager/features/opening_balance/domain/usecases/save_opening_balances_usecase.dart';
import 'package:sales_manager/features/opening_balance/presentation/pages/opening_balance_page.dart';
import 'package:sales_manager/features/products/domain/entities/product.dart';
import 'package:sales_manager/features/products/domain/usecases/get_products_usecase.dart';
import 'package:sales_manager/features/suppliers/domain/entities/supplier.dart';
import 'package:sales_manager/features/suppliers/domain/usecases/get_suppliers_usecase.dart';

class MockCheckOpeningBalanceStatusUseCase extends Mock
    implements CheckOpeningBalanceStatusUseCase {}

class MockSaveOpeningBalancesUseCase extends Mock
    implements SaveOpeningBalancesUseCase {}

class MockGetProductsUseCase extends Mock implements GetProductsUseCase {}

class MockGetCustomersUseCase extends Mock implements GetCustomersUseCase {}

class MockGetSuppliersUseCase extends Mock implements GetSuppliersUseCase {}

class FakeOpeningBalanceInput extends Fake implements OpeningBalanceInput {}

void main() {
  late MockCheckOpeningBalanceStatusUseCase mockCheckStatus;
  late MockSaveOpeningBalancesUseCase mockSave;
  late MockGetProductsUseCase mockGetProducts;
  late MockGetCustomersUseCase mockGetCustomers;
  late MockGetSuppliersUseCase mockGetSuppliers;

  final sampleProducts = [
    Product(
      id: 1,
      name: 'أرز أبيض فاخر',
      code: 'RICE-01',
      unit: 'شيكارة',
      currentSalePrice: const Money.fromPiastres(35000),
      currentPurchasePrice: const Money.fromPiastres(30000),
      currentQuantity: Decimal.zero,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  final sampleCustomers = [
    Customer(
      id: 10,
      name: 'عميل تجريبي',
      phone: '01012345678',
      currentBalance: Money.zero,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  final sampleSuppliers = [
    Supplier(
      id: 20,
      name: 'مورد تجريبي',
      phone: '01212345678',
      currentBalance: Money.zero,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  setUpAll(() {
    registerFallbackValue(FakeOpeningBalanceInput());
  });

  setUp(() async {
    await getIt.reset();

    mockCheckStatus = MockCheckOpeningBalanceStatusUseCase();
    mockSave = MockSaveOpeningBalancesUseCase();
    mockGetProducts = MockGetProductsUseCase();
    mockGetCustomers = MockGetCustomersUseCase();
    mockGetSuppliers = MockGetSuppliersUseCase();

    getIt.registerSingleton<CheckOpeningBalanceStatusUseCase>(mockCheckStatus);
    getIt.registerSingleton<SaveOpeningBalancesUseCase>(mockSave);
    getIt.registerSingleton<GetProductsUseCase>(mockGetProducts);
    getIt.registerSingleton<GetCustomersUseCase>(mockGetCustomers);
    getIt.registerSingleton<GetSuppliersUseCase>(mockGetSuppliers);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: OpeningBalancePage(),
      ),
    );
  }

  group('OpeningBalancePage Widget Tests', () {
    testWidgets('Renders LoadingView while checking status', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final completer = Completer<Result<bool>>();
      when(() => mockCheckStatus()).thenAnswer((_) => completer.future);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(LoadingView), findsOneWidget);
    });

    testWidgets('Renders already saved view when opening balance was already committed',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      when(() => mockCheckStatus()).thenAnswer((_) async => const Success(true));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('الأرصدة الافتتاحية مثبتة ومحمية'), findsOneWidget);
      expect(find.text('الانتقال إلى لوحة التحكم الرئيسية'), findsOneWidget);
    });

    testWidgets('Renders ready view with KPIs, tab bar, and cashbox input',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      when(() => mockCheckStatus()).thenAnswer((_) async => const Success(false));
      when(() => mockGetProducts(isActiveOnly: true))
          .thenAnswer((_) async => Success(sampleProducts));
      when(() => mockGetCustomers(isActiveOnly: true))
          .thenAnswer((_) async => Success(sampleCustomers));
      when(() => mockGetSuppliers(isActiveOnly: true))
          .thenAnswer((_) async => Success(sampleSuppliers));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Header
      expect(find.text('الأرصدة الافتتاحية لنقطة الصفر'), findsOneWidget);

      // Metric Cards
      expect(find.text('نقدية الخزينة الافتتاحية'), findsOneWidget);
      expect(find.text('أصناف المخزون المُدخلة'), findsOneWidget);
      expect(find.text('إجمالي ديون العملاء'), findsOneWidget);
      expect(find.text('إجمالي مستحقات الموردين'), findsOneWidget);

      // Default Cashbox tab
      expect(find.byKey(const ValueKey('cashbox_input')), findsOneWidget);
    });

    testWidgets('Can switch tabs and display products, customers, and suppliers',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      when(() => mockCheckStatus()).thenAnswer((_) async => const Success(false));
      when(() => mockGetProducts(isActiveOnly: true))
          .thenAnswer((_) async => Success(sampleProducts));
      when(() => mockGetCustomers(isActiveOnly: true))
          .thenAnswer((_) async => Success(sampleCustomers));
      when(() => mockGetSuppliers(isActiveOnly: true))
          .thenAnswer((_) async => Success(sampleSuppliers));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Switch to Products tab
      await tester.tap(find.text('مخزون المنتجات (1)'));
      await tester.pumpAndSettle();
      expect(find.text('أرز أبيض فاخر'), findsOneWidget);

      // Switch to Customers tab
      await tester.tap(find.text('ذمم العملاء (1)'));
      await tester.pumpAndSettle();
      expect(find.text('عميل تجريبي'), findsOneWidget);

      // Switch to Suppliers tab
      await tester.tap(find.text('مستحقات الموردين (1)'));
      await tester.pumpAndSettle();
      expect(find.text('مورد تجريبي'), findsOneWidget);
    });

    testWidgets('Opens confirmation dialog and calls save when confirmed',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      when(() => mockCheckStatus()).thenAnswer((_) async => const Success(false));
      when(() => mockGetProducts(isActiveOnly: true))
          .thenAnswer((_) async => Success(sampleProducts));
      when(() => mockGetCustomers(isActiveOnly: true))
          .thenAnswer((_) async => Success(sampleCustomers));
      when(() => mockGetSuppliers(isActiveOnly: true))
          .thenAnswer((_) async => Success(sampleSuppliers));
      when(() => mockSave(any(), createdBy: any(named: 'createdBy')))
          .thenAnswer((_) async => const Success(null));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap save button
      await tester.tap(find.text('حفظ وتثبيت الأرصدة نهائياً'));
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('تأكيد حفظ وتثبيت الأرصدة'), findsOneWidget);

      // Confirm
      await tester.tap(find.text('نعم، احفظ وثبّت الأرصدة'));
      await tester.pumpAndSettle();

      // Verify save was invoked
      verify(() => mockSave(any(), createdBy: any(named: 'createdBy'))).called(1);

      // Verify success view is displayed
      expect(find.text('اكتمل تثبيت الأرصدة بنجاح!'), findsOneWidget);
    });
  });
}
