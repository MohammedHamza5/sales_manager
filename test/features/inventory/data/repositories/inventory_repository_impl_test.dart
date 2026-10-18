import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_manager/core/database/app_database.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/result/failures.dart';
import 'package:sales_manager/features/inventory/data/daos/inventory_movements_dao.dart';
import 'package:sales_manager/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:sales_manager/features/inventory/domain/entities/inventory_movement.dart';
import 'package:sales_manager/features/products/data/daos/products_dao.dart';
import 'package:sales_manager/features/products/data/repositories/product_repository_impl.dart';

void main() {
  late AppDatabase db;
  late ProductsDao productsDao;
  late InventoryMovementsDao inventoryDao;
  late ProductRepositoryImpl productRepository;
  late InventoryRepositoryImpl inventoryRepository;

  setUp(() {
    db = AppDatabase.memory();
    productsDao = ProductsDao(db);
    inventoryDao = InventoryMovementsDao(db);
    productRepository = ProductRepositoryImpl(db: db, dao: productsDao);
    inventoryRepository = InventoryRepositoryImpl(db: db, dao: inventoryDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('InventoryRepositoryImpl Integration Tests', () {
    test('Product creation with initial stock creates opening balance inventory movement', () async {
      final initialQty = Decimal.parse('50');
      final productResult = await productRepository.addProduct(
        name: 'زيت عباد الشمس 1 لتر',
        unit: 'زجاجة',
        salePrice: const Money.fromPiastres(6500),
        purchasePrice: const Money.fromPiastres(5500),
        initialQuantity: initialQty,
      );

      final product = productResult.dataOrNull!;
      final movementsResult = await inventoryRepository.getMovements(productId: product.id);

      expect(movementsResult.isSuccess, isTrue);
      final movements = movementsResult.dataOrNull!;
      expect(movements.length, 1);
      expect(movements.first.type, MovementType.openingBalance);
      expect(movements.first.quantityDelta, initialQty);
      expect(movements.first.balanceAfter, initialQty);
      expect(movements.first.productName, 'زيت عباد الشمس 1 لتر');
    });

    test('Positive stock adjustment updates quantity, records movement, adjustment row, and audit log atomically', () async {
      final productResult = await productRepository.addProduct(
        name: 'مكرونة 400 جم',
        unit: 'كيس',
        salePrice: const Money.fromPiastres(1200),
        purchasePrice: const Money.fromPiastres(900),
        initialQuantity: Decimal.parse('20'),
      );
      final product = productResult.dataOrNull!;

      // Add +15 items via manual adjustment
      final adjResult = await inventoryRepository.recordAdjustment(
        productId: product.id,
        quantityDelta: Decimal.parse('15'),
        reason: 'فروقات جرد عيني سنوي',
      );

      expect(adjResult.isSuccess, isTrue);
      final movement = adjResult.dataOrNull!;
      expect(movement.type, MovementType.adjustment);
      expect(movement.quantityDelta, Decimal.parse('15'));
      expect(movement.balanceAfter, Decimal.parse('35')); // 20 + 15

      // Verify product table current_quantity cache updated
      final updatedProduct = (await productRepository.getProductById(product.id)).dataOrNull!;
      expect(updatedProduct.currentQuantity, Decimal.parse('35'));

      // Verify audit log
      final auditList = await (db.select(db.auditLog)..where((tbl) => tbl.action.equals('create'))).get();
      expect(auditList.any((a) => a.entityType == 'stock_adjustment'), isTrue);
    });

    test('Negative stock adjustment updates quantity correctly', () async {
      final productResult = await productRepository.addProduct(
        name: 'بسكويت سادة',
        unit: 'علبة',
        salePrice: const Money.fromPiastres(500),
        purchasePrice: const Money.fromPiastres(350),
        initialQuantity: Decimal.parse('30'),
      );
      final product = productResult.dataOrNull!;

      // Decrement by -8 items (e.g. damaged goods)
      final adjResult = await inventoryRepository.recordAdjustment(
        productId: product.id,
        quantityDelta: Decimal.parse('-8'),
        reason: 'أصناف تالفة بسبب سوء التخزين',
      );

      expect(adjResult.isSuccess, isTrue);
      final movement = adjResult.dataOrNull!;
      expect(movement.quantityDelta, Decimal.parse('-8'));
      expect(movement.balanceAfter, Decimal.parse('22')); // 30 - 8

      final updatedProduct = (await productRepository.getProductById(product.id)).dataOrNull!;
      expect(updatedProduct.currentQuantity, Decimal.parse('22'));
    });

    test('Negative stock adjustment exceeding available stock is strictly rejected (No negative stock)', () async {
      final productResult = await productRepository.addProduct(
        name: 'تونة قطع',
        unit: 'علبة',
        salePrice: const Money.fromPiastres(4000),
        purchasePrice: const Money.fromPiastres(3200),
        initialQuantity: Decimal.parse('5'),
      );
      final product = productResult.dataOrNull!;

      // Attempt to deduct 10 when only 5 exist
      final adjResult = await inventoryRepository.recordAdjustment(
        productId: product.id,
        quantityDelta: Decimal.parse('-10'),
        reason: 'عجز جرد',
      );

      expect(adjResult.isFailure, isTrue);
      expect(adjResult.failureOrNull, isA<InsufficientStockFailure>());

      // Product stock remains untouched (5)
      final checkProduct = (await productRepository.getProductById(product.id)).dataOrNull!;
      expect(checkProduct.currentQuantity, Decimal.parse('5'));
    });

    test('Stock adjustment with empty reason is rejected', () async {
      final productResult = await productRepository.addProduct(
        name: 'لبن معقم',
        unit: 'علبة',
        salePrice: const Money.fromPiastres(3500),
        purchasePrice: const Money.fromPiastres(2800),
        initialQuantity: Decimal.parse('10'),
      );
      final product = productResult.dataOrNull!;

      final adjResult = await inventoryRepository.recordAdjustment(
        productId: product.id,
        quantityDelta: Decimal.parse('2'),
        reason: '   ',
      );

      expect(adjResult.isFailure, isTrue);
      expect(adjResult.failureOrNull, isA<ValidationFailure>());
    });

    test('Watch movements stream reacts dynamically to new movements', () async {
      final productResult = await productRepository.addProduct(
        name: 'شاي أسود',
        unit: 'علبة',
        salePrice: const Money.fromPiastres(2000),
        purchasePrice: const Money.fromPiastres(1500),
        initialQuantity: Decimal.zero,
      );
      final product = productResult.dataOrNull!;

      final stream = inventoryRepository.watchMovements(productId: product.id);

      expect(await stream.first, isEmpty);

      // Record adjustment
      await inventoryRepository.recordAdjustment(
        productId: product.id,
        quantityDelta: Decimal.parse('12'),
        reason: 'إضافة رصيد',
      );

      final nextEmission = await stream.firstWhere((list) => list.isNotEmpty);
      expect(nextEmission.length, 1);
      expect(nextEmission.first.quantityDelta, Decimal.parse('12'));
    });
  });
}
