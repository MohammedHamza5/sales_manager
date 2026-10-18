import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/result/failures.dart';
import 'package:sales_manager/core/result/result.dart';
import 'package:sales_manager/features/inventory/domain/entities/inventory_movement.dart';
import 'package:sales_manager/features/inventory/domain/usecases/record_stock_adjustment_usecase.dart';
import 'package:sales_manager/features/inventory/presentation/cubit/stock_adjustment_cubit.dart';
import 'package:sales_manager/features/inventory/presentation/cubit/stock_adjustment_state.dart';

class MockRecordStockAdjustmentUseCase extends Mock
    implements RecordStockAdjustmentUseCase {}

void main() {
  late StockAdjustmentCubit cubit;
  late MockRecordStockAdjustmentUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockRecordStockAdjustmentUseCase();
    cubit = StockAdjustmentCubit(
      recordStockAdjustmentUseCase: mockUseCase,
    );
  });

  tearDown(() {
    cubit.close();
  });

  final testMovement = InventoryMovement(
    id: 1,
    productId: 5,
    productName: 'أرز أبيض',
    productUnit: 'كيلو',
    type: MovementType.adjustment,
    quantityDelta: Decimal.parse('3'),
    balanceAfter: Decimal.parse('15'),
    referenceType: 'stock_adjustment',
    referenceId: 1,
    note: 'تسوية جردية',
    createdAt: DateTime.now(),
    createdBy: 'admin',
  );

  group('StockAdjustmentCubit Tests', () {
    test('Initial state is StockAdjustmentInitial', () {
      expect(cubit.state, const StockAdjustmentInitial());
    });

    blocTest<StockAdjustmentCubit, StockAdjustmentState>(
      'Emits [Submitting, Success] on successful adjustment',
      build: () {
        when(
          () => mockUseCase(
            productId: 5,
            quantityDelta: Decimal.parse('3'),
            reason: 'تسوية جردية',
            createdBy: 'admin',
          ),
        ).thenAnswer((_) async => Success(testMovement));
        return cubit;
      },
      act: (c) => c.submitAdjustment(
        productId: 5,
        quantityDelta: Decimal.parse('3'),
        reason: 'تسوية جردية',
      ),
      expect: () => [
        const StockAdjustmentSubmitting(),
        StockAdjustmentSuccess(testMovement),
      ],
    );

    blocTest<StockAdjustmentCubit, StockAdjustmentState>(
      'Emits [Submitting, Error] on failed adjustment',
      build: () {
        when(
          () => mockUseCase(
            productId: 5,
            quantityDelta: Decimal.parse('-20'),
            reason: 'تالف',
            createdBy: 'admin',
          ),
        ).thenAnswer(
          (_) async => const FailureResult(
            InsufficientStockFailure(
              productName: 'أرز أبيض',
              requestedQuantity: '20',
              availableQuantity: '12',
              message: 'الكمية غير كافية',
            ),
          ),
        );
        return cubit;
      },
      act: (c) => c.submitAdjustment(
        productId: 5,
        quantityDelta: Decimal.parse('-20'),
        reason: 'تالف',
      ),
      expect: () => [
        const StockAdjustmentSubmitting(),
        const StockAdjustmentError('الكمية غير كافية'),
      ],
    );

    blocTest<StockAdjustmentCubit, StockAdjustmentState>(
      'Resets back to StockAdjustmentInitial when reset is called',
      build: () => cubit,
      seed: () => StockAdjustmentSuccess(testMovement),
      act: (c) => c.reset(),
      expect: () => [
        const StockAdjustmentInitial(),
      ],
    );
  });
}
