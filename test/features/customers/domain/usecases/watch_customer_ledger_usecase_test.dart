import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/features/customers/domain/entities/customer_ledger_entry.dart';
import 'package:sales_manager/features/customers/domain/repositories/customer_repository.dart';
import 'package:sales_manager/features/customers/domain/usecases/watch_customer_ledger_usecase.dart';

class MockCustomerRepository extends Mock implements CustomerRepository {}

void main() {
  late MockCustomerRepository mockRepo;
  late WatchCustomerLedgerUseCase useCase;

  final sampleLedger = [
    CustomerLedgerEntry(
      id: 1,
      customerId: 10,
      entryType: CustomerLedgerEntryType.openingBalance,
      amount: const Money.fromPiastres(5000),
      effect: LedgerEffect.increase,
      balanceAfter: const Money.fromPiastres(5000),
      referenceType: 'opening_balance',
      referenceId: null,
      note: 'رصيد افتتاحي',
      createdAt: DateTime(2026, 1, 1),
      createdBy: 'admin',
    ),
    CustomerLedgerEntry(
      id: 2,
      customerId: 10,
      entryType: CustomerLedgerEntryType.payment,
      amount: const Money.fromPiastres(2000),
      effect: LedgerEffect.decrease,
      balanceAfter: const Money.fromPiastres(3000),
      referenceType: 'receipt',
      referenceId: 101,
      note: 'سداد نقدي',
      createdAt: DateTime(2026, 1, 2),
      createdBy: 'admin',
    ),
  ];

  setUp(() {
    mockRepo = MockCustomerRepository();
    useCase = WatchCustomerLedgerUseCase(mockRepo);
  });

  group('WatchCustomerLedgerUseCase Unit Tests', () {
    test('Delegates to CustomerRepository.watchCustomerLedger with correct customerId',
        () async {
      when(() => mockRepo.watchCustomerLedger(10))
          .thenAnswer((_) => Stream.value(sampleLedger));

      final stream = useCase(10);

      expect(await stream.first, equals(sampleLedger));
      verify(() => mockRepo.watchCustomerLedger(10)).called(1);
    });
  });
}
