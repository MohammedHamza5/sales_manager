import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/result/result.dart';
import 'package:sales_manager/features/supplier_payments/domain/entities/supplier_payment.dart';
import 'package:sales_manager/features/supplier_payments/domain/usecases/record_supplier_payment_usecase.dart';
import 'package:sales_manager/features/supplier_payments/domain/usecases/watch_supplier_payments_usecase.dart';
import 'package:sales_manager/features/supplier_payments/presentation/cubit/supplier_payments_cubit.dart';
import 'package:sales_manager/features/supplier_payments/presentation/cubit/supplier_payments_state.dart';

class MockRecordSupplierPaymentUseCase extends Mock
    implements RecordSupplierPaymentUseCase {}

class MockWatchSupplierPaymentsUseCase extends Mock
    implements WatchSupplierPaymentsUseCase {}

void main() {
  late MockRecordSupplierPaymentUseCase mockRecordPayment;
  late MockWatchSupplierPaymentsUseCase mockWatchPayments;

  setUp(() {
    mockRecordPayment = MockRecordSupplierPaymentUseCase();
    mockWatchPayments = MockWatchSupplierPaymentsUseCase();
  });

  group('SupplierPaymentsCubit Tests', () {
    test('Initial state is SupplierPaymentsInitial', () {
      final cubit = SupplierPaymentsCubit(
        recordPaymentUseCase: mockRecordPayment,
        watchPaymentsUseCase: mockWatchPayments,
      );
      expect(cubit.state, equals(const SupplierPaymentsInitial()));
      cubit.close();
    });

    blocTest<SupplierPaymentsCubit, SupplierPaymentsState>(
      'Emits [SupplierPaymentsLoading, SupplierPaymentsEmpty] when stream emits empty list',
      build: () {
        when(() => mockWatchPayments(supplierId: any(named: 'supplierId')))
            .thenAnswer((_) => Stream.value([]));
        return SupplierPaymentsCubit(
          recordPaymentUseCase: mockRecordPayment,
          watchPaymentsUseCase: mockWatchPayments,
        );
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        const SupplierPaymentsLoading(),
        const SupplierPaymentsEmpty(),
      ],
    );

    blocTest<SupplierPaymentsCubit, SupplierPaymentsState>(
      'Emits [SupplierPaymentsLoading, SupplierPaymentsLoaded] when stream emits payments',
      build: () {
        final payment = SupplierPayment(
          id: 1,
          supplierId: 20,
          supplierName: 'مورد الصدق',
          amount: const Money(6000),
          paymentDate: DateTime(2026, 9, 24),
          createdAt: DateTime(2026, 9, 24),
        );
        when(() => mockWatchPayments(supplierId: any(named: 'supplierId')))
            .thenAnswer((_) => Stream.value([payment]));
        return SupplierPaymentsCubit(
          recordPaymentUseCase: mockRecordPayment,
          watchPaymentsUseCase: mockWatchPayments,
        );
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        const SupplierPaymentsLoading(),
        isA<SupplierPaymentsLoaded>()
            .having((s) => s.allPayments.length, 'length', 1)
            .having((s) => s.totalPaid, 'totalPaid', const Money(6000)),
      ],
    );

    blocTest<SupplierPaymentsCubit, SupplierPaymentsState>(
      'Delegates recordPayment to usecase',
      build: () {
        final payment = SupplierPayment(
          id: 2,
          supplierId: 20,
          supplierName: 'مورد الصدق',
          amount: const Money(3500),
          paymentDate: DateTime(2026, 9, 24),
          createdAt: DateTime(2026, 9, 24),
        );
        when(() => mockRecordPayment(
              supplierId: 20,
              amount: const Money(3500),
              paymentDate: any(named: 'paymentDate'),
              linkedPurchaseId: null,
              note: null,
            )).thenAnswer((_) async => Success(payment));
        return SupplierPaymentsCubit(
          recordPaymentUseCase: mockRecordPayment,
          watchPaymentsUseCase: mockWatchPayments,
        );
      },
      act: (cubit) async {
        final res = await cubit.recordPayment(
          supplierId: 20,
          amount: const Money(3500),
          paymentDate: DateTime(2026, 9, 24),
        );
        expect(res.isSuccess, isTrue);
      },
    );
  });
}
