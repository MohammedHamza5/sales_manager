import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/result/failures.dart';
import 'package:sales_manager/core/result/result.dart';
import 'package:sales_manager/features/suppliers/domain/entities/supplier.dart';
import 'package:sales_manager/features/suppliers/domain/repositories/supplier_repository.dart';
import 'package:sales_manager/features/suppliers/domain/usecases/add_supplier_usecase.dart';

class MockSupplierRepository extends Mock implements SupplierRepository {}

void main() {
  late MockSupplierRepository mockRepo;
  late AddSupplierUseCase useCase;

  final sampleSupplier = Supplier(
    id: 1,
    name: 'مورد الألبان المتحدة',
    phone: '01012345678',
    address: 'طنطا',
    notes: 'مورد رئيسي',
    currentBalance: const Money.fromPiastres(50000), // 500.00 EGP due
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
    createdBy: 'admin',
  );

  setUp(() {
    mockRepo = MockSupplierRepository();
    useCase = AddSupplierUseCase(mockRepo);
  });

  group('AddSupplierUseCase Unit Tests', () {
    test('Fails when name is empty or whitespace only', () async {
      final result = await useCase(name: '   ');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(
        (result.failureOrNull as ValidationFailure).field,
        equals('name'),
      );
      verifyZeroInteractions(mockRepo);
    });

    test('Fails when phone format is invalid', () async {
      final result = await useCase(
        name: 'مورد تجريبي',
        phone: 'invalid-phone-abc',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(
        (result.failureOrNull as ValidationFailure).field,
        equals('phone'),
      );
      verifyZeroInteractions(mockRepo);
    });

    test('Successfully adds supplier when inputs are valid', () async {
      when(() => mockRepo.addSupplier(
            name: 'مورد الألبان المتحدة',
            phone: '01012345678',
            address: 'طنطا',
            notes: 'مورد رئيسي',
            initialBalance: const Money.fromPiastres(50000),
            createdBy: 'admin',
          )).thenAnswer((_) async => Success(sampleSupplier));

      final result = await useCase(
        name: '  مورد الألبان المتحدة  ',
        phone: '01012345678',
        address: '  طنطا  ',
        notes: '  مورد رئيسي  ',
        initialBalance: const Money.fromPiastres(50000),
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals(sampleSupplier));
      verify(() => mockRepo.addSupplier(
            name: 'مورد الألبان المتحدة',
            phone: '01012345678',
            address: 'طنطا',
            notes: 'مورد رئيسي',
            initialBalance: const Money.fromPiastres(50000),
            createdBy: 'admin',
          )).called(1);
    });
  });
}
