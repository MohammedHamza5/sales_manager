import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/result/result.dart';
import 'package:sales_manager/features/products/domain/entities/product.dart';
import 'package:sales_manager/features/purchases/domain/entities/purchase.dart';
import 'package:sales_manager/features/purchases/domain/repositories/purchase_repository.dart';
import 'package:sales_manager/features/purchases/domain/usecases/create_purchase_usecase.dart';
import 'package:sales_manager/features/purchases/presentation/cubit/create_purchase_cubit.dart';
import 'package:sales_manager/features/purchases/presentation/cubit/create_purchase_state.dart';

class MockCreatePurchaseUseCase extends Mock implements CreatePurchaseUseCase {}
class FakeCreatePurchaseParams extends Fake implements CreatePurchaseParams {}

void main() {
  late MockCreatePurchaseUseCase mockUseCase;

  setUpAll(() {
    registerFallbackValue(FakeCreatePurchaseParams());
  });

  setUp(() {
    mockUseCase = MockCreatePurchaseUseCase();
  });

  final dummyProduct = Product(
    id: 1,
    name: 'شاي العروسة',
    unit: 'عبوة',
    currentSalePrice: const Money(1500),
    currentPurchasePrice: const Money(1000),
    currentQuantity: Decimal.fromInt(20),
    createdAt: DateTime(2026, 9, 24),
  );

  group('CreatePurchaseCubit Tests', () {
    test('Initial state is CreatePurchaseInitial', () {
      final cubit = CreatePurchaseCubit(createPurchaseUseCase: mockUseCase);
      expect(cubit.state, const CreatePurchaseInitial());
      cubit.close();
    });

    blocTest<CreatePurchaseCubit, CreatePurchaseState>(
      'init emits CreatePurchaseEditing with default values',
      build: () => CreatePurchaseCubit(createPurchaseUseCase: mockUseCase),
      act: (cubit) => cubit.init(preselectedSupplierId: 5, preselectedSupplierName: 'شركة النيل'),
      expect: () => [
        isA<CreatePurchaseEditing>()
            .having((s) => s.supplierId, 'supplierId', 5)
            .having((s) => s.supplierName, 'supplierName', 'شركة النيل')
            .having((s) => s.items, 'items', isEmpty),
      ],
    );

    blocTest<CreatePurchaseCubit, CreatePurchaseState>(
      'addItem adds new item draft or increments existing item quantity',
      build: () => CreatePurchaseCubit(createPurchaseUseCase: mockUseCase),
      seed: () => CreatePurchaseEditing(purchaseDate: DateTime.now()),
      act: (cubit) {
        cubit.addItem(dummyProduct, quantity: Decimal.fromInt(2));
        cubit.addItem(dummyProduct, quantity: Decimal.fromInt(3)); // Total quantity should be 5
      },
      expect: () => [
        isA<CreatePurchaseEditing>().having((s) => s.items.length, 'length', 1).having((s) => s.items.first.quantity, 'qty', Decimal.fromInt(2)),
        isA<CreatePurchaseEditing>().having((s) => s.items.length, 'length', 1).having((s) => s.items.first.quantity, 'qty', Decimal.fromInt(5)),
      ],
    );

    blocTest<CreatePurchaseCubit, CreatePurchaseState>(
      'submitPurchase succeeds and emits CreatePurchaseSuccess',
      build: () {
        when(() => mockUseCase(any())).thenAnswer(
          (_) async => Success(
            Purchase(
              id: 99,
              invoiceNo: 200,
              supplierId: 1,
              purchaseDate: DateTime.now(),
              totalAmount: const Money(5000),
              paidAmountAtCreation: const Money(5000),
              createdAt: DateTime.now(),
            ),
          ),
        );
        return CreatePurchaseCubit(createPurchaseUseCase: mockUseCase);
      },
      seed: () => CreatePurchaseEditing(
        supplierId: 1,
        purchaseDate: DateTime.now(),
        items: [
          InvoiceItemDraft(
            productId: 1,
            productName: 'منتج',
            productUnit: 'قطعة',
            quantity: Decimal.one,
            unitCost: const Money(5000),
            currentStock: Decimal.ten,
          ),
        ],
      ),
      act: (cubit) => cubit.submitPurchase(),
      expect: () => [
        isA<CreatePurchaseEditing>().having((s) => s.isSubmitting, 'isSubmitting', isTrue),
        isA<CreatePurchaseSuccess>().having((s) => s.purchase.id, 'id', 99),
      ],
    );
  });
}
