import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/features/suppliers/domain/entities/supplier_ledger_entry.dart';
import 'package:sales_manager/features/suppliers/domain/repositories/supplier_repository.dart';
import 'package:sales_manager/features/suppliers/domain/usecases/watch_supplier_ledger_usecase.dart';

class MockSupplierRepository extends Mock implements SupplierRepository {}

void main() {
  late MockSupplierRepository mockRepo;
  late WatchSupplierLedgerUseCase useCase;

  final sampleLedger = [
    SupplierLedgerEntry(
      id: 1,
      supplierId: 10,
      entryType: SupplierLedgerEntryType.openingBalance,
      amount: const Money.fromPiastres(50000),
      effect: SupplierLedgerEffect.increase,
      balanceAfter: const Money.fromPiastres(50000),
      referenceType: 'opening_balance',
      referenceId: null,
      note: 'رصيد افتتاحي',
      createdAt: DateTime(2026, 1, 1),
      createdBy: 'admin',
    ),
    SupplierLedgerEntry(
      id: 2,
      supplierId: 10,
      entryType: SupplierLedgerEntryType.payment,
      amount: const Money.fromPiastres(20000),
      effect: SupplierLedgerEffect.decrease,
      balanceAfter: const Money.fromPiastres(30000),
      referenceType: 'payment_voucher',
      referenceId: 101,
      note: 'سند صرف نقدية',
      createdAt: DateTime(2026, 1, 2),
      createdBy: 'admin',
    ),
  ];

  setUp(() {
    mockRepo = MockSupplierRepository();
    useCase = WatchSupplierLedgerUseCase(mockRepo);
  });

  group('WatchSupplierLedgerUseCase Unit Tests', () {
    test('Delegates to SupplierRepository.watchSupplierLedger with correct supplierId',
        () async {
      when(() => mockRepo.watchSupplierLedger(10))
          .thenAnswer((_) => Stream.value(sampleLedger));

      final stream = useCase(10);

      expect(await stream.first, equals(sampleLedger));
      verify(() => mockRepo.watchSupplierLedger(10)).called(1);
    });
  });
}
