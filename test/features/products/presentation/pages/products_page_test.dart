import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/di/injector.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/strings/app_strings.dart';
import 'package:sales_manager/core/widgets/states/empty_view.dart';
import 'package:sales_manager/features/products/domain/entities/product.dart';
import 'package:sales_manager/features/products/domain/usecases/add_product_usecase.dart';
import 'package:sales_manager/features/products/domain/usecases/get_products_usecase.dart';
import 'package:sales_manager/features/products/domain/usecases/toggle_product_status_usecase.dart';
import 'package:sales_manager/features/products/domain/usecases/update_product_usecase.dart';
import 'package:sales_manager/features/products/domain/usecases/watch_products_usecase.dart';
import 'package:sales_manager/features/products/presentation/pages/products_page.dart';

class MockWatchProductsUseCase extends Mock implements WatchProductsUseCase {}
class MockGetProductsUseCase extends Mock implements GetProductsUseCase {}
class MockAddProductUseCase extends Mock implements AddProductUseCase {}
class MockUpdateProductUseCase extends Mock implements UpdateProductUseCase {}
class MockToggleProductStatusUseCase extends Mock implements ToggleProductStatusUseCase {}

void main() {
  late MockWatchProductsUseCase mockWatch;
  late MockGetProductsUseCase mockGet;
  late MockAddProductUseCase mockAdd;
  late MockUpdateProductUseCase mockUpdate;
  late MockToggleProductStatusUseCase mockToggle;

  final sampleProducts = [
    Product(
      id: 1,
      name: 'شاي أخضر',
      code: 'TEA-01',
      unit: 'باكت',
      currentSalePrice: const Money.fromPiastres(4000),
      currentPurchasePrice: const Money.fromPiastres(3200),
      currentQuantity: Decimal.parse('4'),
      lowStockThreshold: Decimal.parse('10'),
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  setUp(() {
    mockWatch = MockWatchProductsUseCase();
    mockGet = MockGetProductsUseCase();
    mockAdd = MockAddProductUseCase();
    mockUpdate = MockUpdateProductUseCase();
    mockToggle = MockToggleProductStatusUseCase();

    getIt.reset();
    getIt.registerSingleton<WatchProductsUseCase>(mockWatch);
    getIt.registerSingleton<GetProductsUseCase>(mockGet);
    getIt.registerSingleton<AddProductUseCase>(mockAdd);
    getIt.registerSingleton<UpdateProductUseCase>(mockUpdate);
    getIt.registerSingleton<ToggleProductStatusUseCase>(mockToggle);
  });

  tearDown(() {
    getIt.reset();
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: ProductsPage(),
      ),
    );
  }

  group('ProductsPage Widget Tests', () {
    testWidgets('Renders empty view when there are no products', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      when(() => mockWatch(query: any(named: 'query'), isActiveOnly: any(named: 'isActiveOnly')))
          .thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.products), findsOneWidget);
      expect(find.byType(EmptyView), findsOneWidget);
    });

    testWidgets('Renders data table with product details when products are loaded', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      when(() => mockWatch(query: any(named: 'query'), isActiveOnly: any(named: 'isActiveOnly')))
          .thenAnswer((_) => Stream.value(sampleProducts));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('شاي أخضر'), findsOneWidget);
      expect(find.text('TEA-01'), findsOneWidget);
      expect(find.text('باكت'), findsOneWidget);
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('إجمالي الأصناف المعروضة'), findsOneWidget);
    });

    testWidgets('Clicking add product button opens dialog', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      when(() => mockWatch(query: any(named: 'query'), isActiveOnly: any(named: 'isActiveOnly')))
          .thenAnswer((_) => Stream.value(sampleProducts));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final addButton = find.text('إضافة منتج جديد').first;
      expect(addButton, findsOneWidget);

      await tester.tap(addButton);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'اسم المنتج *'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'سعر البيع (ج.م) *'), findsOneWidget);
    });
  });
}
