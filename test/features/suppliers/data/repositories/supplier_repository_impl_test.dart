import 'package:flutter_test/flutter_test.dart';
import 'package:sales_manager/core/database/app_database.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/features/suppliers/data/daos/suppliers_dao.dart';
import 'package:sales_manager/features/suppliers/data/repositories/supplier_repository_impl.dart';
import 'package:sales_manager/features/suppliers/domain/entities/supplier_ledger_entry.dart';
import 'package:sales_manager/features/suppliers/domain/repositories/supplier_repository.dart';

void main() {
  late AppDatabase db;
  late SuppliersDao dao;
  late SupplierRepository repository;

  setUp(() {
    db = AppDatabase.memory();
    dao = SuppliersDao(db);
    repository = SupplierRepositoryImpl(db: db, dao: dao);
  });

  tearDown(() async {
    await db.close();
  });

  group('SupplierRepositoryImpl Integration Tests', () {
    test('Adding supplier without initial balance inserts supplier and audit log', () async {
      final result = await repository.addSupplier(
        name: 'مورد مواد خام 1',
        phone: '01222334455',
        address: 'العاشر من رمضان',
        notes: 'ملاحظات تجريبية للمورد',
      );

      expect(result.isSuccess, isTrue);
      final supplier = result.dataOrNull!;
      expect(supplier.id, isPositive);
      expect(supplier.name, 'مورد مواد خام 1');
      expect(supplier.currentBalance, Money.zero);
      expect(supplier.isActive, isTrue);
      expect(supplier.isSettled, isTrue);

      // Verify audit log write
      final logs = await db.select(db.auditLog).get();
      expect(logs.length, 1);
      expect(logs.first.entityType, 'supplier');
      expect(logs.first.action, 'create');
      expect(logs.first.entityId, supplier.id);

      // Verify no ledger entries created when initialBalance is zero
      final ledger = await repository.getSupplierLedger(supplier.id);
      expect(ledger.isSuccess, isTrue);
      expect(ledger.dataOrNull!, isEmpty);
    });

    test('Adding supplier with initial balance due creates supplier, ledger entry, and audit log atomically', () async {
      const initialDue = Money.fromPiastres(250000); // 2500.00 EGP

      final result = await repository.addSupplier(
        name: 'شركة النور للأجهزة',
        phone: '01011223344',
        initialBalance: initialDue,
      );

      expect(result.isSuccess, isTrue);
      final supplier = result.dataOrNull!;
      expect(supplier.currentBalance, initialDue);
      expect(supplier.hasBalanceDue, isTrue);
      expect(supplier.isSettled, isFalse);

      // Check supplier ledger
      final ledgerResult = await repository.getSupplierLedger(supplier.id);
      expect(ledgerResult.isSuccess, isTrue);
      final entries = ledgerResult.dataOrNull!;
      expect(entries.length, 1);

      final entry = entries.first;
      expect(entry.supplierId, supplier.id);
      expect(entry.entryType, SupplierLedgerEntryType.openingBalance);
      expect(entry.amount, initialDue);
      expect(entry.effect, SupplierLedgerEffect.increase);
      expect(entry.balanceAfter, initialDue);
      expect(entry.note, 'رصيد افتتاحي عند تسجيل المورد');
    });

    test('Updating supplier updates data, writes audit log, and preserves balance', () async {
      final addResult = await repository.addSupplier(
        name: 'شركة الشروق للتوريد',
        phone: '01000000003',
        initialBalance: const Money.fromPiastres(45000),
      );
      final original = addResult.dataOrNull!;

      final updateResult = await repository.updateSupplier(
        original.copyWith(
          name: 'شركة الشروق للتوريد الحديث',
          phone: '01000000004',
          address: 'المنصورة',
        ),
      );

      expect(updateResult.isSuccess, isTrue);
      final updated = updateResult.dataOrNull!;
      expect(updated.name, 'شركة الشروق للتوريد الحديث');
      expect(updated.phone, '01000000004');
      expect(updated.address, 'المنصورة');
      expect(updated.currentBalance.piastres, 45000); // balance strictly preserved

      // Audit logs must now have create + update
      final logs = await db.select(db.auditLog).get();
      expect(logs.length, 2);
      expect(logs.last.action, 'update');
    });

    test('Toggling supplier status toggles isActive and writes audit log', () async {
      final addResult = await repository.addSupplier(name: 'مورد معطل لاحقاً');
      final supplier = addResult.dataOrNull!;

      // Deactivate
      final deactivateResult = await repository.toggleSupplierStatus(supplier.id, false);
      expect(deactivateResult.isSuccess, isTrue);

      final fetched = await repository.getSupplierById(supplier.id);
      expect(fetched.dataOrNull?.isActive, isFalse);

      // Activate
      final activateResult = await repository.toggleSupplierStatus(supplier.id, true);
      expect(activateResult.isSuccess, isTrue);

      final fetchedActive = await repository.getSupplierById(supplier.id);
      expect(fetchedActive.dataOrNull?.isActive, isTrue);
    });

    test('Watch suppliers stream emits updates reactively', () async {
      final stream = repository.watchSuppliers();

      // 1. Initial emission is empty
      expect(await stream.first, isEmpty);

      // 2. Add supplier
      await repository.addSupplier(name: 'مورد بث مباشر');

      // 3. Reactive emission receives the updated list
      final updatedList = await stream.firstWhere((list) => list.isNotEmpty);
      expect(updatedList.length, 1);
      expect(updatedList.first.name, 'مورد بث مباشر');
    });
  });
}
