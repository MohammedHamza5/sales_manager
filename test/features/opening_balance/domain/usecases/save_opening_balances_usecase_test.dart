import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/result/result.dart';
import 'package:sales_manager/features/opening_balance/domain/entities/opening_balance_input.dart';
import 'package:sales_manager/features/opening_balance/domain/repositories/opening_balance_repository.dart';
import 'package:sales_manager/features/opening_balance/domain/usecases/save_opening_balances_usecase.dart';

class MockOpeningBalanceRepository extends Mock
    implements OpeningBalanceRepository {}

class FakeOpeningBalanceInput extends Fake implements OpeningBalanceInput {}

void main() {
  late MockOpeningBalanceRepository mockRepo;
  late SaveOpeningBalancesUseCase useCase;

  setUpAll(() {
    registerFallbackValue(FakeOpeningBalanceInput());
  });

  setUp(() {
    mockRepo = MockOpeningBalanceRepository();
    useCase = SaveOpeningBalancesUseCase(mockRepo);
  });

  group('SaveOpeningBalancesUseCase Unit Tests', () {
    test('Fails when opening balance is already marked as saved', () async {
      when(() => mockRepo.isOpeningBalanceSaved())
          .thenAnswer((_) async => const Success(true));

      const input = OpeningBalanceInput(
        cashboxBalance: Money.fromPiastres(10000),
      );

      final result = await useCase(input);

      expect(result.isFailure, isTrue);
      expect(
        result.failureOrNull?.message,
        contains('تم حفظ الأرصدة الافتتاحية للنظام بالفعل سابقاً'),
      );
      verifyNever(() => mockRepo.saveOpeningBalances(any()));
    });

    test('Fails when product has negative quantity', () async {
      when(() => mockRepo.isOpeningBalanceSaved())
          .thenAnswer((_) async => const Success(false));

      final input = OpeningBalanceInput(
        products: [
          ProductOpeningBalance(
            productId: 1,
            productName: 'منتج سالب',
            code: 'P01',
            unit: 'قطعة',
            initialQuantity: Decimal.parse('-5'),
          ),
        ],
      );

      final result = await useCase(input);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, contains('لا يمكن أن تكون سالبة'));
      verifyNever(() => mockRepo.saveOpeningBalances(any()));
    });

    test('Fails when customer has negative balance', () async {
      when(() => mockRepo.isOpeningBalanceSaved())
          .thenAnswer((_) async => const Success(false));

      const input = OpeningBalanceInput(
        customers: [
          StakeholderOpeningBalance(
            stakeholderId: 1,
            name: 'عميل سالب',
            balance: Money.fromPiastres(-5000),
          ),
        ],
      );

      final result = await useCase(input);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, contains('لا يمكن أن تكون سالبة'));
      verifyNever(() => mockRepo.saveOpeningBalances(any()));
    });

    test('Fails when supplier has negative balance', () async {
      when(() => mockRepo.isOpeningBalanceSaved())
          .thenAnswer((_) async => const Success(false));

      const input = OpeningBalanceInput(
        suppliers: [
          StakeholderOpeningBalance(
            stakeholderId: 1,
            name: 'مورد سالب',
            balance: Money.fromPiastres(-10000),
          ),
        ],
      );

      final result = await useCase(input);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, contains('لا يمكن أن تكون سالبة'));
      verifyNever(() => mockRepo.saveOpeningBalances(any()));
    });

    test('Delegates to repository when input is valid and not saved before', () async {
      when(() => mockRepo.isOpeningBalanceSaved())
          .thenAnswer((_) async => const Success(false));
      when(() => mockRepo.saveOpeningBalances(any(), createdBy: any(named: 'createdBy')))
          .thenAnswer((_) async => const Success(null));

      final input = OpeningBalanceInput(
        cashboxBalance: const Money.fromPiastres(50000),
        products: [
          ProductOpeningBalance(
            productId: 1,
            productName: 'شاي العروسة',
            code: 'TEA-01',
            unit: 'باكت',
            initialQuantity: Decimal.fromInt(100),
          ),
        ],
        customers: const [
          StakeholderOpeningBalance(
            stakeholderId: 10,
            name: 'عميل آجل',
            balance: Money.fromPiastres(15000),
          ),
        ],
        suppliers: const [
          StakeholderOpeningBalance(
            stakeholderId: 20,
            name: 'مورد بضاعة',
            balance: Money.fromPiastres(25000),
          ),
        ],
      );

      final result = await useCase(input, createdBy: 'admin');

      expect(result.isSuccess, isTrue);
      verify(() => mockRepo.saveOpeningBalances(input, createdBy: 'admin')).called(1);
    });
  });
}
