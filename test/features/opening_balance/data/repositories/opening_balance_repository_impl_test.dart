import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_manager/core/database/app_database.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/features/opening_balance/data/repositories/opening_balance_repository_impl.dart';
import 'package:sales_manager/features/opening_balance/domain/entities/opening_balance_input.dart';
import 'package:sales_manager/features/opening_balance/domain/repositories/opening_balance_repository.dart';

void main() {
  late AppDatabase db;
  late OpeningBalanceRepository repository;

  setUp(() {
    db = AppDatabase.memory();
    repository = OpeningBalanceRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('OpeningBalanceRepositoryImpl Integration Tests', () {
    test('isOpeningBalanceSaved returns false initially when setting does not exist',
        () async {
      final result = await repository.isOpeningBalanceSaved();
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isFalse);
    });

    test('saveOpeningBalances commits atomically across all 4 tables, settings, and audit log',
        () async {
      // 1. Prepare base seed data in DB
      final prodId = await db.into(db.products).insert(
            ProductsCompanion.insert(
              name: 'سكر أبيض 1 كجم',
              unit: 'كيس',
              currentSalePrice: 3500,
              currentPurchasePrice: 3000,
              currentQuantity: Value(Decimal.zero),
            ),
          );

      final custId = await db.into(db.customers).insert(
            CustomersCompanion.insert(
              name: 'سوبرماركت المدينة',
            ),
          );

      final suppId = await db.into(db.suppliers).insert(
            SuppliersCompanion.insert(
              name: 'شركة الدلتا للسكر',
            ),
          );

      // 2. Prepare OpeningBalanceInput
      final input = OpeningBalanceInput(
        cashboxBalance: const Money.fromPiastres(150000), // 1500.00 EGP
        products: [
          ProductOpeningBalance(
            productId: prodId,
            productName: 'سكر أبيض 1 كجم',
            unit: 'كيس',
            initialQuantity: Decimal.fromInt(80),
          ),
        ],
        customers: [
          StakeholderOpeningBalance(
            stakeholderId: custId,
            name: 'سوبرماركت المدينة',
            balance: const Money.fromPiastres(45000), // 450.00 EGP
          ),
        ],
        suppliers: [
          StakeholderOpeningBalance(
            stakeholderId: suppId,
            name: 'شركة الدلتا للسكر',
            balance: const Money.fromPiastres(75000), // 750.00 EGP
          ),
        ],
      );

      // 3. Commit atomic save
      final saveResult = await repository.saveOpeningBalances(input);
      expect(saveResult.isSuccess, isTrue);

      // 4. Verify status is now true
      final statusResult = await repository.isOpeningBalanceSaved();
      expect(statusResult.dataOrNull, isTrue);

      // 5. Verify Cashbox
      final cashTxs = await db.select(db.cashboxTransactions).get();
      expect(cashTxs.length, 1);
      final cashTx = cashTxs.first;
      expect(cashTx.transactionType, 'opening_balance');
      expect(cashTx.amount, 150000);
      expect(cashTx.direction, 'in');
      expect(cashTx.balanceAfter, 150000);

      // 6. Verify Product stock & inventory movement
      final movements = await db.select(db.inventoryMovements).get();
      expect(movements.length, 1);
      final movement = movements.first;
      expect(movement.productId, prodId);
      expect(movement.movementType, 'opening_balance');
      expect(movement.quantityDelta, Decimal.fromInt(80));
      expect(movement.balanceAfter, Decimal.fromInt(80));

      final updatedProd = await (db.select(db.products)
            ..where((p) => p.id.equals(prodId)))
          .getSingle();
      expect(updatedProd.currentQuantity, Decimal.fromInt(80));

      // 7. Verify Customer balance & ledger
      final custEntries = await db.select(db.customerLedgerEntries).get();
      expect(custEntries.length, 1);
      final custEntry = custEntries.first;
      expect(custEntry.customerId, custId);
      expect(custEntry.entryType, 'opening_balance');
      expect(custEntry.amount, 45000);
      expect(custEntry.effect, 'increase');
      expect(custEntry.balanceAfter, 45000);

      final updatedCust = await (db.select(db.customers)
            ..where((c) => c.id.equals(custId)))
          .getSingle();
      expect(updatedCust.currentBalance, 45000);

      // 8. Verify Supplier balance & ledger
      final suppEntries = await db.select(db.supplierLedgerEntries).get();
      expect(suppEntries.length, 1);
      final suppEntry = suppEntries.first;
      expect(suppEntry.supplierId, suppId);
      expect(suppEntry.entryType, 'opening_balance');
      expect(suppEntry.amount, 75000);
      expect(suppEntry.effect, 'increase');
      expect(suppEntry.balanceAfter, 75000);

      final updatedSupp = await (db.select(db.suppliers)
            ..where((s) => s.id.equals(suppId)))
          .getSingle();
      expect(updatedSupp.currentBalance, 75000);

      // 9. Verify Settings table has opening_balance_saved = true
      final setting = await (db.select(db.settings)
            ..where((s) => s.key.equals('opening_balance_saved')))
          .getSingle();
      expect(setting.value, 'true');

      // 10. Verify Audit Log
      final auditLogs = await db.select(db.auditLog).get();
      expect(auditLogs.length, 1);
      final log = auditLogs.first;
      expect(log.entityType, 'system');
      expect(log.action, 'opening_balance');
    });
  });
}
