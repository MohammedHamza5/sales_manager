import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/result/failures.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/result/result.dart';
import 'package:sales_manager/features/customers/domain/entities/customer.dart';
import 'package:sales_manager/features/customers/domain/usecases/get_customers_usecase.dart';
import 'package:sales_manager/features/opening_balance/domain/entities/opening_balance_input.dart';
import 'package:sales_manager/features/opening_balance/domain/usecases/check_opening_balance_status_usecase.dart';
import 'package:sales_manager/features/opening_balance/domain/usecases/save_opening_balances_usecase.dart';
import 'package:sales_manager/features/opening_balance/presentation/cubit/opening_balance_cubit.dart';
import 'package:sales_manager/features/opening_balance/presentation/cubit/opening_balance_state.dart';
import 'package:sales_manager/features/products/domain/entities/product.dart';
import 'package:sales_manager/features/products/domain/usecases/get_products_usecase.dart';
import 'package:sales_manager/features/suppliers/domain/entities/supplier.dart';
import 'package:sales_manager/features/suppliers/domain/usecases/get_suppliers_usecase.dart';

class MockCheckOpeningBalanceStatusUseCase extends Mock
    implements CheckOpeningBalanceStatusUseCase {}

class MockSaveOpeningBalancesUseCase extends Mock
    implements SaveOpeningBalancesUseCase {}

class MockGetProductsUseCase extends Mock implements GetProductsUseCase {}

class MockGetCustomersUseCase extends Mock implements GetCustomersUseCase {}

class MockGetSuppliersUseCase extends Mock implements GetSuppliersUseCase {}

class FakeOpeningBalanceInput extends Fake implements OpeningBalanceInput {}

