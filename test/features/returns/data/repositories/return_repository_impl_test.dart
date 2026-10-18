import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_manager/core/database/app_database.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/result/failures.dart';
import 'package:sales_manager/features/returns/data/daos/returns_dao.dart';
import 'package:sales_manager/features/returns/data/repositories/return_repository_impl.dart';
import 'package:sales_manager/features/returns/domain/repositories/return_repository.dart';

void main() {
  late AppDatabase db;
  late ReturnsDao dao;
  late ReturnRepository repository;

  setUp(() {
    db = AppDatabase.memory();
    dao = ReturnsDao(db);
    repository = ReturnRepositoryImpl(db: db, dao: dao);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertCustomer(String name, {int initialBalance = 0}) {
    return db.into(db.customers).insert(
          CustomersCompanion.insert(
            name: name,
            currentBalance: Value(initialBalance),
          ),
        );
  }

  Future<int> insertSupplier(String name, {int initialBalance = 0}) {
    return db.into(db.suppliers).insert(
          SuppliersCompanion.insert(
            name: name,
            currentBalance: Value(initialBalance),
          ),
        );
  }

  Future<int> insertProduct(
    String name, {
    required Decimal currentQuantity,
    int purchasePrice = 1000,
    int salePrice = 1500,
  }) {
    return db.into(db.products).insert(
          ProductsCompanion.insert(
            name: name,
            unit: 'قطعة',
            currentQuantity: Value(currentQuantity),
            currentPurchasePrice: purchasePrice,
            currentSalePrice: salePrice,
          ),
        );
  }

  group('ReturnRepositoryImpl Integration Tests', () {
    test('Customer return restores inventory and reduces customer debt atomically', () async {
      // Customer initially owes 100.00 EGP (10000 piastres)
      final cId = await insertCustomer('عميل مرتجع', initialBalance: 10000);
      final pId = await insertProduct('منتج مرتجع من عميل', currentQuantity: Decimal.fromInt(5));

      final now = DateTime.now();
      final params = CreateCustomerReturnParams(
        customerId: cId,
        returnDate: now,
        note: 'بضاعة معيبة تم إرجاعها',
        items: [
          ReturnItemParam(
            productId: pId,
            quantity: Decimal.fromInt(2),
            unitPrice: const Money(2000), // 2 * 20.00 = 40.00 EGP (4000 piastres)
          ),
        ],
      );

      final result = await repository.createCustomerReturn(params);

      expect(result.isSuccess, isTrue);
      final ret = result.dataOrNull!;
      expect(ret.totalAmount, const Money(4000));
      expect(ret.customerId, cId);
      expect(ret.items.length, 1);

      // Verify product stock increased: 5 + 2 = 7
      final product = await (db.select(db.products)..where((t) => t.id.equals(pId))).getSingle();
      expect(product.currentQuantity, Decimal.fromInt(7));

      // Verify customer debt reduced: 10000 - 4000 = 6000 piastres
      final customer = await (db.select(db.customers)..where((t) => t.id.equals(cId))).getSingle();
      expect(customer.currentBalance, 6000);

      // Verify customer ledger entry recorded
      final ledgerEntries = await (db.select(db.customerLedgerEntries)..where((t) => t.customerId.equals(cId))).get();
      expect(ledgerEntries.length, 1);
      expect(ledgerEntries.first.amount, 4000);
      expect(ledgerEntries.first.effect, 'decrease');
      expect(ledgerEntries.first.entryType, 'return');

      // Verify inventory movement
      final movements = await (db.select(db.inventoryMovements)..where((t) => t.productId.equals(pId))).get();
      expect(movements.length, 1);
      expect(movements.first.movementType, 'customer_return');
      expect(movements.first.quantityDelta, Decimal.fromInt(2));
      expect(movements.first.balanceAfter, Decimal.fromInt(7));

      // Verify audit log
      final logs = await (db.select(db.auditLog)..where((t) => t.entityType.equals('customer_return'))).get();
      expect(logs.length, 1);
      expect(logs.first.action, 'create');
    });

    test('Supplier return deducts inventory and reduces supplier dues atomically', () async {
      // We owe supplier 500.00 EGP (50000 piastres)
      final sId = await insertSupplier('مورد مرتجع', initialBalance: 50000);
      final pId = await insertProduct('منتج مرتجع لمورد', currentQuantity: Decimal.fromInt(10));

      final now = DateTime.now();
      final params = CreateSupplierReturnParams(
        supplierId: sId,
        returnDate: now,
        note: 'إرجاع لمورد لانتهاء الصلاحية',
        items: [
          ReturnItemParam(
            productId: pId,
            quantity: Decimal.fromInt(3),
            unitPrice: const Money(5000), // 3 * 50.00 = 150.00 EGP (15000 piastres)
          ),
        ],
      );

      final result = await repository.createSupplierReturn(params);

      expect(result.isSuccess, isTrue);
      final ret = result.dataOrNull!;
      expect(ret.totalAmount, const Money(15000));
      expect(ret.supplierId, sId);

      // Verify product stock decreased: 10 - 3 = 7
      final product = await (db.select(db.products)..where((t) => t.id.equals(pId))).getSingle();
      expect(product.currentQuantity, Decimal.fromInt(7));

      // Verify supplier dues reduced: 50000 - 15000 = 35000 piastres
      final supplier = await (db.select(db.suppliers)..where((t) => t.id.equals(sId))).getSingle();
      expect(supplier.currentBalance, 35000);

      // Verify supplier ledger entry recorded
      final ledgerEntries = await (db.select(db.supplierLedgerEntries)..where((t) => t.supplierId.equals(sId))).get();
      expect(ledgerEntries.length, 1);
      expect(ledgerEntries.first.amount, 15000);
      expect(ledgerEntries.first.effect, 'decrease');
      expect(ledgerEntries.first.entryType, 'return');

      // Verify inventory movement
      final movements = await (db.select(db.inventoryMovements)..where((t) => t.productId.equals(pId))).get();
      expect(movements.length, 1);
      expect(movements.first.movementType, 'supplier_return');
      expect(movements.first.quantityDelta, Decimal.fromInt(-3));
      expect(movements.first.balanceAfter, Decimal.fromInt(7));

      // Verify audit log
      final logs = await (db.select(db.auditLog)..where((t) => t.entityType.equals('supplier_return'))).get();
      expect(logs.length, 1);
      expect(logs.first.action, 'create');
    });

    test('Supplier return fails with InsufficientStockFailure if quantity exceeds available inventory', () async {
      final sId = await insertSupplier('مورد فحص رصيد', initialBalance: 20000);
      final pId = await insertProduct('منتج غير كاف', currentQuantity: Decimal.fromInt(2));

      final now = DateTime.now();
      final params = CreateSupplierReturnParams(
        supplierId: sId,
        returnDate: now,
        items: [
          ReturnItemParam(
            productId: pId,
            quantity: Decimal.fromInt(5), // 5 > 2
            unitPrice: const Money(1000),
          ),
        ],
      );

      final result = await repository.createSupplierReturn(params);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<InsufficientStockFailure>());

      // Verify inventory untouched
      final product = await (db.select(db.products)..where((t) => t.id.equals(pId))).getSingle();
      expect(product.currentQuantity, Decimal.fromInt(2));

      // Verify supplier balance untouched
      final supplier = await (db.select(db.suppliers)..where((t) => t.id.equals(sId))).getSingle();
      expect(supplier.currentBalance, 20000);

      // Verify no returns created
      final returns = await db.select(db.returnsSupplier).get();
      expect(returns.isEmpty, isTrue);
    });

    test('Customer return exceeding debt turns customer into a creditor (-15 EGP) when credited to account', () async {
      // Customer owes 20 EGP (2000 piastres)
      final cId = await insertCustomer('منصور', initialBalance: 2000);
      final pId = await insertProduct('منتج 35 ج', currentQuantity: Decimal.fromInt(10));

      final now = DateTime.now();
      final params = CreateCustomerReturnParams(
        customerId: cId,
        returnDate: now,
        items: [
          ReturnItemParam(
            productId: pId,
            quantity: Decimal.fromInt(1),
            unitPrice: const Money(3500), // 35.00 EGP
          ),
        ],
        refundCashAmount: Money.zero, // full credit to account
      );

      final result = await repository.createCustomerReturn(params);

      expect(result.isSuccess, isTrue);

      // Customer balance should be 2000 - 3500 = -1500 (-15.00 EGP)
      final customer = await (db.select(db.customers)..where((t) => t.id.equals(cId))).getSingle();
      expect(customer.currentBalance, -1500);

      // Verify customer ledger entry balanceAfter is -1500
      final ledger = await (db.select(db.customerLedgerEntries)..where((t) => t.customerId.equals(cId))).get();
      expect(ledger.length, 1);
      expect(ledger.first.entryType, 'return');
      expect(ledger.first.amount, 3500);
      expect(ledger.first.balanceAfter, -1500);
    });

    test('Customer return with partial cash refund settles debt (20 EGP) and refunds remaining (15 EGP) from cashbox', () async {
      // Seed cashbox with 50.00 EGP
      await db.into(db.cashboxTransactions).insert(
            CashboxTransactionsCompanion.insert(
              transactionType: 'sale_cash_in',
              amount: 5000,
              direction: 'in',
              balanceAfter: 5000,
            ),
          );

      // Customer owes 20 EGP (2000 piastres)
      final cId = await insertCustomer('عميل تسوية', initialBalance: 2000);
      final pId = await insertProduct('صنف 35ج', currentQuantity: Decimal.fromInt(5));

      final now = DateTime.now();
      final params = CreateCustomerReturnParams(
        customerId: cId,
        returnDate: now,
        items: [
          ReturnItemParam(
            productId: pId,
            quantity: Decimal.fromInt(1),
            unitPrice: const Money(3500), // 35.00 EGP
          ),
        ],
        // Settle debt of 2000 and refund remaining 1500 cash
        refundCashAmount: const Money(1500),
      );

      final result = await repository.createCustomerReturn(params);

      expect(result.isSuccess, isTrue);

      // Customer balance should be 2000 - 2000 = 0 (settled)
      final customer = await (db.select(db.customers)..where((t) => t.id.equals(cId))).getSingle();
      expect(customer.currentBalance, 0);

      // Cashbox should have 5000 - 1500 = 3500
      final latestTx = await (db.select(db.cashboxTransactions)
            ..orderBy([(t) => OrderingTerm.desc(t.id)])
            ..limit(1))
          .getSingle();
      expect(latestTx.transactionType, 'customer_return_out');
      expect(latestTx.amount, 1500);
      expect(latestTx.balanceAfter, 3500);
    });
  });
}
