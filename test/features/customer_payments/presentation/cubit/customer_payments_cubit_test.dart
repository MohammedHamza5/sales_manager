import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/result/result.dart';
import 'package:sales_manager/features/customer_payments/domain/entities/customer_payment.dart';
import 'package:sales_manager/features/customer_payments/domain/usecases/record_customer_payment_usecase.dart';
import 'package:sales_manager/features/customer_payments/domain/usecases/watch_customer_payments_usecase.dart';
import 'package:sales_manager/features/customer_payments/presentation/cubit/customer_payments_cubit.dart';
import 'package:sales_manager/features/customer_payments/presentation/cubit/customer_payments_state.dart';

class MockRecordCustomerPaymentUseCase extends Mock
    implements RecordCustomerPaymentUseCase {}

class MockWatchCustomerPaymentsUseCase extends Mock
    implements WatchCustomerPaymentsUseCase {}

void main() {
  late MockRecordCustomerPaymentUseCase mockRecordPayment;
  late MockWatchCustomerPaymentsUseCase mockWatchPayments;

  setUp(() {
    mockRecordPayment = MockRecordCustomerPaymentUseCase();
    mockWatchPayments = MockWatchCustomerPaymentsUseCase();
  });

  group('CustomerPaymentsCubit Tests', () {
    test('Initial state is CustomerPaymentsInitial', () {
      final cubit = CustomerPaymentsCubit(
        recordPaymentUseCase: mockRecordPayment,
        watchPaymentsUseCase: mockWatchPayments,
      );
      expect(cubit.state, equals(const CustomerPaymentsInitial()));
      cubit.close();
    });

    blocTest<CustomerPaymentsCubit, CustomerPaymentsState>(
      'Emits [CustomerPaymentsLoading, CustomerPaymentsEmpty] when stream emits empty list',
      build: () {
        when(() => mockWatchPayments(customerId: any(named: 'customerId')))
            .thenAnswer((_) => Stream.value([]));
        return CustomerPaymentsCubit(
          recordPaymentUseCase: mockRecordPayment,
          watchPaymentsUseCase: mockWatchPayments,
        );
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        const CustomerPaymentsLoading(),
        const CustomerPaymentsEmpty(),
      ],
    );

    blocTest<CustomerPaymentsCubit, CustomerPaymentsState>(
      'Emits [CustomerPaymentsLoading, CustomerPaymentsLoaded] when stream emits payments',
      build: () {
        final payment = CustomerPayment(
          id: 1,
          customerId: 10,
          customerName: 'أحمد',
          amount: const Money(4000),
          paymentDate: DateTime(2026, 9, 24),
          createdAt: DateTime(2026, 9, 24),
        );
        when(() => mockWatchPayments(customerId: any(named: 'customerId')))
            .thenAnswer((_) => Stream.value([payment]));
        return CustomerPaymentsCubit(
          recordPaymentUseCase: mockRecordPayment,
          watchPaymentsUseCase: mockWatchPayments,
        );
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        const CustomerPaymentsLoading(),
        isA<CustomerPaymentsLoaded>()
            .having((s) => s.allPayments.length, 'length', 1)
            .having((s) => s.totalCollected, 'totalCollected', const Money(4000)),
      ],
    );

    blocTest<CustomerPaymentsCubit, CustomerPaymentsState>(
      'Delegates recordPayment to usecase',
      build: () {
        final payment = CustomerPayment(
          id: 2,
          customerId: 10,
          customerName: 'أحمد',
          amount: const Money(5000),
          paymentDate: DateTime(2026, 9, 24),
          createdAt: DateTime(2026, 9, 24),
        );
        when(() => mockRecordPayment(
              customerId: 10,
              amount: const Money(5000),
              paymentDate: any(named: 'paymentDate'),
              linkedSaleId: null,
              note: null,
            )).thenAnswer((_) async => Success(payment));
        return CustomerPaymentsCubit(
          recordPaymentUseCase: mockRecordPayment,
          watchPaymentsUseCase: mockWatchPayments,
        );
      },
      act: (cubit) async {
        final res = await cubit.recordPayment(
          customerId: 10,
          amount: const Money(5000),
          paymentDate: DateTime(2026, 9, 24),
        );
        expect(res.isSuccess, isTrue);
      },
    );
  });
}
