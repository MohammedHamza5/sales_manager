import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/features/purchases/domain/entities/purchase.dart';
import 'package:sales_manager/features/purchases/domain/usecases/reverse_purchase_usecase.dart';
import 'package:sales_manager/features/purchases/domain/usecases/watch_purchases_usecase.dart';
import 'package:sales_manager/features/purchases/presentation/cubit/purchases_list_cubit.dart';
import 'package:sales_manager/features/purchases/presentation/cubit/purchases_list_state.dart';

class MockWatchPurchasesUseCase extends Mock implements WatchPurchasesUseCase {}
class MockReversePurchaseUseCase extends Mock implements ReversePurchaseUseCase {}

void main() {
  late MockWatchPurchasesUseCase mockWatch;
  late MockReversePurchaseUseCase mockReverse;

  setUp(() {
    mockWatch = MockWatchPurchasesUseCase();
    mockReverse = MockReversePurchaseUseCase();
  });

  group('PurchasesListCubit Tests', () {
    test('Initial state is PurchasesListInitial', () {
      final cubit = PurchasesListCubit(
        watchPurchasesUseCase: mockWatch,
        reversePurchaseUseCase: mockReverse,
      );
      expect(cubit.state, const PurchasesListInitial());
      cubit.close();
    });

    blocTest<PurchasesListCubit, PurchasesListState>(
      'Emits [PurchasesListLoading, PurchasesListLoaded] when purchases stream emits data',
      build: () {
        when(() => mockWatch()).thenAnswer(
          (_) => Stream.value([
            Purchase(
              id: 1,
              invoiceNo: 101,
              supplierId: 1,
              supplierName: 'مورد 1',
              purchaseDate: DateTime(2026, 9, 24),
              totalAmount: const Money(10000),
              paidAmountAtCreation: const Money(5000),
              createdAt: DateTime(2026, 9, 24),
            ),
          ]),
        );
        return PurchasesListCubit(
          watchPurchasesUseCase: mockWatch,
          reversePurchaseUseCase: mockReverse,
        );
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        const PurchasesListLoading(),
        isA<PurchasesListLoaded>().having((s) => s.purchases.length, 'purchases length', 1),
      ],
    );

    blocTest<PurchasesListCubit, PurchasesListState>(
      'Emits [PurchasesListLoading, PurchasesListEmpty] when purchases stream emits empty list',
      build: () {
        when(() => mockWatch()).thenAnswer((_) => Stream.value([]));
        return PurchasesListCubit(
          watchPurchasesUseCase: mockWatch,
          reversePurchaseUseCase: mockReverse,
        );
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        const PurchasesListLoading(),
        const PurchasesListEmpty(),
      ],
    );
  });
}
