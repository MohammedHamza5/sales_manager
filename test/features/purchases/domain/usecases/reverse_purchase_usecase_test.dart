import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/result/failures.dart';
import 'package:sales_manager/core/result/result.dart';
import 'package:sales_manager/features/purchases/domain/entities/purchase.dart';
import 'package:sales_manager/features/purchases/domain/repositories/purchase_repository.dart';
import 'package:sales_manager/features/purchases/domain/usecases/reverse_purchase_usecase.dart';

class MockPurchaseRepository extends Mock implements PurchaseRepository {}

void main() {
  late MockPurchaseRepository mockRepo;
  late ReversePurchaseUseCase useCase;

  setUp(() {
    mockRepo = MockPurchaseRepository();
    useCase = ReversePurchaseUseCase(mockRepo);
  });

  group('ReversePurchaseUseCase Unit Tests', () {
    test('Fails when purchaseId is invalid (<= 0)', () async {
      final result = await useCase(purchaseId: 0);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      verifyZeroInteractions(mockRepo);
    });

    test('Delegates to repository when purchaseId is valid', () async {
      final now = DateTime.now();
      final expectedPurchase = Purchase(
        id: 5,
        invoiceNo: 105,
        supplierId: 2,
        supplierName: 'مورد 2',
        purchaseDate: now,
        totalAmount: const Money(5000),
        paidAmountAtCreation: const Money(5000),
        status: PurchaseStatus.reversed,
        createdAt: now,
      );

      when(() => mockRepo.reversePurchase(purchaseId: 5, createdBy: 'admin'))
          .thenAnswer((_) async => Success(expectedPurchase));

      final result = await useCase(purchaseId: 5);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.isReversed, isTrue);
      verify(() => mockRepo.reversePurchase(purchaseId: 5, createdBy: 'admin')).called(1);
    });
  });
}