void main() {
  late MockCheckOpeningBalanceStatusUseCase mockCheckStatus;
  late MockSaveOpeningBalancesUseCase mockSave;
  late MockGetProductsUseCase mockGetProducts;
  late MockGetCustomersUseCase mockGetCustomers;
  late MockGetSuppliersUseCase mockGetSuppliers;
  late OpeningBalanceCubit cubit;

  final sampleProducts = [
    Product(
      id: 1,
      name: 'أرز أبيض فاخر',
      code: 'RICE-01',
      unit: 'شيكارة',
      currentSalePrice: const Money.fromPiastres(35000),
      currentPurchasePrice: const Money.fromPiastres(30000),
      currentQuantity: Decimal.zero,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  final sampleCustomers = [
    Customer(
      id: 10,
      name: 'عميل تجريبي',
      phone: '01012345678',
      currentBalance: Money.zero,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  final sampleSuppliers = [
    Supplier(
      id: 20,
      name: 'مورد تجريبي',
      phone: '01212345678',
      currentBalance: Money.zero,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  setUpAll(() {
    registerFallbackValue(FakeOpeningBalanceInput());
  });

  setUp(() {
    mockCheckStatus = MockCheckOpeningBalanceStatusUseCase();
    mockSave = MockSaveOpeningBalancesUseCase();
    mockGetProducts = MockGetProductsUseCase();
    mockGetCustomers = MockGetCustomersUseCase();
    mockGetSuppliers = MockGetSuppliersUseCase();

    cubit = OpeningBalanceCubit(
      checkStatusUseCase: mockCheckStatus,
      saveOpeningBalancesUseCase: mockSave,
      getProductsUseCase: mockGetProducts,
      getCustomersUseCase: mockGetCustomers,
      getSuppliersUseCase: mockGetSuppliers,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('OpeningBalanceCubit Tests', () {
    test('Initial state is OpeningBalanceInitial', () {
      expect(cubit.state, const OpeningBalanceInitial());
    });

    blocTest<OpeningBalanceCubit, OpeningBalanceState>(
      'init() emits [OpeningBalanceLoading, OpeningBalanceAlreadySaved] when already saved',
      build: () {
        when(() => mockCheckStatus()).thenAnswer((_) async => const Success(true));
        return cubit;
      },
      act: (c) => c.init(),
      expect: () => [
        const OpeningBalanceLoading(),
        const OpeningBalanceAlreadySaved(),
      ],
      verify: (_) {
        verify(() => mockCheckStatus()).called(1);
        verifyNever(() => mockGetProducts(isActiveOnly: any(named: 'isActiveOnly')));
      },
    );

    blocTest<OpeningBalanceCubit, OpeningBalanceState>(
      'init() loads products, customers, suppliers and emits [OpeningBalanceLoading, OpeningBalanceReady]',
      build: () {
        when(() => mockCheckStatus()).thenAnswer((_) async => const Success(false));
        when(() => mockGetProducts(isActiveOnly: true))
            .thenAnswer((_) async => Success(sampleProducts));
        when(() => mockGetCustomers(isActiveOnly: true))
            .thenAnswer((_) async => Success(sampleCustomers));
        when(() => mockGetSuppliers(isActiveOnly: true))
            .thenAnswer((_) async => Success(sampleSuppliers));
        return cubit;
      },
      act: (c) => c.init(),
      expect: () => [
        const OpeningBalanceLoading(),
        isA<OpeningBalanceReady>().having(
          (s) => s.input.products.length,
          'products length',
          1,
        ).having(
          (s) => s.input.customers.length,
          'customers length',
          1,
        ).having(
          (s) => s.input.suppliers.length,
          'suppliers length',
          1,
        ).having(
          (s) => s.input.cashboxBalance,
          'cashbox balance',
          Money.zero,
        ),
      ],
    );

    blocTest<OpeningBalanceCubit, OpeningBalanceState>(
      'init() emits OpeningBalanceError when product loading fails',
      build: () {
        when(() => mockCheckStatus()).thenAnswer((_) async => const Success(false));
        when(() => mockGetProducts(isActiveOnly: true))
            .thenAnswer((_) async => const FailureResult(DatabaseFailure(message: 'Database error products')));
        when(() => mockGetCustomers(isActiveOnly: true))
            .thenAnswer((_) async => Success(sampleCustomers));
        when(() => mockGetSuppliers(isActiveOnly: true))
            .thenAnswer((_) async => Success(sampleSuppliers));
        return cubit;
      },
      act: (c) => c.init(),
      expect: () => [
        const OpeningBalanceLoading(),
        const OpeningBalanceError(message: 'Database error products'),
      ],
    );

    blocTest<OpeningBalanceCubit, OpeningBalanceState>(
      'init() emits OpeningBalanceError when customer loading fails',
      build: () {
        when(() => mockCheckStatus()).thenAnswer((_) async => const Success(false));
        when(() => mockGetProducts(isActiveOnly: true))
            .thenAnswer((_) async => Success(sampleProducts));
        when(() => mockGetCustomers(isActiveOnly: true))
            .thenAnswer((_) async => const FailureResult(DatabaseFailure(message: 'Database error customers')));
        when(() => mockGetSuppliers(isActiveOnly: true))
            .thenAnswer((_) async => Success(sampleSuppliers));
        return cubit;
      },
      act: (c) => c.init(),
      expect: () => [
        const OpeningBalanceLoading(),
        const OpeningBalanceError(message: 'Database error customers'),
      ],
    );

    blocTest<OpeningBalanceCubit, OpeningBalanceState>(
      'init() emits OpeningBalanceError when supplier loading fails',
      build: () {
        when(() => mockCheckStatus()).thenAnswer((_) async => const Success(false));
        when(() => mockGetProducts(isActiveOnly: true))
            .thenAnswer((_) async => Success(sampleProducts));
        when(() => mockGetCustomers(isActiveOnly: true))
            .thenAnswer((_) async => Success(sampleCustomers));
        when(() => mockGetSuppliers(isActiveOnly: true))
            .thenAnswer((_) async => const FailureResult(DatabaseFailure(message: 'Database error suppliers')));
        return cubit;
      },
      act: (c) => c.init(),
      expect: () => [
        const OpeningBalanceLoading(),
        const OpeningBalanceError(message: 'Database error suppliers'),
      ],
    );

    blocTest<OpeningBalanceCubit, OpeningBalanceState>(
      'updates tab, cashbox, products, customers, suppliers accurately',
      build: () {
        when(() => mockCheckStatus()).thenAnswer((_) async => const Success(false));
        when(() => mockGetProducts(isActiveOnly: true))
            .thenAnswer((_) async => Success(sampleProducts));
        when(() => mockGetCustomers(isActiveOnly: true))
            .thenAnswer((_) async => Success(sampleCustomers));
        when(() => mockGetSuppliers(isActiveOnly: true))
            .thenAnswer((_) async => Success(sampleSuppliers));
        return cubit;
      },
      act: (c) async {
        await c.init();
        c.setTab(1);
        c.setCashboxBalance(const Money.fromPiastres(50000));
        c.updateProductQuantity(1, Decimal.fromInt(25));
        c.updateCustomerBalance(10, const Money.fromPiastres(12000));
        c.updateSupplierBalance(20, const Money.fromPiastres(18000));
      },
      skip: 2, // Skip Loading and initial Ready
      expect: () => [
        // setTab(1)
        isA<OpeningBalanceReady>().having((s) => s.activeTabIndex, 'tab', 1),
        // setCashboxBalance(500.00 EGP)
        isA<OpeningBalanceReady>().having(
          (s) => s.input.cashboxBalance,
          'cashbox',
          const Money.fromPiastres(50000),
        ),
        // updateProductQuantity(1, 25)
        isA<OpeningBalanceReady>().having(
          (s) => s.input.products.first.initialQuantity,
          'product qty',
          Decimal.fromInt(25),
        ),
        // updateCustomerBalance(10, 120.00 EGP)
        isA<OpeningBalanceReady>().having(
          (s) => s.input.customers.first.balance,
          'customer balance',
          const Money.fromPiastres(12000),
        ),
        // updateSupplierBalance(20, 180.00 EGP)
        isA<OpeningBalanceReady>().having(
          (s) => s.input.suppliers.first.balance,
          'supplier balance',
          const Money.fromPiastres(18000),
        ),
      ],
    );

    blocTest<OpeningBalanceCubit, OpeningBalanceState>(
      'submit() emits [isSubmitting: true, OpeningBalanceSuccess] when repository succeeds',
      build: () {
        when(() => mockCheckStatus()).thenAnswer((_) async => const Success(false));
        when(() => mockGetProducts(isActiveOnly: true))
            .thenAnswer((_) async => Success(sampleProducts));
        when(() => mockGetCustomers(isActiveOnly: true))
            .thenAnswer((_) async => Success(sampleCustomers));
        when(() => mockGetSuppliers(isActiveOnly: true))
            .thenAnswer((_) async => Success(sampleSuppliers));
        when(() => mockSave(any(), createdBy: any(named: 'createdBy')))
            .thenAnswer((_) async => const Success(null));
        return cubit;
      },
      act: (c) async {
        await c.init();
        await c.submit(createdBy: 'kimo');
      },
      skip: 2, // Skip Loading and initial Ready
      expect: () => [
        isA<OpeningBalanceReady>().having((s) => s.isSubmitting, 'isSubmitting', true),
        const OpeningBalanceSuccess(),
      ],
      verify: (_) {
        verify(() => mockSave(any(), createdBy: 'kimo')).called(1);
      },
    );

    blocTest<OpeningBalanceCubit, OpeningBalanceState>(
      'submit() emits [isSubmitting: true, isSubmitting: false, submitError: ...] when repository fails',
      build: () {
        when(() => mockCheckStatus()).thenAnswer((_) async => const Success(false));
        when(() => mockGetProducts(isActiveOnly: true))
            .thenAnswer((_) async => Success(sampleProducts));
        when(() => mockGetCustomers(isActiveOnly: true))
            .thenAnswer((_) async => Success(sampleCustomers));
        when(() => mockGetSuppliers(isActiveOnly: true))
            .thenAnswer((_) async => Success(sampleSuppliers));
        when(() => mockSave(any(), createdBy: any(named: 'createdBy')))
            .thenAnswer((_) async => const FailureResult(ValidationFailure(field: 'cashbox', message: 'قيمة غير صالحة')));
        return cubit;
      },
      act: (c) async {
        await c.init();
        await c.submit();
      },
      skip: 2, // Skip Loading and initial Ready
      expect: () => [
        isA<OpeningBalanceReady>().having((s) => s.isSubmitting, 'isSubmitting', true),
        isA<OpeningBalanceReady>()
            .having((s) => s.isSubmitting, 'isSubmitting', false)
            .having((s) => s.submitError, 'submitError', 'قيمة غير صالحة'),
      ],
    );
  });
}
