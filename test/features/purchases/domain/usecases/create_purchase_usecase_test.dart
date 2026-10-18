import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/result/failures.dart';
import 'package:sales_manager/core/result/result.dart';
import 'package:sales_manager/features/purchases/domain/entities/purchase.dart';
import 'package:sales_manager/features/purchases/domain/repositories/purchase_repository.dart';
import 'package:sales_manager/features/purchases/domain/usecases/create_purchase_usecase.dart';

class MockPurchaseRepository extends Mock implements PurchaseRepository {}

void main() {
  late MockPurchaseRepository mockRepo;
  late CreatePurchaseUseCase useCase;

  setUp(() {
    mockRepo = MockPurchaseRepository();
    useCase = CreatePurchaseUseCase(mockRepo);
  });

  group('CreatePurchaseUseCase Unit Tests', () {
    test('Fails when items list is empty', () async {
      final params = CreatePurchaseParams(
        supplierId: 1,
        purchaseDate: DateTime.now(),
        items: const [],
        paidAmountAtCreation: Money.zero,
      );

      final result = await useCase(params);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      verifyZeroInteractions(mockRepo);
    });

    test('Fails when item quantity is <= zero', () async {
      final params = CreatePurchaseParams(
        supplierId: 1,
        purchaseDate: DateTime.now(),
        items: [
          PurchaseItemParam(
            productId: 1,
            quantity: Decimal.zero,
            unitCost: const Money(1000),
          ),
        ],
        paidAmountAtCreation: Money.zero,
      );

      final result = await useCase(params);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      verifyZeroInteractions(mockRepo);
    });

    test('Fails when paidAmount is greater than totalAmount', () async {
      final params = CreatePurchaseParams(
        supplierId: 1,
        purchaseDate: DateTime.now(),
        items: [
          PurchaseItemParam(
            productId: 1,
            quantity: Decimal.fromInt(2),
            unitCost: const Money(1000), // Total = 2000
          ),
        ],
        paidAmountAtCreation: const Money(3000), // Paid > Total
      );

      final result = await useCase(params);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      verifyZeroInteractions(mockRepo);
    });

    test('Delegates to repository when inputs are valid', () async {
      final now = DateTime.now();
      final params = CreatePurchaseParams(
        supplierId: 1,
        purchaseDate: now,
        items: [
          PurchaseItemParam(
            productId: 1,
            quantity: Decimal.fromInt(5),
            unitCost: const Money(2000),
          ),
        ],
        paidAmountAtCreation: const Money(5000),
      );

      final expectedPurchase = Purchase(
        id: 10,
        invoiceNo: 100,
        supplierId: 1,
        supplierName: 'مورد تجريبي',
        purchaseDate: now,
        totalAmount: const Money(10000),
        paidAmountAtCreation: const Money(5000),
        createdAt: now,
      );

      when(() => mockRepo.createPurchase(params))
          .thenAnswer((_) async => Success(expectedPurchase));

      final result = await useCase(params);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, expectedPurchase);
      verify(() => mockRepo.createPurchase(params)).called(1);
    });
  });
}
