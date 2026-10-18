import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_manager/core/database/app_database.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/result/failures.dart';
import 'package:sales_manager/features/customer_payments/data/daos/customer_payments_dao.dart';
import 'package:sales_manager/features/customer_payments/data/repositories/customer_payment_repository_impl.dart';
import 'package:sales_manager/features/customer_payments/domain/repositories/customer_payment_repository.dart';

void main() {
  late AppDatabase db;
  late CustomerPaymentsDao dao;
  late CustomerPaymentRepository repository;

  setUp(() {
    db = AppDatabase.memory();
    dao = CustomerPaymentsDao(db);
    repository = CustomerPaymentRepositoryImpl(db: db, dao: dao);
  });

  tearDown(() async {
    await db.close();
  });

  group('CustomerPaymentRepositoryImpl Integration Tests', () {
    test(
        'Recording customer payment decreases customer debt, increases cashbox, and writes ledger atomically',
        () async {
      // 1. Setup active customer with initial debt of 5000 piastres (50 EGP)
      final cId = await db.into(db.customers).insert(
            CustomersCompanion.insert(
              name: 'عميل اختبار',
              phone: const Value('01011112222'),
              currentBalance: const Value(5000),
            ),
          );

      // 2. Setup initial cashbox transaction with 10000 piastres balance
      await db.into(db.cashboxTransactions).insert(
            CashboxTransactionsCompanion.insert(
              transactionType: 'opening_balance',
              amount: 10000,
              direction: 'in',
              balanceAfter: 10000,
            ),
          );

      // 3. Setup confirmed sale for this customer with 5000 remaining
      final sId = await db.into(db.sales).insert(
            SalesCompanion.insert(
              invoiceNo: 101,
              customerId: cId,
              saleDate: DateTime(2026, 9, 20),
              totalAmount: 5000,
              paidAmountAtCreation: 0,
              status: const Value('confirmed'),
            ),
          );

      // 4. Record payment of 3000 piastres linked to the sale
      final res = await repository.recordPayment(
        customerId: cId,
        amount: const Money(3000),
        paymentDate: DateTime(2026, 9, 24),
        linkedSaleId: sId,
        note: 'تحصيل نقدي جزئي',
      );

      expect(res.isSuccess, isTrue);
      final payment = res.dataOrNull!;
      expect(payment.amount, const Money(3000));
      expect(payment.customerId, cId);
      expect(payment.customerName, 'عميل اختبار');
      expect(payment.linkedSaleId, sId);

      // 5. Verify customer balance decreased: 5000 - 3000 = 2000
      final updatedCustomer = await (db.select(db.customers)
            ..where((t) => t.id.equals(cId)))
          .getSingle();
      expect(updatedCustomer.currentBalance, 2000);

      // 6. Verify customer ledger entry recorded
      final ledgerEntries = await (db.select(db.customerLedgerEntries)
            ..where((t) => t.customerId.equals(cId)))
          .get();
      expect(ledgerEntries.length, 1);
      expect(ledgerEntries.first.entryType, 'payment');
      expect(ledgerEntries.first.amount, 3000);
      expect(ledgerEntries.first.effect, 'decrease');
      expect(ledgerEntries.first.balanceAfter, 2000);

      // 7. Verify cashbox balance increased: 10000 + 3000 = 13000
      final latestCashbox = await (db.select(db.cashboxTransactions)
            ..orderBy([(t) => OrderingTerm.desc(t.id)])
            ..limit(1))
          .getSingle();
      expect(latestCashbox.transactionType, 'customer_payment_in');
      expect(latestCashbox.direction, 'in');
      expect(latestCashbox.amount, 3000);
      expect(latestCashbox.balanceAfter, 13000);

      // 8. Verify linked payment record was created with linkedSaleId
      final paymentEntry = await (db.select(db.customerPayments)
            ..where((t) => t.id.equals(res.dataOrNull!.id)))
          .getSingle();
      expect(paymentEntry.linkedSaleId, sId);

      // 9. Verify audit log entry created
      final auditLogs = await (db.select(db.auditLog)
            ..where((t) => t.entityType.equals('customer_payment')))
          .get();
      expect(auditLogs.length, 1);
      expect(auditLogs.first.action, 'create');
    });

    test('Fails when customer is not found or inactive', () async {
      final resNotFound = await repository.recordPayment(
        customerId: 9999,
        amount: const Money(1000),
        paymentDate: DateTime.now(),
      );
      expect(resNotFound.isFailure, isTrue);
      expect(resNotFound.failureOrNull, isA<NotFoundFailure>());

      final inactiveId = await db.into(db.customers).insert(
            CustomersCompanion.insert(
              name: 'عميل موقوف',
              phone: const Value('01000000000'),
              isActive: const Value(false),
            ),
          );

      final resInactive = await repository.recordPayment(
        customerId: inactiveId,
        amount: const Money(1000),
        paymentDate: DateTime.now(),
      );
      expect(resInactive.isFailure, isTrue);
      expect(resInactive.failureOrNull, isA<ConflictFailure>());
    });
  });
}
