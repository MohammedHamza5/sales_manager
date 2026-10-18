import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/result/failures.dart';
import 'package:sales_manager/core/result/result.dart';
import 'package:sales_manager/features/supplier_payments/domain/entities/supplier_payment.dart';
import 'package:sales_manager/features/supplier_payments/domain/repositories/supplier_payment_repository.dart';
import 'package:sales_manager/features/supplier_payments/domain/usecases/record_supplier_payment_usecase.dart';

class MockSupplierPaymentRepository extends Mock
    implements SupplierPaymentRepository {}

void main() {
  late MockSupplierPaymentRepository repository;
  late RecordSupplierPaymentUseCase useCase;

  setUp(() {
    repository = MockSupplierPaymentRepository();
    useCase = RecordSupplierPaymentUseCase(repository);
  });

  group('RecordSupplierPaymentUseCase Unit Tests', () {
    test('Fails when supplierId is <= 0', () async {
      final result = await useCase(
        supplierId: 0,
        amount: const Money(1000),
        paymentDate: DateTime.now(),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('Fails when amount is <= 0', () async {
      final result = await useCase(
        supplierId: 1,
        amount: const Money(0),
        paymentDate: DateTime.now(),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('Delegates to repository when inputs are valid', () async {
      final now = DateTime.now();
      final expectedPayment = SupplierPayment(
        id: 1,
        supplierId: 20,
        supplierName: 'مورد 1',
        amount: const Money(7000),
        paymentDate: now,
        createdAt: now,
      );

      when(() => repository.recordPayment(
            supplierId: 20,
            amount: const Money(7000),
            paymentDate: now,
            linkedPurchaseId: null,
            note: null,
            createdBy: 'admin',
          )).thenAnswer((_) async => Success(expectedPayment));

      final result = await useCase(
        supplierId: 20,
        amount: const Money(7000),
        paymentDate: now,
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals(expectedPayment));
      verify(() => repository.recordPayment(
            supplierId: 20,
            amount: const Money(7000),
            paymentDate: now,
            linkedPurchaseId: null,
            note: null,
            createdBy: 'admin',
          )).called(1);
    });
  });
}
