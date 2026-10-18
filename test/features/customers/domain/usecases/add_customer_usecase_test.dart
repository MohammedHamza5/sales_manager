import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/result/failures.dart';
import 'package:sales_manager/core/result/result.dart';
import 'package:sales_manager/features/customers/domain/entities/customer.dart';
import 'package:sales_manager/features/customers/domain/repositories/customer_repository.dart';
import 'package:sales_manager/features/customers/domain/usecases/add_customer_usecase.dart';

class MockCustomerRepository extends Mock implements CustomerRepository {}

void main() {
  late AddCustomerUseCase useCase;
  late MockCustomerRepository mockRepository;

  setUp(() {
    mockRepository = MockCustomerRepository();
    useCase = AddCustomerUseCase(mockRepository);
  });

  group('AddCustomerUseCase Unit Tests', () {
    test('Fails when name is empty or whitespace only', () async {
      final result = await useCase(
        name: '   ',
        phone: '01012345678',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect((result.failureOrNull as ValidationFailure).field, 'name');
    });

    test('Fails when phone format is invalid', () async {
      final result = await useCase(
        name: 'محمد أحمد',
        phone: 'invalid-phone-abc',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect((result.failureOrNull as ValidationFailure).field, 'phone');
    });

    test('Successfully adds customer when inputs are valid', () async {
      final expectedCustomer = Customer(
        id: 1,
        name: 'محمود السيد',
        phone: '01012345678',
        address: 'شارع الجمهورية',
        notes: 'عميل جملة موثوق',
        currentBalance: const Money.fromPiastres(50000), // 500 EGP
        createdAt: DateTime.now(),
        createdBy: 'admin',
      );

      when(
        () => mockRepository.addCustomer(
          name: 'محمود السيد',
          phone: '01012345678',
          address: 'شارع الجمهورية',
          notes: 'عميل جملة موثوق',
          initialBalance: const Money.fromPiastres(50000),
          createdBy: 'admin',
        ),
      ).thenAnswer((_) async => Success(expectedCustomer));

      final result = await useCase(
        name: '  محمود السيد  ',
        phone: '  01012345678  ',
        address: '  شارع الجمهورية  ',
        notes: '  عميل جملة موثوق  ',
        initialBalance: const Money.fromPiastres(50000),
        createdBy: 'admin',
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.id, 1);
      expect(result.dataOrNull?.name, 'محمود السيد');
      expect(result.dataOrNull?.hasDebt, isTrue);
      expect(result.dataOrNull?.currentBalance.piastres, 50000);
    });
  });
}
