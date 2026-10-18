import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/result/failures.dart';
import 'package:sales_manager/core/result/result.dart';
import 'package:sales_manager/features/inventory/domain/entities/inventory_movement.dart';
import 'package:sales_manager/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:sales_manager/features/inventory/domain/usecases/record_stock_adjustment_usecase.dart';

class MockInventoryRepository extends Mock implements InventoryRepository {}

void main() {
  late RecordStockAdjustmentUseCase useCase;
  late MockInventoryRepository mockRepository;

  setUp(() {
    mockRepository = MockInventoryRepository();
    useCase = RecordStockAdjustmentUseCase(mockRepository);
  });

  group('RecordStockAdjustmentUseCase Unit Tests', () {
    test('Fails when productId is invalid (<= 0)', () async {
      final result = await useCase(
        productId: 0,
        quantityDelta: Decimal.parse('5'),
        reason: 'تعديل جردي',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect((result.failureOrNull as ValidationFailure).field, 'productId');
    });

    test('Fails when quantityDelta is zero', () async {
      final result = await useCase(
        productId: 1,
        quantityDelta: Decimal.zero,
        reason: 'تعديل جردي',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect((result.failureOrNull as ValidationFailure).field, 'quantityDelta');
    });

    test('Fails when reason is empty or whitespace only', () async {
      final result = await useCase(
        productId: 1,
        quantityDelta: Decimal.parse('2'),
        reason: '   ',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect((result.failureOrNull as ValidationFailure).field, 'reason');
    });

    test('Delegates to repository with trimmed reason on valid inputs', () async {
      final movement = InventoryMovement(
        id: 10,
        productId: 1,
        productName: 'سكر أبيض',
        productUnit: 'كيلو',
        type: MovementType.adjustment,
        quantityDelta: Decimal.parse('5'),
        balanceAfter: Decimal.parse('25'),
        referenceType: 'stock_adjustment',
        referenceId: 1,
        note: 'جرد دوري نصف سنوي',
        createdAt: DateTime.now(),
        createdBy: 'admin',
      );

      when(
        () => mockRepository.recordAdjustment(
          productId: 1,
          quantityDelta: Decimal.parse('5'),
          reason: 'جرد دوري نصف سنوي',
          createdBy: 'admin',
        ),
      ).thenAnswer((_) async => Success(movement));

      final result = await useCase(
        productId: 1,
        quantityDelta: Decimal.parse('5'),
        reason: '  جرد دوري نصف سنوي  ',
        createdBy: 'admin',
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.id, 10);
      expect(result.dataOrNull?.quantityDelta, Decimal.parse('5'));
      expect(result.dataOrNull?.note, 'جرد دوري نصف سنوي');
      verify(
        () => mockRepository.recordAdjustment(
          productId: 1,
          quantityDelta: Decimal.parse('5'),
          reason: 'جرد دوري نصف سنوي',
          createdBy: 'admin',
        ),
      ).called(1);
    });
  });
}
