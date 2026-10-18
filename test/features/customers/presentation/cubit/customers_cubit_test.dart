import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/result/result.dart';
import 'package:sales_manager/features/customers/domain/entities/customer.dart';
import 'package:sales_manager/features/customers/domain/usecases/add_customer_usecase.dart';
import 'package:sales_manager/features/customers/domain/usecases/toggle_customer_status_usecase.dart';
import 'package:sales_manager/features/customers/domain/usecases/update_customer_usecase.dart';
import 'package:sales_manager/features/customers/domain/usecases/watch_customers_usecase.dart';
import 'package:sales_manager/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:sales_manager/features/customers/presentation/cubit/customers_state.dart';

class MockWatchCustomersUseCase extends Mock implements WatchCustomersUseCase {}

class MockAddCustomerUseCase extends Mock implements AddCustomerUseCase {}

class MockUpdateCustomerUseCase extends Mock implements UpdateCustomerUseCase {}

class MockToggleCustomerStatusUseCase extends Mock
    implements ToggleCustomerStatusUseCase {}

void main() {
  late MockWatchCustomersUseCase mockWatch;
  late MockAddCustomerUseCase mockAdd;
  late MockUpdateCustomerUseCase mockUpdate;
  late MockToggleCustomerStatusUseCase mockToggle;

  final sampleCustomers = [
    Customer(
      id: 1,
      name: 'محمود أحمد',
      phone: '01011111111',
      address: 'شارع التحرير، القاهرة',
      notes: 'عميل مميز',
      currentBalance: const Money.fromPiastres(15000), // 150.00 EGP debt
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
      createdBy: 'admin',
    ),
    Customer(
      id: 2,
      name: 'سارة إبراهيم',
      phone: '01022222222',
      address: 'المعادي',
      notes: null,
      currentBalance: Money.zero, // Settled
      isActive: true,
      createdAt: DateTime(2026, 1, 2),
      createdBy: 'admin',
    ),
    Customer(
      id: 3,
      name: 'شركة النور',
      phone: '01033333333',
      address: 'مدينة نصر',
      notes: 'معطل مؤقتا',
      currentBalance: const Money.fromPiastres(25000), // 250.00 EGP debt
      isActive: false,
      createdAt: DateTime(2026, 1, 3),
      createdBy: 'admin',
    ),
  ];

  setUp(() {
    mockWatch = MockWatchCustomersUseCase();
    mockAdd = MockAddCustomerUseCase();
    mockUpdate = MockUpdateCustomerUseCase();
    mockToggle = MockToggleCustomerStatusUseCase();
  });

  group('CustomersCubit Tests', () {
    test('Initial state is CustomersInitial', () {
      final cubit = CustomersCubit(
        watchCustomersUseCase: mockWatch,
        addCustomerUseCase: mockAdd,
        updateCustomerUseCase: mockUpdate,
        toggleCustomerStatusUseCase: mockToggle,
      );

      expect(cubit.state, const CustomersInitial());
      cubit.close();
    });

    blocTest<CustomersCubit, CustomersState>(
      'Emits [CustomersLoading, CustomersLoaded] and computes KPIs correctly when stream emits customers',
      build: () {
        when(() => mockWatch()).thenAnswer((_) => Stream.value(sampleCustomers));
        return CustomersCubit(
          watchCustomersUseCase: mockWatch,
          addCustomerUseCase: mockAdd,
          updateCustomerUseCase: mockUpdate,
          toggleCustomerStatusUseCase: mockToggle,
        );
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        const CustomersLoading(),
        CustomersLoaded(
          customers: sampleCustomers,
          totalDebtAmount: const Money.fromPiastres(40000), // 15000 + 25000
          totalDebtorsCount: 2,
        ),
      ],
    );

    blocTest<CustomersCubit, CustomersState>(
      'Emits [CustomersLoading, CustomersEmpty] when stream emits empty list',
      build: () {
        when(() => mockWatch()).thenAnswer((_) => Stream.value([]));
        return CustomersCubit(
          watchCustomersUseCase: mockWatch,
          addCustomerUseCase: mockAdd,
          updateCustomerUseCase: mockUpdate,
          toggleCustomerStatusUseCase: mockToggle,
        );
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        const CustomersLoading(),
        const CustomersEmpty(
          message: 'لا يوجد عملاء مسجلون بالنظام حتى الآن',
          hasActiveFilters: false,
        ),
      ],
    );

    blocTest<CustomersCubit, CustomersState>(
      'Emits [CustomersLoading, CustomersError] when stream throws error',
      build: () {
        when(() => mockWatch()).thenAnswer(
          (_) => Stream.error(Exception('Database error occurred')),
        );
        return CustomersCubit(
          watchCustomersUseCase: mockWatch,
          addCustomerUseCase: mockAdd,
          updateCustomerUseCase: mockUpdate,
          toggleCustomerStatusUseCase: mockToggle,
        );
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        const CustomersLoading(),
        const CustomersError(message: 'Exception: Database error occurred'),
      ],
    );

    blocTest<CustomersCubit, CustomersState>(
      'search updates searchQuery in CustomersLoaded state',
      build: () => CustomersCubit(
        watchCustomersUseCase: mockWatch,
        addCustomerUseCase: mockAdd,
        updateCustomerUseCase: mockUpdate,
        toggleCustomerStatusUseCase: mockToggle,
      ),
      seed: () => CustomersLoaded(
        customers: sampleCustomers,
        totalDebtAmount: const Money.fromPiastres(40000),
        totalDebtorsCount: 2,
      ),
      act: (cubit) => cubit.search('سارة'),
      expect: () => [
        CustomersLoaded(
          customers: sampleCustomers,
          searchQuery: 'سارة',
          totalDebtAmount: const Money.fromPiastres(40000),
          totalDebtorsCount: 2,
        ),
      ],
      verify: (cubit) {
        final state = cubit.state as CustomersLoaded;
        expect(state.filteredCustomers.length, 1);
        expect(state.filteredCustomers.first.name, 'سارة إبراهيم');
      },
    );

    blocTest<CustomersCubit, CustomersState>(
      'toggleDebtorsFilter toggles showDebtorsOnly and filters customers correctly',
      build: () => CustomersCubit(
        watchCustomersUseCase: mockWatch,
        addCustomerUseCase: mockAdd,
        updateCustomerUseCase: mockUpdate,
        toggleCustomerStatusUseCase: mockToggle,
      ),
      seed: () => CustomersLoaded(
        customers: sampleCustomers,
        totalDebtAmount: const Money.fromPiastres(40000),
        totalDebtorsCount: 2,
      ),
      act: (cubit) => cubit.toggleDebtorsFilter(),
      expect: () => [
        CustomersLoaded(
          customers: sampleCustomers,
          showDebtorsOnly: true,
          totalDebtAmount: const Money.fromPiastres(40000),
          totalDebtorsCount: 2,
        ),
      ],
      verify: (cubit) {
        final state = cubit.state as CustomersLoaded;
        // activeFilter is default true, so only active customers with debt (Customer 1)
        expect(state.filteredCustomers.length, 1);
        expect(state.filteredCustomers.first.name, 'محمود أحمد');
      },
    );

    blocTest<CustomersCubit, CustomersState>(
      'setActiveFilter alters activeFilter criteria (null, false, true)',
      build: () => CustomersCubit(
        watchCustomersUseCase: mockWatch,
        addCustomerUseCase: mockAdd,
        updateCustomerUseCase: mockUpdate,
        toggleCustomerStatusUseCase: mockToggle,
      ),
      seed: () => CustomersLoaded(
        customers: sampleCustomers,
        totalDebtAmount: const Money.fromPiastres(40000),
        totalDebtorsCount: 2,
      ),
      act: (cubit) => cubit.setActiveFilter(false), // Only deactivated
      expect: () => [
        CustomersLoaded(
          customers: sampleCustomers,
          activeFilter: false,
          totalDebtAmount: const Money.fromPiastres(40000),
          totalDebtorsCount: 2,
        ),
      ],
      verify: (cubit) {
        final state = cubit.state as CustomersLoaded;
        expect(state.filteredCustomers.length, 1);
        expect(state.filteredCustomers.first.name, 'شركة النور');
      },
    );

    test('addCustomer delegates directly to AddCustomerUseCase', () async {
      when(() => mockAdd(
            name: 'عميل جديد',
            phone: '01099999999',
            address: 'طنطا',
            notes: 'ملاحظة',
            initialBalance: const Money.fromPiastres(5000),
            createdBy: 'admin',
          )).thenAnswer((_) async => Success(sampleCustomers.first));

      final cubit = CustomersCubit(
        watchCustomersUseCase: mockWatch,
        addCustomerUseCase: mockAdd,
        updateCustomerUseCase: mockUpdate,
        toggleCustomerStatusUseCase: mockToggle,
      );

      final result = await cubit.addCustomer(
        name: 'عميل جديد',
        phone: '01099999999',
        address: 'طنطا',
        notes: 'ملاحظة',
        initialBalance: const Money.fromPiastres(5000),
      );

      expect(result.isSuccess, isTrue);
      verify(() => mockAdd(
            name: 'عميل جديد',
            phone: '01099999999',
            address: 'طنطا',
            notes: 'ملاحظة',
            initialBalance: const Money.fromPiastres(5000),
            createdBy: 'admin',
          )).called(1);

      await cubit.close();
    });

    test('updateCustomer delegates directly to UpdateCustomerUseCase', () async {
      final updated = sampleCustomers.first.copyWith(name: 'محمود أحمد المعدل');
      when(() => mockUpdate(updated)).thenAnswer((_) async => Success(updated));

      final cubit = CustomersCubit(
        watchCustomersUseCase: mockWatch,
        addCustomerUseCase: mockAdd,
        updateCustomerUseCase: mockUpdate,
        toggleCustomerStatusUseCase: mockToggle,
      );

      final result = await cubit.updateCustomer(updated);

      expect(result.isSuccess, isTrue);
      verify(() => mockUpdate(updated)).called(1);

      await cubit.close();
    });

    test('toggleCustomerStatus delegates directly to ToggleCustomerStatusUseCase', () async {
      when(() => mockToggle(1, false)).thenAnswer((_) async => const Success(null));

      final cubit = CustomersCubit(
        watchCustomersUseCase: mockWatch,
        addCustomerUseCase: mockAdd,
        updateCustomerUseCase: mockUpdate,
        toggleCustomerStatusUseCase: mockToggle,
      );

      final result = await cubit.toggleCustomerStatus(1, false);

      expect(result.isSuccess, isTrue);
      verify(() => mockToggle(1, false)).called(1);

      await cubit.close();
    });
  });
}
