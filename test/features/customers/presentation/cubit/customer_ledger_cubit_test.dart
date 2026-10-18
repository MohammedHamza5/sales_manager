import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/features/customers/domain/entities/customer_ledger_entry.dart';
import 'package:sales_manager/features/customers/domain/usecases/watch_customer_ledger_usecase.dart';
import 'package:sales_manager/features/customers/presentation/cubit/customer_ledger_cubit.dart';
import 'package:sales_manager/features/customers/presentation/cubit/customer_ledger_state.dart';

class MockWatchCustomerLedgerUseCase extends Mock
    implements WatchCustomerLedgerUseCase {}

void main() {
  late MockWatchCustomerLedgerUseCase mockWatch;

  final sampleEntries = [
    CustomerLedgerEntry(
      id: 1,
      customerId: 5,
      entryType: CustomerLedgerEntryType.openingBalance,
      amount: const Money.fromPiastres(10000), // 100.00 EGP debit
      effect: LedgerEffect.increase,
      balanceAfter: const Money.fromPiastres(10000),
      referenceType: 'opening_balance',
      referenceId: null,
      note: 'رصيد افتتاحي',
      createdAt: DateTime(2026, 1, 1),
      createdBy: 'admin',
    ),
    CustomerLedgerEntry(
      id: 2,
      customerId: 5,
      entryType: CustomerLedgerEntryType.sale,
      amount: const Money.fromPiastres(25000), // 250.00 EGP debit
      effect: LedgerEffect.increase,
      balanceAfter: const Money.fromPiastres(35000),
      referenceType: 'sale_invoice',
      referenceId: 101,
      note: 'فاتورة مبيعات آجل',
      createdAt: DateTime(2026, 1, 2),
      createdBy: 'admin',
    ),
    CustomerLedgerEntry(
      id: 3,
      customerId: 5,
      entryType: CustomerLedgerEntryType.payment,
      amount: const Money.fromPiastres(15000), // 150.00 EGP credit
      effect: LedgerEffect.decrease,
      balanceAfter: const Money.fromPiastres(20000),
      referenceType: 'cash_receipt',
      referenceId: 50,
      note: 'سداد نقدي من العميل',
      createdAt: DateTime(2026, 1, 3),
      createdBy: 'admin',
    ),
  ];

  setUp(() {
    mockWatch = MockWatchCustomerLedgerUseCase();
  });

  group('CustomerLedgerCubit Tests', () {
    test('Initial state is CustomerLedgerInitial', () {
      final cubit = CustomerLedgerCubit(
        watchCustomerLedgerUseCase: mockWatch,
        customerId: 5,
      );

      expect(cubit.state, const CustomerLedgerInitial());
      cubit.close();
    });

    blocTest<CustomerLedgerCubit, CustomerLedgerState>(
      'Emits [CustomerLedgerLoading, CustomerLedgerLoaded] and computes debit/credit/net correctly',
      build: () {
        when(() => mockWatch(5)).thenAnswer((_) => Stream.value(sampleEntries));
        return CustomerLedgerCubit(
          watchCustomerLedgerUseCase: mockWatch,
          customerId: 5,
        );
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        const CustomerLedgerLoading(),
        CustomerLedgerLoaded(entries: sampleEntries),
      ],
      verify: (cubit) {
        final state = cubit.state as CustomerLedgerLoaded;
        expect(state.totalDebit, const Money.fromPiastres(35000)); // 10000 + 25000
        expect(state.totalCredit, const Money.fromPiastres(15000)); // 15000
        expect(state.netBalance, const Money.fromPiastres(20000)); // 35000 - 15000
        expect(state.count, 3);
      },
    );

    blocTest<CustomerLedgerCubit, CustomerLedgerState>(
      'Emits [CustomerLedgerLoading, CustomerLedgerEmpty] when stream emits empty entries',
      build: () {
        when(() => mockWatch(5)).thenAnswer((_) => Stream.value([]));
        return CustomerLedgerCubit(
          watchCustomerLedgerUseCase: mockWatch,
          customerId: 5,
        );
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        const CustomerLedgerLoading(),
        const CustomerLedgerEmpty(
          message: 'لا توجد حركات مسجلة بكشف حساب العميل حتى الآن',
          hasFilter: false,
        ),
      ],
    );

    blocTest<CustomerLedgerCubit, CustomerLedgerState>(
      'Emits [CustomerLedgerLoading, CustomerLedgerError] when stream throws error',
      build: () {
        when(() => mockWatch(5)).thenAnswer(
          (_) => Stream.error(Exception('DB Read Error')),
        );
        return CustomerLedgerCubit(
          watchCustomerLedgerUseCase: mockWatch,
          customerId: 5,
        );
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        const CustomerLedgerLoading(),
        const CustomerLedgerError(
          message: 'فشل في تحميل كشف الحساب: Exception: DB Read Error',
        ),
      ],
    );

    blocTest<CustomerLedgerCubit, CustomerLedgerState>(
      'setFilterType filters entries correctly in loaded state',
      build: () => CustomerLedgerCubit(
        watchCustomerLedgerUseCase: mockWatch,
        customerId: 5,
      ),
      seed: () => CustomerLedgerLoaded(entries: sampleEntries),
      act: (cubit) => cubit.setFilterType(CustomerLedgerEntryType.payment),
      expect: () => [
        CustomerLedgerLoaded(
          entries: sampleEntries,
          filterEntryType: CustomerLedgerEntryType.payment,
        ),
      ],
      verify: (cubit) {
        final state = cubit.state as CustomerLedgerLoaded;
        expect(state.filteredEntries.length, 1);
        expect(state.filteredEntries.first.entryType, CustomerLedgerEntryType.payment);
        expect(state.count, 1);
      },
    );
  });
}
