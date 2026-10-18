import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_manager/core/database/app_database.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/result/failures.dart';
import 'package:sales_manager/features/sales/data/daos/sales_dao.dart';
import 'package:sales_manager/features/sales/data/repositories/sale_repository_impl.dart';
import 'package:sales_manager/features/sales/domain/entities/sale.dart';
import 'package:sales_manager/features/sales/domain/repositories/sale_repository.dart';

void main() {
  late AppDatabase db;
  late SalesDao dao;
  late SaleRepository repository;

  setUp(() {
    db = AppDatabase.memory();
    dao = SalesDao(db);
    repository = SaleRepositoryImpl(db: db, dao: dao);
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

  group('SaleRepositoryImpl Integration Tests', () {
    test('Creating a credit sale deducts stock, increases customer debt, and writes movements atomically', () async {
      final cId = await insertCustomer('عميل آجل');
      final pId = await insertProduct('منتج س', currentQuantity: Decimal.fromInt(20));

      final now = DateTime.now();
      final params = CreateSaleParams(
        customerId: cId,
        saleDate: now,
        items: [
          SaleItemParam(
            productId: pId,
            quantity: Decimal.fromInt(5),
            unitPrice: const Money(3000), // 5 * 30.00 = 150.00 EGP (15000 piastres)
          ),
        ],
        paidAmountAtCreation: Money.zero, // Fully on credit
      );

      final result = await repository.createSale(params);

      expect(result.isSuccess, isTrue);
      final sale = result.dataOrNull!;
      expect(sale.invoiceNo, 1);
      expect(sale.totalAmount, const Money(15000));
      expect(sale.remainingAmount, const Money(15000));
      expect(sale.isFullyCredit, isTrue);

      // Verify product stock decreased: 20 - 5 = 15
      final product = await (db.select(db.products)..where((t) => t.id.equals(pId))).getSingle();
      expect(product.currentQuantity, Decimal.fromInt(15));

      // Verify customer balance increased by 15000 piastres (debt)
      final customer = await (db.select(db.customers)..where((t) => t.id.equals(cId))).getSingle();
      expect(customer.currentBalance, 15000);

      // Verify customer ledger entry
      final ledgerEntries = await (db.select(db.customerLedgerEntries)..where((t) => t.customerId.equals(cId))).get();
      expect(ledgerEntries.length, 1);
      expect(ledgerEntries.first.amount, 15000);
      expect(ledgerEntries.first.effect, 'increase');

      // Verify inventory movement
      final movements = await (db.select(db.inventoryMovements)..where((t) => t.productId.equals(pId))).get();
      expect(movements.length, 1);
      expect(movements.first.movementType, 'sale');
      expect(movements.first.quantityDelta, Decimal.fromInt(-5));
      expect(movements.first.balanceAfter, Decimal.fromInt(15));

      // Verify audit log
      final logs = await db.select(db.auditLog).get();
      expect(logs.length, 1);
      expect(logs.first.entityType, 'sale');
      expect(logs.first.action, 'create');
    });

    test('Creating a cash sale updates cashbox balance atomically', () async {
      final cId = await insertCustomer('عميل كاش');
      final pId = await insertProduct('منتج ص', currentQuantity: Decimal.fromInt(10));

      final now = DateTime.now();
      final params = CreateSaleParams(
        customerId: cId,
        saleDate: now,
        items: [
          SaleItemParam(
            productId: pId,
            quantity: Decimal.fromInt(2),
            unitPrice: const Money(2500), // 5000 piastres
          ),
        ],
        paidAmountAtCreation: const Money(5000), // Fully paid
      );

      final result = await repository.createSale(params);

      expect(result.isSuccess, isTrue);
      final sale = result.dataOrNull!;
      expect(sale.isFullyPaid, isTrue);
      expect(sale.remainingAmount, Money.zero);

      // Customer balance should remain 0
      final customer = await (db.select(db.customers)..where((t) => t.id.equals(cId))).getSingle();
      expect(customer.currentBalance, 0);

      // Cashbox transaction should be recorded
      final latestTx = await (db.select(db.cashboxTransactions)
            ..orderBy([(t) => OrderingTerm.desc(t.id)])
            ..limit(1))
          .getSingle();
      expect(latestTx.transactionType, 'sale_cash_in');
      expect(latestTx.direction, 'in');
      expect(latestTx.amount, 5000);
      expect(latestTx.balanceAfter, 5000);
    });

    test('Strict Negative Stock Prevention (Locked Decision #6): Fails if requested quantity exceeds stock', () async {
      final cId = await insertCustomer('عميل تجربة رصيد سالب');
      final pId = await insertProduct('منتج محدود', currentQuantity: Decimal.fromInt(3));

      final now = DateTime.now();
      final params = CreateSaleParams(
        customerId: cId,
        saleDate: now,
        items: [
          SaleItemParam(
            productId: pId,
            quantity: Decimal.fromInt(5), // 5 > 3
            unitPrice: const Money(1000),
          ),
        ],
        paidAmountAtCreation: Money.zero,
      );

      final result = await repository.createSale(params);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<InsufficientStockFailure>());

      // Invariants: Product stock remains exactly 3
      final product = await (db.select(db.products)..where((t) => t.id.equals(pId))).getSingle();
      expect(product.currentQuantity, Decimal.fromInt(3));

      // No sales recorded
      final sales = await db.select(db.sales).get();
      expect(sales.isEmpty, isTrue);

      // No ledger entries
      final ledgers = await db.select(db.customerLedgerEntries).get();
      expect(ledgers.isEmpty, isTrue);
    });

    test('Reversing a sale restores stock, rolls back customer debt and cashbox, and logs action', () async {
      final cId = await insertCustomer('عميل استرجاع فاتورة');
      final pId = await insertProduct('منتج ع', currentQuantity: Decimal.fromInt(15));

      final now = DateTime.now();
      final params = CreateSaleParams(
        customerId: cId,
        saleDate: now,
        items: [
          SaleItemParam(
            productId: pId,
            quantity: Decimal.fromInt(5),
            unitPrice: const Money(2000), // 10000 piastres
          ),
        ],
        paidAmountAtCreation: const Money(4000), // 4000 cash, 6000 credit
      );

      final createRes = await repository.createSale(params);
      expect(createRes.isSuccess, isTrue);
      final saleId = createRes.dataOrNull!.id;

      // Verify initial state after sale
      final prodAfterSale = await (db.select(db.products)..where((t) => t.id.equals(pId))).getSingle();
      expect(prodAfterSale.currentQuantity, Decimal.fromInt(10));

      final custAfterSale = await (db.select(db.customers)..where((t) => t.id.equals(cId))).getSingle();
      expect(custAfterSale.currentBalance, 6000);

      // Now reverse sale
      final reverseRes = await repository.reverseSale(saleId, reason: 'خطأ في الفاتورة');
      expect(reverseRes.isSuccess, isTrue);
      expect(reverseRes.dataOrNull!.status, SaleStatus.reversed);

      // Product stock restored to 15
      final prodAfterReverse = await (db.select(db.products)..where((t) => t.id.equals(pId))).getSingle();
      expect(prodAfterReverse.currentQuantity, Decimal.fromInt(15));

      // Customer debt restored to 0
      final custAfterReverse = await (db.select(db.customers)..where((t) => t.id.equals(cId))).getSingle();
      expect(custAfterReverse.currentBalance, 0);

      // Cashbox has refund transaction (direction: 'out')
      final latestTx = await (db.select(db.cashboxTransactions)
            ..orderBy([(t) => OrderingTerm.desc(t.id)])
            ..limit(1))
          .getSingle();
      expect(latestTx.transactionType, 'sale_reverse_out');
      expect(latestTx.direction, 'out');
      expect(latestTx.amount, 4000);

      // Cannot reverse again
      final doubleReverseRes = await repository.reverseSale(saleId);
      expect(doubleReverseRes.isFailure, isTrue);
      expect(doubleReverseRes.failureOrNull, isA<ConflictFailure>());
    });
  });
}
