import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/features/inventory/domain/entities/inventory_movement.dart';
import 'package:sales_manager/features/inventory/domain/usecases/watch_inventory_movements_usecase.dart';
import 'package:sales_manager/features/inventory/presentation/cubit/product_movements_cubit.dart';
import 'package:sales_manager/features/inventory/presentation/cubit/product_movements_state.dart';

class MockWatchInventoryMovementsUseCase extends Mock
    implements WatchInventoryMovementsUseCase {}

void main() {
  late MockWatchInventoryMovementsUseCase mockWatch;

  final sampleMovements = [
    InventoryMovement(
      id: 1,
      productId: 10,
      productName: 'سكر أبيض',
      productUnit: 'كيلو',
      type: MovementType.openingBalance,
      quantityDelta: Decimal.parse('50'),
      balanceAfter: Decimal.parse('50'),
      createdAt: DateTime(2026, 1, 1, 10, 0),
    ),
    InventoryMovement(
      id: 2,
      productId: 10,
      productName: 'سكر أبيض',
      productUnit: 'كيلو',
      type: MovementType.sale,
      quantityDelta: Decimal.parse('-5'),
      balanceAfter: Decimal.parse('45'),
      createdAt: DateTime(2026, 1, 1, 11, 30),
    ),
  ];

  setUp(() {
    mockWatch = MockWatchInventoryMovementsUseCase();
  });

  group('ProductMovementsCubit Tests', () {
    test('Initial state is ProductMovementsInitial', () {
      final cubit = ProductMovementsCubit(
        watchMovementsUseCase: mockWatch,
        productId: 10,
      );

      expect(cubit.state, const ProductMovementsInitial());
      cubit.close();
    });

    blocTest<ProductMovementsCubit, ProductMovementsState>(
      'Emits [ProductMovementsLoading, ProductMovementsLoaded] when movements arrive',
      build: () {
        when(() => mockWatch(productId: 10, type: null))
            .thenAnswer((_) => Stream.value(sampleMovements));
        return ProductMovementsCubit(
          watchMovementsUseCase: mockWatch,
          productId: 10,
        );
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        const ProductMovementsLoading(),
        ProductMovementsLoaded(movements: sampleMovements),
      ],
      verify: (cubit) {
        final state = cubit.state as ProductMovementsLoaded;
        expect(state.totalInflow, Decimal.parse('50'));
        expect(state.totalOutflow, Decimal.parse('5'));
        expect(state.count, 2);
      },
    );

    blocTest<ProductMovementsCubit, ProductMovementsState>(
      'Emits [ProductMovementsLoading, ProductMovementsEmpty] when stream is empty',
      build: () {
        when(() => mockWatch(productId: 10, type: null))
            .thenAnswer((_) => Stream.value([]));
        return ProductMovementsCubit(
          watchMovementsUseCase: mockWatch,
          productId: 10,
        );
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        const ProductMovementsLoading(),
        const ProductMovementsEmpty(
          message: 'لا توجد حركات مخزنية مسجلة حتى الآن',
          hasFilter: false,
        ),
      ],
    );

    blocTest<ProductMovementsCubit, ProductMovementsState>(
      'Emits updated filter when setFilterType is called',
      build: () {
        when(() => mockWatch(productId: 10, type: MovementType.sale))
            .thenAnswer((_) => Stream.value([sampleMovements[1]]));
        return ProductMovementsCubit(
          watchMovementsUseCase: mockWatch,
          productId: 10,
        );
      },
      act: (cubit) => cubit.setFilterType(MovementType.sale),
      expect: () => [
        const ProductMovementsLoading(),
        ProductMovementsLoaded(
          movements: [sampleMovements[1]],
          filterType: MovementType.sale,
        ),
      ],
    );
  });
}
