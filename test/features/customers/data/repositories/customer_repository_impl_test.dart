import 'package:flutter_test/flutter_test.dart';
import 'package:sales_manager/core/database/app_database.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/features/customers/data/daos/customers_dao.dart';
import 'package:sales_manager/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:sales_manager/features/customers/domain/entities/customer_ledger_entry.dart';
import 'package:sales_manager/features/customers/domain/repositories/customer_repository.dart';

void main() {
  late AppDatabase db;
  late CustomersDao dao;
  late CustomerRepository repository;

  setUp(() {
    db = AppDatabase.memory();
    dao = CustomersDao(db);
    repository = CustomerRepositoryImpl(db: db, dao: dao);
  });

  tearDown(() async {
    await db.close();
  });

  group('CustomerRepositoryImpl Integration Tests', () {
    test('Adding customer without initial balance inserts customer and audit log', () async {
      final result = await repository.addCustomer(
        name: 'عميل نقدي 1',
        phone: '01122334455',
        address: 'القاهرة',
        notes: 'ملاحظات تجريبية',
      );

      expect(result.isSuccess, isTrue);
      final customer = result.dataOrNull!;
      expect(customer.id, isPositive);
      expect(customer.name, 'عميل نقدي 1');
      expect(customer.currentBalance, Money.zero);
      expect(customer.isActive, isTrue);

      // Verify audit log write
      final logs = await db.select(db.auditLog).get();
      expect(logs.length, 1);
      expect(logs.first.entityType, 'customer');
      expect(logs.first.action, 'create');
      expect(logs.first.entityId, customer.id);

      // Verify no ledger entries created when initialBalance is zero
      final ledger = await repository.getCustomerLedger(customer.id);
      expect(ledger.isSuccess, isTrue);
      expect(ledger.dataOrNull!, isEmpty);
    });

    test('Adding customer with initial debt balance creates customer, ledger entry, and audit log atomically', () async {
      const initialDebt = Money.fromPiastres(150000); // 1500.00 EGP

      final result = await repository.addCustomer(
        name: 'أحمد التاجر',
        phone: '01099887766',
        initialBalance: initialDebt,
      );

      expect(result.isSuccess, isTrue);
      final customer = result.dataOrNull!;
      expect(customer.currentBalance, initialDebt);
      expect(customer.hasDebt, isTrue);

      // Check customer ledger
      final ledgerResult = await repository.getCustomerLedger(customer.id);
      expect(ledgerResult.isSuccess, isTrue);
      final entries = ledgerResult.dataOrNull!;
      expect(entries.length, 1);

      final entry = entries.first;
      expect(entry.customerId, customer.id);
      expect(entry.entryType, CustomerLedgerEntryType.openingBalance);
      expect(entry.amount, initialDebt);
      expect(entry.effect, LedgerEffect.increase);
      expect(entry.balanceAfter, initialDebt);
      expect(entry.note, 'رصيد افتتاحي عند إنشاء العميل');
    });

    test('Updating customer updates data, writes audit log, and preserves balance', () async {
      final addResult = await repository.addCustomer(
        name: 'كريم محمود',
        phone: '01000000001',
        initialBalance: const Money.fromPiastres(25000),
      );
      final original = addResult.dataOrNull!;

      final updateResult = await repository.updateCustomer(
        original.copyWith(
          name: 'كريم محمود المعدل',
          phone: '01000000002',
          address: 'الإسكندرية',
        ),
      );

      expect(updateResult.isSuccess, isTrue);
      final updated = updateResult.dataOrNull!;
      expect(updated.name, 'كريم محمود المعدل');
      expect(updated.phone, '01000000002');
      expect(updated.address, 'الإسكندرية');
      expect(updated.currentBalance.piastres, 25000); // balance strictly preserved

      // Audit logs must now have create + update
      final logs = await db.select(db.auditLog).get();
      expect(logs.length, 2);
      expect(logs.last.action, 'update');
    });

    test('Toggling customer status toggles isActive and writes audit log', () async {
      final addResult = await repository.addCustomer(name: 'عميل معطل لاحقاً');
      final customer = addResult.dataOrNull!;

      // Deactivate
      final deactivateResult = await repository.toggleCustomerStatus(customer.id, false);
      expect(deactivateResult.isSuccess, isTrue);

      final fetched = await repository.getCustomerById(customer.id);
      expect(fetched.dataOrNull?.isActive, isFalse);

      // Activate
      final activateResult = await repository.toggleCustomerStatus(customer.id, true);
      expect(activateResult.isSuccess, isTrue);

      final fetchedActive = await repository.getCustomerById(customer.id);
      expect(fetchedActive.dataOrNull?.isActive, isTrue);
    });

    test('Watch customers stream emits updates reactively', () async {
      final stream = repository.watchCustomers();

      // 1. Initial emission is empty
      expect(await stream.first, isEmpty);

      // 2. Add customer
      await repository.addCustomer(name: 'عميل بث مباشر');

      // 3. Reactive emission receives the updated list
      final updatedList = await stream.firstWhere((list) => list.isNotEmpty);
      expect(updatedList.length, 1);
      expect(updatedList.first.name, 'عميل بث مباشر');
    });
  });
}
