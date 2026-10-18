import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/result/result.dart';
import 'package:sales_manager/features/products/domain/entities/product.dart';
import 'package:sales_manager/features/products/domain/usecases/add_product_usecase.dart';
import 'package:sales_manager/features/products/domain/usecases/toggle_product_status_usecase.dart';
import 'package:sales_manager/features/products/domain/usecases/update_product_usecase.dart';
import 'package:sales_manager/features/products/domain/usecases/watch_products_usecase.dart';
import 'package:sales_manager/features/products/presentation/cubit/products_cubit.dart';
import 'package:sales_manager/features/products/presentation/cubit/products_state.dart';

class MockWatchProductsUseCase extends Mock implements WatchProductsUseCase {}
class MockAddProductUseCase extends Mock implements AddProductUseCase {}
class MockUpdateProductUseCase extends Mock implements UpdateProductUseCase {}
class MockToggleProductStatusUseCase extends Mock implements ToggleProductStatusUseCase {}

void main() {
  late MockWatchProductsUseCase mockWatch;
  late MockAddProductUseCase mockAdd;
  late MockUpdateProductUseCase mockUpdate;
  late MockToggleProductStatusUseCase mockToggle;

  final sampleProducts = [
    Product(
      id: 1,
      name: 'جبنة بيضاء',
      code: 'CHEESE-01',
      unit: 'علبة',
      currentSalePrice: const Money.fromPiastres(2500),
      currentPurchasePrice: const Money.fromPiastres(2000),
      currentQuantity: Decimal.parse('3'),
      lowStockThreshold: Decimal.parse('5'),
      createdAt: DateTime(2026, 1, 1),
    ),
    Product(
      id: 2,
      name: 'لبن معبأ',
      code: 'MILK-01',
      unit: 'لتر',
      currentSalePrice: const Money.fromPiastres(3500),
      currentPurchasePrice: const Money.fromPiastres(3000),
      currentQuantity: Decimal.parse('15'),
      lowStockThreshold: Decimal.parse('5'),
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  setUp(() {
    mockWatch = MockWatchProductsUseCase();
    mockAdd = MockAddProductUseCase();
    mockUpdate = MockUpdateProductUseCase();
    mockToggle = MockToggleProductStatusUseCase();
  });

  group('ProductsCubit Tests', () {
    test('Initial state is ProductsInitial', () {
      final cubit = ProductsCubit(
        watchProductsUseCase: mockWatch,
        addProductUseCase: mockAdd,
        updateProductUseCase: mockUpdate,
        toggleProductStatusUseCase: mockToggle,
      );

      expect(cubit.state, const ProductsInitial());
      cubit.close();
    });

    blocTest<ProductsCubit, ProductsState>(
      'Emits [ProductsLoading, ProductsLoaded] when stream emits products',
      build: () {
        when(() => mockWatch(query: null, isActiveOnly: true))
            .thenAnswer((_) => Stream.value(sampleProducts));
        return ProductsCubit(
          watchProductsUseCase: mockWatch,
          addProductUseCase: mockAdd,
          updateProductUseCase: mockUpdate,
          toggleProductStatusUseCase: mockToggle,
        );
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        const ProductsLoading(),
        ProductsLoaded(products: sampleProducts, filterActiveOnly: true),
      ],
    );

    blocTest<ProductsCubit, ProductsState>(
      'Emits [ProductsLoading, ProductsEmpty] when stream emits empty list',
      build: () {
        when(() => mockWatch(query: null, isActiveOnly: true))
            .thenAnswer((_) => Stream.value([]));
        return ProductsCubit(
          watchProductsUseCase: mockWatch,
          addProductUseCase: mockAdd,
          updateProductUseCase: mockUpdate,
          toggleProductStatusUseCase: mockToggle,
        );
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        const ProductsLoading(),
        const ProductsEmpty(
          message: 'لا توجد منتجات تطابق معايير البحث والترشيح',
          hasActiveFilters: true,
        ),
      ],
    );

    blocTest<ProductsCubit, ProductsState>(
      'Filters low stock items when toggleLowStockFilter is called',
      build: () {
        when(() => mockWatch(query: null, isActiveOnly: true))
            .thenAnswer((_) => Stream.value(sampleProducts));
        return ProductsCubit(
          watchProductsUseCase: mockWatch,
          addProductUseCase: mockAdd,
          updateProductUseCase: mockUpdate,
          toggleProductStatusUseCase: mockToggle,
        );
      },
      act: (cubit) => cubit.toggleLowStockFilter(),
      expect: () => [
        const ProductsLoading(),
        ProductsLoaded(
          products: [sampleProducts.first], // Only product 1 is low stock (3 <= 5)
          filterActiveOnly: true,
          filterLowStockOnly: true,
        ),
      ],
    );

    test('addProduct delegates directly to AddProductUseCase', () async {
      when(() => mockAdd(
            name: 'منتج تجريبي',
            code: 'TEST-01',
            unit: 'قطعة',
            salePrice: const Money.fromPiastres(1000),
            purchasePrice: const Money.fromPiastres(700),
            initialQuantity: Decimal.parse('10'),
            lowStockThreshold: Decimal.parse('2'),
            createdBy: 'admin',
          )).thenAnswer((_) async => Success(sampleProducts.first));

      final cubit = ProductsCubit(
        watchProductsUseCase: mockWatch,
        addProductUseCase: mockAdd,
        updateProductUseCase: mockUpdate,
        toggleProductStatusUseCase: mockToggle,
      );

      final result = await cubit.addProduct(
        name: 'منتج تجريبي',
        code: 'TEST-01',
        unit: 'قطعة',
        salePrice: const Money.fromPiastres(1000),
        purchasePrice: const Money.fromPiastres(700),
        initialQuantity: Decimal.parse('10'),
        lowStockThreshold: Decimal.parse('2'),
      );

      expect(result.isSuccess, isTrue);
      verify(() => mockAdd(
            name: 'منتج تجريبي',
            code: 'TEST-01',
            unit: 'قطعة',
            salePrice: const Money.fromPiastres(1000),
            purchasePrice: const Money.fromPiastres(700),
            initialQuantity: Decimal.parse('10'),
            lowStockThreshold: Decimal.parse('2'),
            createdBy: 'admin',
          )).called(1);

      await cubit.close();
    });
  });
}
