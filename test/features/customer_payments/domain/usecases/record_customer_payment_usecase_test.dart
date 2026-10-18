import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/result/failures.dart';
import 'package:sales_manager/core/result/result.dart';
import 'package:sales_manager/features/customer_payments/domain/entities/customer_payment.dart';
import 'package:sales_manager/features/customer_payments/domain/repositories/customer_payment_repository.dart';
import 'package:sales_manager/features/customer_payments/domain/usecases/record_customer_payment_usecase.dart';

class MockCustomerPaymentRepository extends Mock
    implements CustomerPaymentRepository {}

void main() {
  late MockCustomerPaymentRepository repository;
  late RecordCustomerPaymentUseCase useCase;

  setUp(() {
    repository = MockCustomerPaymentRepository();
    useCase = RecordCustomerPaymentUseCase(repository);
  });

  group('RecordCustomerPaymentUseCase Unit Tests', () {
    test('Fails when customerId is <= 0', () async {
      final result = await useCase(
        customerId: 0,
        amount: const Money(1000),
        paymentDate: DateTime.now(),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('Fails when amount is <= 0', () async {
      final result = await useCase(
        customerId: 1,
        amount: const Money(0),
        paymentDate: DateTime.now(),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('Delegates to repository when inputs are valid', () async {
      final now = DateTime.now();
      final expectedPayment = CustomerPayment(
        id: 1,
        customerId: 10,
        customerName: 'عميل 1',
        amount: const Money(5000),
        paymentDate: now,
        createdAt: now,
      );

      when(() => repository.recordPayment(
            customerId: 10,
            amount: const Money(5000),
            paymentDate: now,
            linkedSaleId: null,
            note: null,
            createdBy: 'admin',
          )).thenAnswer((_) async => Success(expectedPayment));

      final result = await useCase(
        customerId: 10,
        amount: const Money(5000),
        paymentDate: now,
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals(expectedPayment));
      verify(() => repository.recordPayment(
            customerId: 10,
            amount: const Money(5000),
            paymentDate: now,
            linkedSaleId: null,
            note: null,
            createdBy: 'admin',
          )).called(1);
    });
  });
}
