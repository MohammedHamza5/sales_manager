import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/result/failures.dart';
import 'package:sales_manager/core/result/result.dart';
import 'package:sales_manager/features/products/domain/entities/product.dart';
import 'package:sales_manager/features/products/domain/repositories/product_repository.dart';
import 'package:sales_manager/features/products/domain/usecases/add_product_usecase.dart';

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late AddProductUseCase useCase;
  late MockProductRepository mockRepository;

  setUp(() {
    mockRepository = MockProductRepository();
    useCase = AddProductUseCase(mockRepository);
  });

  group('AddProductUseCase Unit Tests', () {
    test('Fails when product name is empty or only whitespace', () async {
      final result = await useCase(
        name: '   ',
        unit: 'قطعة',
        salePrice: const Money.fromPiastres(1000),
        purchasePrice: const Money.fromPiastres(800),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect((result.failureOrNull as ValidationFailure).field, 'name');
    });

    test('Fails when unit is empty', () async {
      final result = await useCase(
        name: 'منتج تجريبي',
        unit: '  ',
        salePrice: const Money.fromPiastres(1000),
        purchasePrice: const Money.fromPiastres(800),
      );

      expect(result.isFailure, isTrue);
      expect((result.failureOrNull as ValidationFailure).field, 'unit');
    });

    test('Fails when sale price is negative', () async {
      final result = await useCase(
        name: 'منتج تجريبي',
        unit: 'قطعة',
        salePrice: const Money.fromPiastres(-100),
        purchasePrice: const Money.fromPiastres(500),
      );

      expect(result.isFailure, isTrue);
      expect((result.failureOrNull as ValidationFailure).field, 'salePrice');
    });

    test('Fails when purchase price is negative', () async {
      final result = await useCase(
        name: 'منتج تجريبي',
        unit: 'قطعة',
        salePrice: const Money.fromPiastres(1000),
        purchasePrice: const Money.fromPiastres(-500),
      );

      expect(result.isFailure, isTrue);
      expect((result.failureOrNull as ValidationFailure).field, 'purchasePrice');
    });

    test('Fails when initial quantity is negative', () async {
      final result = await useCase(
        name: 'منتج تجريبي',
        unit: 'قطعة',
        salePrice: const Money.fromPiastres(1000),
        purchasePrice: const Money.fromPiastres(500),
        initialQuantity: Decimal.parse('-5'),
      );

      expect(result.isFailure, isTrue);
      expect((result.failureOrNull as ValidationFailure).field, 'initialQuantity');
    });

    test('Fails when code already exists in repository', () async {
      final existingProduct = Product(
        id: 1,
        name: 'منتج موجود',
        code: 'BAR-123',
        unit: 'قطعة',
        currentSalePrice: const Money.fromPiastres(1000),
        currentPurchasePrice: const Money.fromPiastres(700),
        currentQuantity: Decimal.zero,
        createdAt: DateTime(2026, 1, 1),
      );

      when(() => mockRepository.getProductByCode('BAR-123'))
          .thenAnswer((_) async => Success(existingProduct));

      final result = await useCase(
        name: 'منتج جديد',
        code: 'BAR-123',
        unit: 'قطعة',
        salePrice: const Money.fromPiastres(2000),
        purchasePrice: const Money.fromPiastres(1500),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ConflictFailure>());
    });

    test('Successfully adds product when all inputs are valid', () async {
      final expectedProduct = Product(
        id: 42,
        name: 'سكر أبيض',
        code: 'SUGAR-01',
        unit: 'كيلو',
        currentSalePrice: const Money.fromPiastres(3500),
        currentPurchasePrice: const Money.fromPiastres(2800),
        currentQuantity: Decimal.parse('50'),
        lowStockThreshold: Decimal.parse('10'),
        createdAt: DateTime.now(),
      );

      when(() => mockRepository.getProductByCode('SUGAR-01'))
          .thenAnswer((_) async => const Success(null));

      when(() => mockRepository.addProduct(
            name: 'سكر أبيض',
            code: 'SUGAR-01',
            unit: 'كيلو',
            salePrice: const Money.fromPiastres(3500),
            purchasePrice: const Money.fromPiastres(2800),
            initialQuantity: Decimal.parse('50'),
            lowStockThreshold: Decimal.parse('10'),
            createdBy: 'admin',
          )).thenAnswer((_) async => Success(expectedProduct));

      final result = await useCase(
        name: 'سكر أبيض',
        code: 'SUGAR-01',
        unit: 'كيلو',
        salePrice: const Money.fromPiastres(3500),
        purchasePrice: const Money.fromPiastres(2800),
        initialQuantity: Decimal.parse('50'),
        lowStockThreshold: Decimal.parse('10'),
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.id, 42);
      expect(result.dataOrNull?.name, 'سكر أبيض');
      expect(result.dataOrNull?.currentUnitMargin.piastres, 700); // 3500 - 2800
    });
  });
}
