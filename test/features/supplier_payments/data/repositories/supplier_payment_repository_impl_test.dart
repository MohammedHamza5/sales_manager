import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_manager/core/database/app_database.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/result/failures.dart';
import 'package:sales_manager/features/supplier_payments/data/daos/supplier_payments_dao.dart';
import 'package:sales_manager/features/supplier_payments/data/repositories/supplier_payment_repository_impl.dart';
import 'package:sales_manager/features/supplier_payments/domain/repositories/supplier_payment_repository.dart';

void main() {
  late AppDatabase db;
  late SupplierPaymentsDao dao;
  late SupplierPaymentRepository repository;

  setUp(() {
    db = AppDatabase.memory();
    dao = SupplierPaymentsDao(db);
    repository = SupplierPaymentRepositoryImpl(db: db, dao: dao);
  });

  tearDown(() async {
    await db.close();
  });

  group('SupplierPaymentRepositoryImpl Integration Tests', () {
    test(
        'Recording supplier payment decreases supplier dues, deducts cashbox, and writes ledger atomically',
        () async {
      // 1. Setup active supplier with initial dues of 8000 piastres (80 EGP)
      final sId = await db.into(db.suppliers).insert(
            SuppliersCompanion.insert(
              name: 'مورد اختبار',
              phone: const Value('01211112222'),
              currentBalance: const Value(8000),
            ),
          );

      // 2. Setup initial cashbox transaction with 20000 piastres balance
      await db.into(db.cashboxTransactions).insert(
            CashboxTransactionsCompanion.insert(
              transactionType: 'opening_balance',
              amount: 20000,
              direction: 'in',
              balanceAfter: 20000,
            ),
          );

      // 3. Setup confirmed purchase for this supplier
      final pId = await db.into(db.purchases).insert(
            PurchasesCompanion.insert(
              invoiceNo: 201,
              supplierId: sId,
              purchaseDate: DateTime(2026, 9, 21),
              totalAmount: 8000,
              paidAmountAtCreation: 0,
              status: const Value('confirmed'),
            ),
          );

      // 4. Record payment of 5000 piastres linked to purchase
      final res = await repository.recordPayment(
        supplierId: sId,
        amount: const Money(5000),
        paymentDate: DateTime(2026, 9, 24),
        linkedPurchaseId: pId,
        note: 'سداد نقدي لدفعة بضاعة',
      );

      expect(res.isSuccess, isTrue);
      final payment = res.dataOrNull!;
      expect(payment.amount, const Money(5000));
      expect(payment.supplierId, sId);
      expect(payment.supplierName, 'مورد اختبار');
      expect(payment.linkedPurchaseId, pId);

      // 5. Verify supplier balance decreased: 8000 - 5000 = 3000
      final updatedSupplier = await (db.select(db.suppliers)
            ..where((t) => t.id.equals(sId)))
          .getSingle();
      expect(updatedSupplier.currentBalance, 3000);

      // 6. Verify supplier ledger entry recorded
      final ledgerEntries = await (db.select(db.supplierLedgerEntries)
            ..where((t) => t.supplierId.equals(sId)))
          .get();
      expect(ledgerEntries.length, 1);
      expect(ledgerEntries.first.entryType, 'payment');
      expect(ledgerEntries.first.amount, 5000);
      expect(ledgerEntries.first.effect, 'decrease');
      expect(ledgerEntries.first.balanceAfter, 3000);

      // 7. Verify cashbox balance deducted: 20000 - 5000 = 15000
      final latestCashbox = await (db.select(db.cashboxTransactions)
            ..orderBy([(t) => OrderingTerm.desc(t.id)])
            ..limit(1))
          .getSingle();
      expect(latestCashbox.transactionType, 'supplier_payment_out');
      expect(latestCashbox.direction, 'out');
      expect(latestCashbox.amount, 5000);
      expect(latestCashbox.balanceAfter, 15000);

      // 8. Verify audit log entry created
      final auditLogs = await (db.select(db.auditLog)
            ..where((t) => t.entityType.equals('supplier_payment')))
          .get();
      expect(auditLogs.length, 1);
      expect(auditLogs.first.action, 'create');
    });

    test('Fails when supplier is not found or inactive', () async {
      final resNotFound = await repository.recordPayment(
        supplierId: 9999,
        amount: const Money(1000),
        paymentDate: DateTime.now(),
      );
      expect(resNotFound.isFailure, isTrue);
      expect(resNotFound.failureOrNull, isA<NotFoundFailure>());

      final inactiveId = await db.into(db.suppliers).insert(
            SuppliersCompanion.insert(
              name: 'مورد موقوف',
              phone: const Value('01200000000'),
              isActive: const Value(false),
            ),
          );

      final resInactive = await repository.recordPayment(
        supplierId: inactiveId,
        amount: const Money(1000),
        paymentDate: DateTime.now(),
      );
      expect(resInactive.isFailure, isTrue);
      expect(resInactive.failureOrNull, isA<ConflictFailure>());
    });
  });
}
