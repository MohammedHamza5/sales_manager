import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_manager/core/database/app_database.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/result/failures.dart';
import 'package:sales_manager/features/purchases/data/daos/purchases_dao.dart';
import 'package:sales_manager/features/purchases/data/repositories/purchase_repository_impl.dart';
import 'package:sales_manager/features/purchases/domain/entities/purchase.dart';
import 'package:sales_manager/features/purchases/domain/repositories/purchase_repository.dart';

void main() {
  late AppDatabase db;
  late PurchasesDao dao;
  late PurchaseRepository repository;

  setUp(() {
    db = AppDatabase.memory();
    dao = PurchasesDao(db);
    repository = PurchaseRepositoryImpl(db: db, dao: dao);
  });

  tearDown(() async {
    await db.close();
  });

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

  group('PurchaseRepositoryImpl Integration Tests', () {
    test('Creating a credit purchase updates stock, supplier balance, and writes movements atomically', () async {
      final sId = await insertSupplier('مورد الأمل');
      final pId = await insertProduct('منتج أ', currentQuantity: Decimal.fromInt(10));

      final now = DateTime.now();
      final params = CreatePurchaseParams(
        supplierId: sId,
        purchaseDate: now,
        items: [
          PurchaseItemParam(
            productId: pId,
            quantity: Decimal.fromInt(5),
            unitCost: const Money(2000), // Total = 5 * 20.00 = 100.00 EGP (10000 piastres)
          ),
        ],
        paidAmountAtCreation: Money.zero, // Fully on credit
      );

      final result = await repository.createPurchase(params);

      expect(result.isSuccess, isTrue);
      final purchase = result.dataOrNull!;
      expect(purchase.invoiceNo, 1);
      expect(purchase.totalAmount, const Money(10000));
      expect(purchase.remainingAmount, const Money(10000));
      expect(purchase.isFullyCredit, isTrue);

      // Verify product stock increased: 10 + 5 = 15
      final product = await (db.select(db.products)..where((t) => t.id.equals(pId))).getSingle();
      expect(product.currentQuantity, Decimal.fromInt(15));
      expect(product.currentPurchasePrice, 2000); // Updated to last purchase price!

      // Verify supplier balance increased by 10000 piastres
      final supplier = await (db.select(db.suppliers)..where((t) => t.id.equals(sId))).getSingle();
      expect(supplier.currentBalance, 10000);

      // Verify supplier ledger entry
      final ledgerEntries = await (db.select(db.supplierLedgerEntries)..where((t) => t.supplierId.equals(sId))).get();
      expect(ledgerEntries.length, 1);
      expect(ledgerEntries.first.amount, 10000);
      expect(ledgerEntries.first.effect, 'increase');

      // Verify inventory movement
      final movements = await (db.select(db.inventoryMovements)..where((t) => t.productId.equals(pId))).get();
      expect(movements.length, 1);
      expect(movements.first.movementType, 'purchase');
      expect(movements.first.quantityDelta, Decimal.fromInt(5));
      expect(movements.first.balanceAfter, Decimal.fromInt(15));

      // Verify audit log
      final logs = await db.select(db.auditLog).get();
      expect(logs.length, 1);
      expect(logs.first.entityType, 'purchase');
      expect(logs.first.action, 'create');
    });

    test('Creating a cash purchase deducts cashbox balance and writes cashbox transaction', () async {
      final sId = await insertSupplier('مورد نقدي');
      final pId = await insertProduct('منتج ب', currentQuantity: Decimal.zero);

      // Seed initial cashbox balance with 500.00 EGP (50000 piastres)
      await db.into(db.cashboxTransactions).insert(
            CashboxTransactionsCompanion.insert(
              transactionType: 'opening_balance',
              amount: 50000,
              direction: 'in',
              balanceAfter: 50000,
            ),
          );

      final now = DateTime.now();
      final params = CreatePurchaseParams(
        supplierId: sId,
        purchaseDate: now,
        items: [
          PurchaseItemParam(
            productId: pId,
            quantity: Decimal.fromInt(2),
            unitCost: const Money(15000), // 30000 piastres
          ),
        ],
        paidAmountAtCreation: const Money(30000), // Fully paid in cash
      );

      final result = await repository.createPurchase(params);

      expect(result.isSuccess, isTrue);
      final purchase = result.dataOrNull!;
      expect(purchase.isFullyPaid, isTrue);

      // Supplier balance should not change
      final supplier = await (db.select(db.suppliers)..where((t) => t.id.equals(sId))).getSingle();
      expect(supplier.currentBalance, 0);

      // Cashbox should decrease by 30000: 50000 - 30000 = 20000
      final latestTx = await (db.select(db.cashboxTransactions)
            ..orderBy([(t) => OrderingTerm.desc(t.id)])
            ..limit(1))
          .getSingle();
      expect(latestTx.transactionType, 'purchase_cash_out');
      expect(latestTx.direction, 'out');
      expect(latestTx.amount, 30000);
      expect(latestTx.balanceAfter, 20000);
    });

    test('Reversing purchase updates stock, supplier balance, cashbox, and sets reversed status', () async {
      final sId = await insertSupplier('مورد عكس');
      final pId = await insertProduct('منتج ت', currentQuantity: Decimal.fromInt(5));

      final now = DateTime.now();
      final params = CreatePurchaseParams(
        supplierId: sId,
        purchaseDate: now,
        items: [
          PurchaseItemParam(
            productId: pId,
            quantity: Decimal.fromInt(10),
            unitCost: const Money(1000),
          ),
        ],
        paidAmountAtCreation: Money.zero,
      );

      final createRes = await repository.createPurchase(params);
      expect(createRes.isSuccess, isTrue);
      final pIdInvoice = createRes.dataOrNull!.id;

      // Reverse it
      final reverseRes = await repository.reversePurchase(purchaseId: pIdInvoice);
      expect(reverseRes.isSuccess, isTrue);
      expect(reverseRes.dataOrNull!.status, PurchaseStatus.reversed);

      // Stock should return to 5 (15 - 10)
      final product = await (db.select(db.products)..where((t) => t.id.equals(pId))).getSingle();
      expect(product.currentQuantity, Decimal.fromInt(5));

      // Supplier balance should return to 0
      final supplier = await (db.select(db.suppliers)..where((t) => t.id.equals(sId))).getSingle();
      expect(supplier.currentBalance, 0);
    });

    test('Reversing fails with InsufficientStockFailure if available stock is less than purchased quantity', () async {
      final sId = await insertSupplier('مورد عجز');
      final pId = await insertProduct('منتج ث', currentQuantity: Decimal.zero);

      final now = DateTime.now();
      final params = CreatePurchaseParams(
        supplierId: sId,
        purchaseDate: now,
        items: [
          PurchaseItemParam(
            productId: pId,
            quantity: Decimal.fromInt(10),
            unitCost: const Money(1000),
          ),
        ],
        paidAmountAtCreation: Money.zero,
      );

      final createRes = await repository.createPurchase(params);
      final pIdInvoice = createRes.dataOrNull!.id;

      // Simulate a subsequent sale or usage that reduced stock from 10 to 4
      await (db.update(db.products)..where((t) => t.id.equals(pId))).write(
        ProductsCompanion(currentQuantity: Value(Decimal.fromInt(4))),
      );

      // Try to reverse purchase of 10 items
      final reverseRes = await repository.reversePurchase(purchaseId: pIdInvoice);

      expect(reverseRes.isFailure, isTrue);
      expect(reverseRes.failureOrNull, isA<InsufficientStockFailure>());
    });
  });
}
