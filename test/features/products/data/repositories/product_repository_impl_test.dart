import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_manager/core/database/app_database.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/features/products/data/daos/products_dao.dart';
import 'package:sales_manager/features/products/data/repositories/product_repository_impl.dart';

void main() {
  late AppDatabase db;
  late ProductsDao dao;
  late ProductRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.memory();
    dao = ProductsDao(db);
    repository = ProductRepositoryImpl(db: db, dao: dao);
  });

  tearDown(() async {
    await db.close();
  });

  group('ProductRepositoryImpl Integration Tests', () {
    test('Adding product without initial quantity creates product and audit log, NO inventory movement', () async {
      final result = await repository.addProduct(
        name: 'شيبسي عائلي',
        code: 'CHIPS-01',
        unit: 'كيس',
        salePrice: const Money.fromPiastres(1500), // 15.00 ج.م
        purchasePrice: const Money.fromPiastres(1200), // 12.00 ج.م
        initialQuantity: Decimal.zero,
      );

      expect(result.isSuccess, isTrue);
      final product = result.dataOrNull!;
      expect(product.id, isPositive);
      expect(product.name, 'شيبسي عائلي');
      expect(product.currentQuantity, Decimal.zero);

      // Verify NO inventory movement created
      final movements = await db.select(db.inventoryMovements).get();
      expect(movements, isEmpty);

      // Verify Audit Log created
      final auditEntries = await db.select(db.auditLog).get();
      expect(auditEntries.length, 1);
      expect(auditEntries.first.entityType, 'product');
      expect(auditEntries.first.action, 'create');
      expect(auditEntries.first.entityId, product.id);
    });

    test('Adding product WITH initial quantity creates opening balance movement and audit log atomically', () async {
      final initialQty = Decimal.parse('25.5');
      final result = await repository.addProduct(
        name: 'أرز فاخر',
        code: 'RICE-01',
        unit: 'كيلو',
        salePrice: const Money.fromPiastres(3000),
        purchasePrice: const Money.fromPiastres(2400),
        initialQuantity: initialQty,
        lowStockThreshold: Decimal.parse('5'),
      );

      expect(result.isSuccess, isTrue);
      final product = result.dataOrNull!;
      expect(product.currentQuantity, initialQty);

      // Verify inventory movement recorded with opening_balance
      final movements = await db.select(db.inventoryMovements).get();
      expect(movements.length, 1);
      final movement = movements.first;
      expect(movement.productId, product.id);
      expect(movement.movementType, 'opening_balance');
      expect(movement.quantityDelta, initialQty);
      expect(movement.balanceAfter, initialQty);

      // Verify Audit Log
      final auditEntries = await db.select(db.auditLog).get();
      expect(auditEntries.length, 1);
      expect(auditEntries.first.entityId, product.id);
    });

    test('Search products by Arabic name and code', () async {
      await repository.addProduct(
        name: 'عصير برتقال',
        code: 'JUICE-ORG',
        unit: 'علبة',
        salePrice: const Money.fromPiastres(1000),
        purchasePrice: const Money.fromPiastres(800),
      );

      await repository.addProduct(
        name: 'عصير تفاح',
        code: 'JUICE-APP',
        unit: 'علبة',
        salePrice: const Money.fromPiastres(1000),
        purchasePrice: const Money.fromPiastres(800),
      );

      await repository.addProduct(
        name: 'مياه معدنية',
        code: 'WATER-01',
        unit: 'زجاجة',
        salePrice: const Money.fromPiastres(500),
        purchasePrice: const Money.fromPiastres(350),
      );

      // Search by Arabic text "عصير"
      final searchResult = await repository.getProducts(query: 'عصير');
      expect(searchResult.isSuccess, isTrue);
      expect(searchResult.dataOrNull?.length, 2);

      // Search by Code "WATER"
      final codeResult = await repository.getProducts(query: 'WATER');
      expect(codeResult.isSuccess, isTrue);
      expect(codeResult.dataOrNull?.length, 1);
      expect(codeResult.dataOrNull?.first.name, 'مياه معدنية');
    });

    test('Filter low stock products accurately', () async {
      // Product 1: Low stock (current: 3 <= threshold: 5)
      await repository.addProduct(
        name: 'تونة قطعة واحدة',
        unit: 'علبة',
        salePrice: const Money.fromPiastres(4500),
        purchasePrice: const Money.fromPiastres(3800),
        initialQuantity: Decimal.parse('3'),
        lowStockThreshold: Decimal.parse('5'),
      );

      // Product 2: Abundant stock (current: 20 > threshold: 5)
      await repository.addProduct(
        name: 'تونة مفتتة',
        unit: 'علبة',
        salePrice: const Money.fromPiastres(2500),
        purchasePrice: const Money.fromPiastres(2000),
        initialQuantity: Decimal.parse('20'),
        lowStockThreshold: Decimal.parse('5'),
      );

      final lowStockResult = await repository.getProducts(isLowStockOnly: true);
      expect(lowStockResult.isSuccess, isTrue);
      final items = lowStockResult.dataOrNull!;
      expect(items.length, 1);
      expect(items.first.name, 'تونة قطعة واحدة');
      expect(items.first.isLowStock, isTrue);
    });

    test('Toggle product status (deactivate and reactivate) without deletion', () async {
      final createResult = await repository.addProduct(
        name: 'منتج مؤقت',
        unit: 'قطعة',
        salePrice: const Money.fromPiastres(1000),
        purchasePrice: const Money.fromPiastres(700),
      );
      final productId = createResult.dataOrNull!.id;

      // Deactivate
      await repository.toggleProductStatus(productId, false);

      final activeOnly = await repository.getProducts(isActiveOnly: true);
      expect(activeOnly.dataOrNull?.any((p) => p.id == productId), isFalse);

      final allProducts = await repository.getProducts(isActiveOnly: false);
      expect(allProducts.dataOrNull?.any((p) => p.id == productId), isTrue);

      // Reactivate
      await repository.toggleProductStatus(productId, true);
      final activeAgain = await repository.getProducts(isActiveOnly: true);
      expect(activeAgain.dataOrNull?.any((p) => p.id == productId), isTrue);
    });

    test('Updating product updates fields and creates audit log with before/after', () async {
      final created = (await repository.addProduct(
        name: 'شوكولاتة دارك',
        code: 'CHOC-01',
        unit: 'قطعة',
        salePrice: const Money.fromPiastres(2000),
        purchasePrice: const Money.fromPiastres(1500),
      )).dataOrNull!;

      final updatedProduct = created.copyWith(
        name: 'شوكولاتة دارك 70%',
        currentSalePrice: const Money.fromPiastres(2500),
      );

      final updateResult = await repository.updateProduct(updatedProduct);
      expect(updateResult.isSuccess, isTrue);

      final fetched = (await repository.getProductById(created.id)).dataOrNull!;
      expect(fetched.name, 'شوكولاتة دارك 70%');
      expect(fetched.currentSalePrice.piastres, 2500);

      // Check audit log
      final auditLogs = await (db.select(db.auditLog)..where((tbl) => tbl.action.equals('update'))).get();
      expect(auditLogs.length, 1);
      expect(auditLogs.first.payloadBefore, contains('شوكولاتة دارك'));
      expect(auditLogs.first.payloadAfter, contains('شوكولاتة دارك 70%'));
    });

    test('Watch products stream emits updates when products are added', () async {
      final stream = repository.watchProducts();

      // 1. Initial emission is empty
      expect(await stream.first, isEmpty);

      // 2. Add product
      await repository.addProduct(
        name: 'نسكافيه بلاك',
        unit: 'برطمان',
        salePrice: const Money.fromPiastres(12000),
        purchasePrice: const Money.fromPiastres(9500),
      );

      // 3. Reactive emission receives the updated list
      final updatedList = await stream.firstWhere((list) => list.isNotEmpty);
      expect(updatedList.length, 1);
      expect(updatedList.first.name, 'نسكافيه بلاك');
    });
  });
}
