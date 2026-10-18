import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/result/failures.dart';
import 'package:sales_manager/core/result/result.dart';
import 'package:sales_manager/features/products/domain/entities/product.dart';
import 'package:sales_manager/features/products/domain/repositories/product_repository.dart';
import 'package:sales_manager/features/products/domain/usecases/update_product_usecase.dart';

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late UpdateProductUseCase useCase;
  late MockProductRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(
      Product(
        id: 0,
        name: 'fallback',
        unit: 'قطعة',
        currentSalePrice: Money.zero,
        currentPurchasePrice: Money.zero,
        currentQuantity: Decimal.zero,
        createdAt: DateTime(2026, 1, 1),
      ),
    );
  });

  setUp(() {
    mockRepository = MockProductRepository();
    useCase = UpdateProductUseCase(mockRepository);
  });

  group('UpdateProductUseCase Unit Tests', () {
    test('Fails when name is empty', () async {
      final product = Product(
        id: 1,
        name: '   ',
        unit: 'قطعة',
        currentSalePrice: const Money.fromPiastres(1000),
        currentPurchasePrice: const Money.fromPiastres(800),
        currentQuantity: Decimal.zero,
        createdAt: DateTime(2026, 1, 1),
      );

      final result = await useCase(product);
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('Fails when code collides with another product ID', () async {
      final productToUpdate = Product(
        id: 1,
        name: 'منتج أ',
        code: 'COLLIDE-01',
        unit: 'قطعة',
        currentSalePrice: const Money.fromPiastres(1000),
        currentPurchasePrice: const Money.fromPiastres(800),
        currentQuantity: Decimal.zero,
        createdAt: DateTime(2026, 1, 1),
      );

      final otherProductWithSameCode = Product(
        id: 2, // Different ID!
        name: 'منتج ب',
        code: 'COLLIDE-01',
        unit: 'علبة',
        currentSalePrice: const Money.fromPiastres(1200),
        currentPurchasePrice: const Money.fromPiastres(900),
        currentQuantity: Decimal.zero,
        createdAt: DateTime(2026, 1, 1),
      );

      when(() => mockRepository.getProductByCode('COLLIDE-01'))
          .thenAnswer((_) async => Success(otherProductWithSameCode));

      final result = await useCase(productToUpdate);
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ConflictFailure>());
    });

    test('Allows keeping same code for the same product ID', () async {
      final productToUpdate = Product(
        id: 1,
        name: 'منتج أ معدل',
        code: 'SAME-01',
        unit: 'قطعة',
        currentSalePrice: const Money.fromPiastres(1500),
        currentPurchasePrice: const Money.fromPiastres(1000),
        currentQuantity: Decimal.zero,
        createdAt: DateTime(2026, 1, 1),
      );

      final existingProductSameId = Product(
        id: 1, // Same ID!
        name: 'منتج أ قديم',
        code: 'SAME-01',
        unit: 'قطعة',
        currentSalePrice: const Money.fromPiastres(1000),
        currentPurchasePrice: const Money.fromPiastres(800),
        currentQuantity: Decimal.zero,
        createdAt: DateTime(2026, 1, 1),
      );

      when(() => mockRepository.getProductByCode('SAME-01'))
          .thenAnswer((_) async => Success(existingProductSameId));

      when(() => mockRepository.updateProduct(any()))
          .thenAnswer((_) async => Success(productToUpdate));

      final result = await useCase(productToUpdate);
      expect(result.isSuccess, isTrue);
    });
  });
}
