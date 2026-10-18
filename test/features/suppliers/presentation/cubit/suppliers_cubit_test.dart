import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/result/result.dart';
import 'package:sales_manager/features/suppliers/domain/entities/supplier.dart';
import 'package:sales_manager/features/suppliers/domain/usecases/add_supplier_usecase.dart';
import 'package:sales_manager/features/suppliers/domain/usecases/toggle_supplier_status_usecase.dart';
import 'package:sales_manager/features/suppliers/domain/usecases/update_supplier_usecase.dart';
import 'package:sales_manager/features/suppliers/domain/usecases/watch_suppliers_usecase.dart';
import 'package:sales_manager/features/suppliers/presentation/cubit/suppliers_cubit.dart';
import 'package:sales_manager/features/suppliers/presentation/cubit/suppliers_state.dart';

class MockWatchSuppliersUseCase extends Mock implements WatchSuppliersUseCase {}

class MockAddSupplierUseCase extends Mock implements AddSupplierUseCase {}

class MockUpdateSupplierUseCase extends Mock implements UpdateSupplierUseCase {}

class MockToggleSupplierStatusUseCase extends Mock
    implements ToggleSupplierStatusUseCase {}

void main() {
  late MockWatchSuppliersUseCase mockWatch;
  late MockAddSupplierUseCase mockAdd;
  late MockUpdateSupplierUseCase mockUpdate;
  late MockToggleSupplierStatusUseCase mockToggle;

  final sampleSuppliers = [
    Supplier(
      id: 1,
      name: 'شركة الأمل للتوريدات',
      phone: '01011111111',
      address: 'المنطقة الصناعية، العاشر من رمضان',
      notes: 'مورد رئيسي للبضائع',
      currentBalance: const Money.fromPiastres(150000), // 1500.00 EGP due to them
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
      createdBy: 'admin',
    ),
    Supplier(
      id: 2,
      name: 'مؤسسة السلام',
      phone: '01022222222',
      address: 'العتبة، القاهرة',
      notes: null,
      currentBalance: Money.zero, // Settled
      isActive: true,
      createdAt: DateTime(2026, 1, 2),
      createdBy: 'admin',
    ),
    Supplier(
      id: 3,
      name: 'مصنع الأهرام',
      phone: '01033333333',
      address: 'حلوان',
      notes: 'معطل مؤقتا',
      currentBalance: const Money.fromPiastres(250000), // 2500.00 EGP due to them
      isActive: false,
      createdAt: DateTime(2026, 1, 3),
      createdBy: 'admin',
    ),
  ];

  setUp(() {
    mockWatch = MockWatchSuppliersUseCase();
    mockAdd = MockAddSupplierUseCase();
    mockUpdate = MockUpdateSupplierUseCase();
    mockToggle = MockToggleSupplierStatusUseCase();
  });

  group('SuppliersCubit Tests', () {
    test('Initial state is SuppliersInitial', () {
      final cubit = SuppliersCubit(
        watchSuppliersUseCase: mockWatch,
        addSupplierUseCase: mockAdd,
        updateSupplierUseCase: mockUpdate,
        toggleSupplierStatusUseCase: mockToggle,
      );

      expect(cubit.state, const SuppliersInitial());
      cubit.close();
    });

    blocTest<SuppliersCubit, SuppliersState>(
      'Emits [SuppliersLoading, SuppliersLoaded] and computes KPIs correctly when stream emits suppliers',
      build: () {
        when(() => mockWatch()).thenAnswer((_) => Stream.value(sampleSuppliers));
        return SuppliersCubit(
          watchSuppliersUseCase: mockWatch,
          addSupplierUseCase: mockAdd,
          updateSupplierUseCase: mockUpdate,
          toggleSupplierStatusUseCase: mockToggle,
        );
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        const SuppliersLoading(),
        SuppliersLoaded(
          suppliers: sampleSuppliers,
          totalDueAmount: const Money.fromPiastres(400000), // 150000 + 250000
          totalDueSuppliersCount: 2,
        ),
      ],
    );

    blocTest<SuppliersCubit, SuppliersState>(
      'Emits [SuppliersLoading, SuppliersEmpty] when stream emits empty list',
      build: () {
        when(() => mockWatch()).thenAnswer((_) => Stream.value([]));
        return SuppliersCubit(
          watchSuppliersUseCase: mockWatch,
          addSupplierUseCase: mockAdd,
          updateSupplierUseCase: mockUpdate,
          toggleSupplierStatusUseCase: mockToggle,
        );
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        const SuppliersLoading(),
        const SuppliersEmpty(
          message: 'لا يوجد موردون مسجلون بالنظام حتى الآن',
          hasActiveFilters: false,
        ),
      ],
    );

    blocTest<SuppliersCubit, SuppliersState>(
      'Emits [SuppliersLoading, SuppliersError] when stream throws error',
      build: () {
        when(() => mockWatch()).thenAnswer(
          (_) => Stream.error(Exception('Database error occurred')),
        );
        return SuppliersCubit(
          watchSuppliersUseCase: mockWatch,
          addSupplierUseCase: mockAdd,
          updateSupplierUseCase: mockUpdate,
          toggleSupplierStatusUseCase: mockToggle,
        );
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        const SuppliersLoading(),
        const SuppliersError(message: 'Exception: Database error occurred'),
      ],
    );

    blocTest<SuppliersCubit, SuppliersState>(
      'search updates searchQuery in SuppliersLoaded state',
      build: () => SuppliersCubit(
        watchSuppliersUseCase: mockWatch,
        addSupplierUseCase: mockAdd,
        updateSupplierUseCase: mockUpdate,
        toggleSupplierStatusUseCase: mockToggle,
      ),
      seed: () => SuppliersLoaded(
        suppliers: sampleSuppliers,
        totalDueAmount: const Money.fromPiastres(400000),
        totalDueSuppliersCount: 2,
      ),
      act: (cubit) => cubit.search('السلام'),
      expect: () => [
        SuppliersLoaded(
          suppliers: sampleSuppliers,
          searchQuery: 'السلام',
          totalDueAmount: const Money.fromPiastres(400000),
          totalDueSuppliersCount: 2,
        ),
      ],
      verify: (cubit) {
        final state = cubit.state as SuppliersLoaded;
        expect(state.filteredSuppliers.length, 1);
        expect(state.filteredSuppliers.first.name, 'مؤسسة السلام');
      },
    );

    blocTest<SuppliersCubit, SuppliersState>(
      'toggleDueFilter toggles showDueOnly and filters suppliers correctly',
      build: () => SuppliersCubit(
        watchSuppliersUseCase: mockWatch,
        addSupplierUseCase: mockAdd,
        updateSupplierUseCase: mockUpdate,
        toggleSupplierStatusUseCase: mockToggle,
      ),
      seed: () => SuppliersLoaded(
        suppliers: sampleSuppliers,
        totalDueAmount: const Money.fromPiastres(400000),
        totalDueSuppliersCount: 2,
      ),
      act: (cubit) => cubit.toggleDueFilter(),
      expect: () => [
        SuppliersLoaded(
          suppliers: sampleSuppliers,
          showDueOnly: true,
          totalDueAmount: const Money.fromPiastres(400000),
          totalDueSuppliersCount: 2,
        ),
      ],
      verify: (cubit) {
        final state = cubit.state as SuppliersLoaded;
        // activeFilter is default true, so only active suppliers with due balance (Supplier 1)
        expect(state.filteredSuppliers.length, 1);
        expect(state.filteredSuppliers.first.name, 'شركة الأمل للتوريدات');
      },
    );

    blocTest<SuppliersCubit, SuppliersState>(
      'setActiveFilter alters activeFilter criteria (null, false, true)',
      build: () => SuppliersCubit(
        watchSuppliersUseCase: mockWatch,
        addSupplierUseCase: mockAdd,
        updateSupplierUseCase: mockUpdate,
        toggleSupplierStatusUseCase: mockToggle,
      ),
      seed: () => SuppliersLoaded(
        suppliers: sampleSuppliers,
        totalDueAmount: const Money.fromPiastres(400000),
        totalDueSuppliersCount: 2,
      ),
      act: (cubit) => cubit.setActiveFilter(false), // Only deactivated
      expect: () => [
        SuppliersLoaded(
          suppliers: sampleSuppliers,
          activeFilter: false,
          totalDueAmount: const Money.fromPiastres(400000),
          totalDueSuppliersCount: 2,
        ),
      ],
      verify: (cubit) {
        final state = cubit.state as SuppliersLoaded;
        expect(state.filteredSuppliers.length, 1);
        expect(state.filteredSuppliers.first.name, 'مصنع الأهرام');
      },
    );

    test('addSupplier delegates directly to AddSupplierUseCase', () async {
      when(() => mockAdd(
            name: 'مورد جديد',
            phone: '01099999999',
            address: 'طنطا',
            notes: 'ملاحظة',
            initialBalance: const Money.fromPiastres(50000),
            createdBy: 'admin',
          )).thenAnswer((_) async => Success(sampleSuppliers.first));

      final cubit = SuppliersCubit(
        watchSuppliersUseCase: mockWatch,
        addSupplierUseCase: mockAdd,
        updateSupplierUseCase: mockUpdate,
        toggleSupplierStatusUseCase: mockToggle,
      );

      final result = await cubit.addSupplier(
        name: 'مورد جديد',
        phone: '01099999999',
        address: 'طنطا',
        notes: 'ملاحظة',
        initialBalance: const Money.fromPiastres(50000),
      );

      expect(result.isSuccess, isTrue);
      verify(() => mockAdd(
            name: 'مورد جديد',
            phone: '01099999999',
            address: 'طنطا',
            notes: 'ملاحظة',
            initialBalance: const Money.fromPiastres(50000),
            createdBy: 'admin',
          )).called(1);

      await cubit.close();
    });

    test('updateSupplier delegates directly to UpdateSupplierUseCase', () async {
      final updated = sampleSuppliers.first.copyWith(name: 'شركة الأمل المعدلة');
      when(() => mockUpdate(updated)).thenAnswer((_) async => Success(updated));

      final cubit = SuppliersCubit(
        watchSuppliersUseCase: mockWatch,
        addSupplierUseCase: mockAdd,
        updateSupplierUseCase: mockUpdate,
        toggleSupplierStatusUseCase: mockToggle,
      );

      final result = await cubit.updateSupplier(updated);

      expect(result.isSuccess, isTrue);
      verify(() => mockUpdate(updated)).called(1);

      await cubit.close();
    });

    test('toggleSupplierStatus delegates directly to ToggleSupplierStatusUseCase', () async {
      when(() => mockToggle(1, false)).thenAnswer((_) async => const Success(null));

      final cubit = SuppliersCubit(
        watchSuppliersUseCase: mockWatch,
        addSupplierUseCase: mockAdd,
        updateSupplierUseCase: mockUpdate,
        toggleSupplierStatusUseCase: mockToggle,
      );

      final result = await cubit.toggleSupplierStatus(1, false);

      expect(result.isSuccess, isTrue);
      verify(() => mockToggle(1, false)).called(1);

      await cubit.close();
    });
  });
}
