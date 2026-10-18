import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/features/suppliers/domain/entities/supplier_ledger_entry.dart';
import 'package:sales_manager/features/suppliers/domain/usecases/watch_supplier_ledger_usecase.dart';
import 'package:sales_manager/features/suppliers/presentation/cubit/supplier_ledger_cubit.dart';
import 'package:sales_manager/features/suppliers/presentation/cubit/supplier_ledger_state.dart';

class MockWatchSupplierLedgerUseCase extends Mock
    implements WatchSupplierLedgerUseCase {}

void main() {
  late MockWatchSupplierLedgerUseCase mockWatch;

  final sampleEntries = [
    SupplierLedgerEntry(
      id: 1,
      supplierId: 5,
      entryType: SupplierLedgerEntryType.openingBalance,
      amount: const Money.fromPiastres(100000), // 1000.00 EGP credit (due to supplier)
      effect: SupplierLedgerEffect.increase,
      balanceAfter: const Money.fromPiastres(100000),
      referenceType: 'opening_balance',
      referenceId: null,
      note: 'رصيد افتتاحي',
      createdAt: DateTime(2026, 1, 1),
      createdBy: 'admin',
    ),
    SupplierLedgerEntry(
      id: 2,
      supplierId: 5,
      entryType: SupplierLedgerEntryType.purchase,
      amount: const Money.fromPiastres(250000), // 2500.00 EGP credit
      effect: SupplierLedgerEffect.increase,
      balanceAfter: const Money.fromPiastres(350000),
      referenceType: 'purchase_invoice',
      referenceId: 101,
      note: 'فاتورة توريد بضاعة',
      createdAt: DateTime(2026, 1, 2),
      createdBy: 'admin',
    ),
    SupplierLedgerEntry(
      id: 3,
      supplierId: 5,
      entryType: SupplierLedgerEntryType.payment,
      amount: const Money.fromPiastres(150000), // 1500.00 EGP debit (paid to supplier)
      effect: SupplierLedgerEffect.decrease,
      balanceAfter: const Money.fromPiastres(200000),
      referenceType: 'payment_voucher',
      referenceId: 50,
      note: 'سند صرف نقدية للمورد',
      createdAt: DateTime(2026, 1, 3),
      createdBy: 'admin',
    ),
  ];

  setUp(() {
    mockWatch = MockWatchSupplierLedgerUseCase();
  });

  group('SupplierLedgerCubit Tests', () {
    test('Initial state is SupplierLedgerInitial', () {
      final cubit = SupplierLedgerCubit(
        watchSupplierLedgerUseCase: mockWatch,
        supplierId: 5,
      );

      expect(cubit.state, const SupplierLedgerInitial());
      cubit.close();
    });

    blocTest<SupplierLedgerCubit, SupplierLedgerState>(
      'Emits [SupplierLedgerLoading, SupplierLedgerLoaded] and computes credit/debit/net correctly',
      build: () {
        when(() => mockWatch(5)).thenAnswer((_) => Stream.value(sampleEntries));
        return SupplierLedgerCubit(
          watchSupplierLedgerUseCase: mockWatch,
          supplierId: 5,
        );
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        const SupplierLedgerLoading(),
        SupplierLedgerLoaded(entries: sampleEntries),
      ],
      verify: (cubit) {
        final state = cubit.state as SupplierLedgerLoaded;
        expect(state.totalCredit, const Money.fromPiastres(350000)); // 100000 + 250000
        expect(state.totalDebit, const Money.fromPiastres(150000)); // 150000
        expect(state.netBalance, const Money.fromPiastres(200000)); // 350000 - 150000
        expect(state.count, 3);
      },
    );

    blocTest<SupplierLedgerCubit, SupplierLedgerState>(
      'Emits [SupplierLedgerLoading, SupplierLedgerEmpty] when stream emits empty entries',
      build: () {
        when(() => mockWatch(5)).thenAnswer((_) => Stream.value([]));
        return SupplierLedgerCubit(
          watchSupplierLedgerUseCase: mockWatch,
          supplierId: 5,
        );
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        const SupplierLedgerLoading(),
        const SupplierLedgerEmpty(
          message: 'لا توجد حركات مسجلة بكشف حساب المورد حتى الآن',
          hasFilter: false,
        ),
      ],
    );

    blocTest<SupplierLedgerCubit, SupplierLedgerState>(
      'Emits [SupplierLedgerLoading, SupplierLedgerError] when stream throws error',
      build: () {
        when(() => mockWatch(5)).thenAnswer(
          (_) => Stream.error(Exception('DB Read Error')),
        );
        return SupplierLedgerCubit(
          watchSupplierLedgerUseCase: mockWatch,
          supplierId: 5,
        );
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        const SupplierLedgerLoading(),
        const SupplierLedgerError(
          message: 'فشل في تحميل كشف الحساب: Exception: DB Read Error',
        ),
      ],
    );

    blocTest<SupplierLedgerCubit, SupplierLedgerState>(
      'setFilterType filters entries correctly in loaded state',
      build: () => SupplierLedgerCubit(
        watchSupplierLedgerUseCase: mockWatch,
        supplierId: 5,
      ),
      seed: () => SupplierLedgerLoaded(entries: sampleEntries),
      act: (cubit) => cubit.setFilterType(SupplierLedgerEntryType.payment),
      expect: () => [
        SupplierLedgerLoaded(
          entries: sampleEntries,
          filterEntryType: SupplierLedgerEntryType.payment,
        ),
      ],
      verify: (cubit) {
        final state = cubit.state as SupplierLedgerLoaded;
        expect(state.filteredEntries.length, 1);
        expect(state.filteredEntries.first.entryType, SupplierLedgerEntryType.payment);
        expect(state.count, 1);
      },
    );
  });
}
