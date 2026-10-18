import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_manager/core/database/app_database.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/result/failures.dart';
import 'package:sales_manager/features/cashbox/data/daos/cashbox_dao.dart';
import 'package:sales_manager/features/cashbox/data/repositories/cashbox_repository_impl.dart';
import 'package:sales_manager/features/customer_payments/data/daos/customer_payments_dao.dart';
import 'package:sales_manager/features/customer_payments/data/repositories/customer_payment_repository_impl.dart';
import 'package:sales_manager/features/customer_payments/domain/repositories/customer_payment_repository.dart';
import 'package:sales_manager/features/expenses/data/daos/expenses_dao.dart';
import 'package:sales_manager/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:sales_manager/features/expenses/domain/repositories/expense_repository.dart';
import 'package:sales_manager/features/inventory/data/daos/inventory_movements_dao.dart';
import 'package:sales_manager/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:sales_manager/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:sales_manager/features/opening_balance/data/repositories/opening_balance_repository_impl.dart';
import 'package:sales_manager/features/opening_balance/domain/entities/opening_balance_input.dart';
import 'package:sales_manager/features/opening_balance/domain/repositories/opening_balance_repository.dart';
import 'package:sales_manager/features/purchases/data/daos/purchases_dao.dart';
import 'package:sales_manager/features/purchases/data/repositories/purchase_repository_impl.dart';
import 'package:sales_manager/features/purchases/domain/repositories/purchase_repository.dart';
import 'package:sales_manager/features/reports/data/repositories/report_repository_impl.dart';
import 'package:sales_manager/features/reports/domain/repositories/report_repository.dart';
import 'package:sales_manager/features/returns/data/daos/returns_dao.dart';
import 'package:sales_manager/features/returns/data/repositories/return_repository_impl.dart';
import 'package:sales_manager/features/returns/domain/repositories/return_repository.dart';
import 'package:sales_manager/features/sales/data/daos/sales_dao.dart';
import 'package:sales_manager/features/sales/data/repositories/sale_repository_impl.dart';
import 'package:sales_manager/features/sales/domain/repositories/sale_repository.dart';
import 'package:sales_manager/features/supplier_payments/data/daos/supplier_payments_dao.dart';
import 'package:sales_manager/features/supplier_payments/data/repositories/supplier_payment_repository_impl.dart';
import 'package:sales_manager/features/supplier_payments/domain/repositories/supplier_payment_repository.dart';

void main() {
  late AppDatabase db;
  late SaleRepository saleRepo;
  late PurchaseRepository purchaseRepo;
  late ReturnRepository returnRepo;
  late CustomerPaymentRepository customerPaymentRepo;
  late SupplierPaymentRepository supplierPaymentRepo;
  late ExpenseRepository expenseRepo;
  late InventoryRepository inventoryRepo;
  late OpeningBalanceRepository openingBalanceRepo;
  late CashboxRepositoryImpl cashboxRepo;
  late ReportRepository reportRepo;

  setUp(() {
    db = AppDatabase.memory();

    final salesDao = SalesDao(db);
    saleRepo = SaleRepositoryImpl(db: db, dao: salesDao);

    final purchasesDao = PurchasesDao(db);
    purchaseRepo = PurchaseRepositoryImpl(db: db, dao: purchasesDao);

    final returnsDao = ReturnsDao(db);
    returnRepo = ReturnRepositoryImpl(db: db, dao: returnsDao);

    final customerPaymentsDao = CustomerPaymentsDao(db);
    customerPaymentRepo = CustomerPaymentRepositoryImpl(db: db, dao: customerPaymentsDao);

    final supplierPaymentsDao = SupplierPaymentsDao(db);
    supplierPaymentRepo = SupplierPaymentRepositoryImpl(db: db, dao: supplierPaymentsDao);

    final expensesDao = ExpensesDao(db);
    expenseRepo = ExpenseRepositoryImpl(db: db, dao: expensesDao);

    final inventoryDao = InventoryMovementsDao(db);
    inventoryRepo = InventoryRepositoryImpl(db: db, dao: inventoryDao);

    openingBalanceRepo = OpeningBalanceRepositoryImpl(db);

    final cashboxDao = CashboxDao(db);
    cashboxRepo = CashboxRepositoryImpl(cashboxDao);

    reportRepo = ReportRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  // Helpers
  Future<int> addCustomer(String name, {int initialBalance = 0}) {
    return db.into(db.customers).insert(
          CustomersCompanion.insert(
            name: name,
            currentBalance: Value(initialBalance),
          ),
        );
  }

  Future<int> addSupplier(String name, {int initialBalance = 0}) {
    return db.into(db.suppliers).insert(
          SuppliersCompanion.insert(
            name: name,
            currentBalance: Value(initialBalance),
          ),
        );
  }

  Future<int> addProduct(
    String name, {
    required Decimal currentQuantity,
    int purchasePrice = 1000, // 10.00 EGP
    int salePrice = 1500, // 15.00 EGP
    String unit = 'قطعة',
  }) {
    return db.into(db.products).insert(
          ProductsCompanion.insert(
            name: name,
            unit: unit,
            currentQuantity: Value(currentQuantity),
            currentPurchasePrice: purchasePrice,
            currentSalePrice: salePrice,
          ),
        );
  }

  Future<void> seedCashbox(int amountPiastres) async {
    await db.into(db.cashboxTransactions).insert(
          CashboxTransactionsCompanion.insert(
            transactionType: 'opening_balance',
            amount: amountPiastres,
            direction: 'in',
            balanceAfter: amountPiastres,
            note: const Value('رصيد افتتاحي للاختبارات'),
          ),
        );
  }

  Future<int> getCashboxBalance() async {
    final res = await cashboxRepo.getCurrentBalance();
    return res.dataOrNull?.piastres ?? 0;
  }

  Future<int> getCustomerBalance(int id) async {
    final c = await (db.select(db.customers)..where((t) => t.id.equals(id))).getSingle();
    return c.currentBalance;
  }

  Future<int> getSupplierBalance(int id) async {
    final s = await (db.select(db.suppliers)..where((t) => t.id.equals(id))).getSingle();
    return s.currentBalance;
  }

  Future<Decimal> getProductStock(int id) async {
    final p = await (db.select(db.products)..where((t) => t.id.equals(id))).getSingle();
    return p.currentQuantity;
  }

  // =========================================================================
  // DOMAIN 1: المبيعات والعملاء والكميات والخصومات (Scenarios 1 - 10)
  // =========================================================================
  group('المجال 1: دورة المبيعات والعملاء (10 سيناريوهات)', () {
    test('سيناريو 1: بيع نقدي 100% لعميل - زيادة الخزينة وخصم المخزون دون دين', () async {
      await seedCashbox(5000); // 50.00
      final cId = await addCustomer('عميل كاش');
      final pId = await addProduct('شاي', currentQuantity: Decimal.fromInt(20), salePrice: 2500);

      final res = await saleRepo.createSale(
        CreateSaleParams(
          customerId: cId,
          saleDate: DateTime.now(),
          items: [
            SaleItemParam(productId: pId, quantity: Decimal.fromInt(4), unitPrice: const Money(2500)),
          ],
          paidAmountAtCreation: const Money(10000), // 4 * 25 = 100 EGP (10000 piastres)
        ),
      );

      expect(res.isSuccess, isTrue);
      expect(await getCashboxBalance(), 15000); // 50 + 100 = 150 EGP
      expect(await getProductStock(pId), Decimal.fromInt(16));
      expect(await getCustomerBalance(cId), 0); // لا مديونية
    });

    test('سيناريو 2: بيع آجل 100% - زيادة مديونية العميل دون مساس الخزينة', () async {
      await seedCashbox(5000);
      final cId = await addCustomer('عميل آجل');
      final pId = await addProduct('سكر', currentQuantity: Decimal.fromInt(10), salePrice: 3000);

      final res = await saleRepo.createSale(
        CreateSaleParams(
          customerId: cId,
          saleDate: DateTime.now(),
          items: [
            SaleItemParam(productId: pId, quantity: Decimal.fromInt(2), unitPrice: const Money(3000)),
          ],
          paidAmountAtCreation: Money.zero,
        ),
      );

      expect(res.isSuccess, isTrue);
      expect(await getCashboxBalance(), 5000); // لم تتغير الخزينة
      expect(await getProductStock(pId), Decimal.fromInt(8));
      expect(await getCustomerBalance(cId), 6000); // دين 60.00 EGP
    });

    test('سيناريو 3: بيع بدفعة جزئية (كاش + متبقي آجل) بدقة القرش', () async {
      await seedCashbox(10000);
      final cId = await addCustomer('عميل جزئي');
      final pId = await addProduct('زيت', currentQuantity: Decimal.fromInt(15), salePrice: 5000);

      // فاتورة 3 زجاجات = 150.00 EGP (15000 قرش)، دفع 70.00 EGP (7000 قرش)، متبقي 80.00 EGP (8000 قرش)
      final res = await saleRepo.createSale(
        CreateSaleParams(
          customerId: cId,
          saleDate: DateTime.now(),
          items: [
            SaleItemParam(productId: pId, quantity: Decimal.fromInt(3), unitPrice: const Money(5000)),
          ],
          paidAmountAtCreation: const Money(7000),
        ),
      );

      expect(res.isSuccess, isTrue);
      expect(await getCashboxBalance(), 17000); // 100 + 70 = 170 EGP
      expect(await getProductStock(pId), Decimal.fromInt(12));
      expect(await getCustomerBalance(cId), 8000); // دين 80.00 EGP
    });

    test('سيناريو 4: بيع مع تسعير مخفض مخصص للبند (خصم على سعر البيع)', () async {
      final cId = await addCustomer('عميل بخصم');
      final pId = await addProduct('مكرونة', currentQuantity: Decimal.fromInt(50), salePrice: 1500);

      // السعر الأصلي 15.00، بيعت بسعر ترويجي 12.50 (1250 قرش)
      final res = await saleRepo.createSale(
        CreateSaleParams(
          customerId: cId,
          saleDate: DateTime.now(),
          items: [
            SaleItemParam(productId: pId, quantity: Decimal.fromInt(10), unitPrice: const Money(1250)),
          ],
          paidAmountAtCreation: const Money(12500),
        ),
      );

      expect(res.isSuccess, isTrue);
      expect(res.dataOrNull!.totalAmount, const Money(12500));
      expect(await getProductStock(pId), Decimal.fromInt(40));
    });

    test('سيناريو 5: كميات كسرية دقيقة جداً (مثل 1.750 كجم أو 0.333 طن)', () async {
      final cId = await addCustomer('عميل كسر');
      final pId = await addProduct('جبن رومي بالكيلو', currentQuantity: Decimal.parse('10.500'), salePrice: 32000, unit: 'كجم');

      // شراء 2.350 كجم بسعر 320.00 EGP للكيلو = 752.00 EGP (75200 قرش)
      final res = await saleRepo.createSale(
        CreateSaleParams(
          customerId: cId,
          saleDate: DateTime.now(),
          items: [
            SaleItemParam(productId: pId, quantity: Decimal.parse('2.350'), unitPrice: const Money(32000)),
          ],
          paidAmountAtCreation: const Money(75200),
        ),
      );

      expect(res.isSuccess, isTrue);
      expect(res.dataOrNull!.totalAmount, const Money(75200));
      expect(await getProductStock(pId), Decimal.parse('8.150')); // 10.500 - 2.350 = 8.150
    });

    test('سيناريو 6: منع البيع فوق الرصيد المتاح (منع المخزون السالب)', () async {
      final cId = await addCustomer('عميل طلب زائد');
      final pId = await addProduct('أرز', currentQuantity: Decimal.fromInt(5), salePrice: 2000);

      // محاولة بيع 6 بينما المتوفر 5
      final res = await saleRepo.createSale(
        CreateSaleParams(
          customerId: cId,
          saleDate: DateTime.now(),
          items: [
            SaleItemParam(productId: pId, quantity: Decimal.fromInt(6), unitPrice: const Money(2000)),
          ],
          paidAmountAtCreation: Money.zero,
        ),
      );

      expect(res.isFailure, isTrue);
      expect(res.failureOrNull, isA<InsufficientStockFailure>());
      expect(await getProductStock(pId), Decimal.fromInt(5)); // لم يمس
      expect(await getCustomerBalance(cId), 0); // لم يتأثر
    });

    test('سيناريو 7: بيع لعميل له رصيد دائن سابق (له فلوس عند المحل)', () async {
      // رصيد سالب يعني المحل مدين للعميل بـ 50.00 EGP (-5000 قرش)
      final cId = await addCustomer('عميل دائن', initialBalance: -5000);
      final pId = await addProduct('تونة', currentQuantity: Decimal.fromInt(10), salePrice: 4000);

      // فاتورة بقيمة 80.00 EGP (8000 قرش) على الآجل بالكامل
      final res = await saleRepo.createSale(
        CreateSaleParams(
          customerId: cId,
          saleDate: DateTime.now(),
          items: [
            SaleItemParam(productId: pId, quantity: Decimal.fromInt(2), unitPrice: const Money(4000)),
          ],
          paidAmountAtCreation: Money.zero,
        ),
      );

      expect(res.isSuccess, isTrue);
      // رصيد العميل يجب أن يصبح -5000 + 8000 = +3000 قرش (مدين بـ 30.00 EGP فقط)
      expect(await getCustomerBalance(cId), 3000);
    });

    test('سيناريو 8: سلة مبيعات متعددة الأصناف بأحجام وأسعار مختلفة', () async {
      final cId = await addCustomer('عميل سلة');
      final p1 = await addProduct('صنف 1', currentQuantity: Decimal.fromInt(10), salePrice: 1000);
      final p2 = await addProduct('صنف 2', currentQuantity: Decimal.fromInt(10), salePrice: 2550);
      final p3 = await addProduct('صنف 3', currentQuantity: Decimal.fromInt(10), salePrice: 500);

      // (2 * 1000 = 2000) + (3 * 2550 = 7650) + (5 * 500 = 2500) = 12150 قرش (121.50 EGP)
      final res = await saleRepo.createSale(
        CreateSaleParams(
          customerId: cId,
          saleDate: DateTime.now(),
          items: [
            SaleItemParam(productId: p1, quantity: Decimal.fromInt(2), unitPrice: const Money(1000)),
            SaleItemParam(productId: p2, quantity: Decimal.fromInt(3), unitPrice: const Money(2550)),
            SaleItemParam(productId: p3, quantity: Decimal.fromInt(5), unitPrice: const Money(500)),
          ],
          paidAmountAtCreation: const Money(12150),
        ),
      );

      expect(res.isSuccess, isTrue);
      expect(res.dataOrNull!.totalAmount, const Money(12150));
      expect(await getProductStock(p1), Decimal.fromInt(8));
      expect(await getProductStock(p2), Decimal.fromInt(7));
      expect(await getProductStock(p3), Decimal.fromInt(5));
    });

    test('سيناريو 9: بيع بسعر التكلفة أو بهامش ربح صفري', () async {
      final cId = await addCustomer('عميل تكلفة');
      final pId = await addProduct('سلعة تموينية', currentQuantity: Decimal.fromInt(10), purchasePrice: 2000, salePrice: 2000);

      final res = await saleRepo.createSale(
        CreateSaleParams(
          customerId: cId,
          saleDate: DateTime.now(),
          items: [
            SaleItemParam(productId: pId, quantity: Decimal.fromInt(1), unitPrice: const Money(2000)),
          ],
          paidAmountAtCreation: const Money(2000),
        ),
      );

      expect(res.isSuccess, isTrue);
      expect(res.dataOrNull!.totalAmount, const Money(2000));
    });

    test('سيناريو 10: إلغاء وعكس فاتورة بيع (Sale Reversal) ورد المخزون والمالية بدقة', () async {
      await seedCashbox(10000);
      final cId = await addCustomer('عميل إلغاء');
      final pId = await addProduct('حليب', currentQuantity: Decimal.fromInt(20), salePrice: 3500);

      // بيع 5 علب نقداً = 17500 قرش
      final createRes = await saleRepo.createSale(
        CreateSaleParams(
          customerId: cId,
          saleDate: DateTime.now(),
          items: [
            SaleItemParam(productId: pId, quantity: Decimal.fromInt(5), unitPrice: const Money(3500)),
          ],
          paidAmountAtCreation: const Money(17500),
        ),
      );
      final saleId = createRes.dataOrNull!.id;
      expect(await getProductStock(pId), Decimal.fromInt(15));
      expect(await getCashboxBalance(), 27500);

      // عكس الفاتورة
      final revRes = await saleRepo.reverseSale(saleId, reason: 'إلغاء بناء على طلب العميل');
      expect(revRes.isSuccess, isTrue);
      expect(await getProductStock(pId), Decimal.fromInt(20)); // عاد المخزون كما كان
      expect(await getCashboxBalance(), 10000); // ردت النقدية وعادت الخزينة لأصلها
    });
  });

  // =========================================================================
  // DOMAIN 2: المشتريات والموردين والتكلفة (Scenarios 11 - 18)
  // =========================================================================
  group('المجال 2: دورة المشتريات والموردين (8 سيناريوهات)', () {
    test('سيناريو 11: شراء نقدي 100% مع كفاية الخزينة - زيادة المخزون وصرف النقدية', () async {
      await seedCashbox(50000); // 500 EGP
      final sId = await addSupplier('مورد نقدي');
      final pId = await addProduct('دقيق', currentQuantity: Decimal.fromInt(10), purchasePrice: 1500);

      // شراء 20 كيس بسعر 15.00 EGP = 300.00 EGP (30000 قرش) نقداً
      final res = await purchaseRepo.createPurchase(
        CreatePurchaseParams(
          supplierId: sId,
          purchaseDate: DateTime.now(),
          items: [
            PurchaseItemParam(productId: pId, quantity: Decimal.fromInt(20), unitCost: const Money(1500)),
          ],
          paidAmountAtCreation: const Money(30000),
        ),
      );

      expect(res.isSuccess, isTrue);
      expect(await getCashboxBalance(), 20000); // 50000 - 30000 = 20000
      expect(await getProductStock(pId), Decimal.fromInt(30)); // 10 + 20 = 30
      expect(await getSupplierBalance(sId), 0); // سددت نقداً
    });

    test('سيناريو 12: شراء آجل 100% - زيادة المخزون وزيادة مديونية المورد دون لمس الخزينة', () async {
      await seedCashbox(50000);
      final sId = await addSupplier('مورد آجل');
      final pId = await addProduct('صلصة', currentQuantity: Decimal.fromInt(5), purchasePrice: 1200);

      final res = await purchaseRepo.createPurchase(
        CreatePurchaseParams(
          supplierId: sId,
          purchaseDate: DateTime.now(),
          items: [
            PurchaseItemParam(productId: pId, quantity: Decimal.fromInt(10), unitCost: const Money(1200)),
          ],
          paidAmountAtCreation: Money.zero,
        ),
      );

      expect(res.isSuccess, isTrue);
      expect(await getCashboxBalance(), 50000); // لم تتغير الخزينة
      expect(await getProductStock(pId), Decimal.fromInt(15));
      expect(await getSupplierBalance(sId), 12000); // مستحق للمورد 120.00 EGP
    });

    test('سيناريو 13: شراء جزئي (دفعة كاش ومتبقي آجل)', () async {
      await seedCashbox(30000);
      final sId = await addSupplier('مورد جزئي');
      final pId = await addProduct('عصير', currentQuantity: Decimal.fromInt(10), purchasePrice: 800);

      // شراء 20 علبة = 16000 قرش. دفع 6000 قرش كاش ومتبقي 10000 آجل
      final res = await purchaseRepo.createPurchase(
        CreatePurchaseParams(
          supplierId: sId,
          purchaseDate: DateTime.now(),
          items: [
            PurchaseItemParam(productId: pId, quantity: Decimal.fromInt(20), unitCost: const Money(800)),
          ],
          paidAmountAtCreation: const Money(6000),
        ),
      );

      expect(res.isSuccess, isTrue);
      expect(await getCashboxBalance(), 24000); // 30000 - 6000 = 24000
      expect(await getProductStock(pId), Decimal.fromInt(30));
      expect(await getSupplierBalance(sId), 10000); // متبقي 100.00 EGP
    });

    test('سيناريو 14: تحديث سعر الشراء الأخير للمنتج تلقائياً عند الشراء بتكلفة جديدة', () async {
      final sId = await addSupplier('مورد أسعار');
      final pId = await addProduct('مسحوق غسيل', currentQuantity: Decimal.fromInt(10), purchasePrice: 5000);

      // شراء بسعر جديد 55.00 EGP (5500 قرش)
      final res = await purchaseRepo.createPurchase(
        CreatePurchaseParams(
          supplierId: sId,
          purchaseDate: DateTime.now(),
          items: [
            PurchaseItemParam(productId: pId, quantity: Decimal.fromInt(5), unitCost: const Money(5500)),
          ],
          paidAmountAtCreation: Money.zero,
        ),
      );

      expect(res.isSuccess, isTrue);
      final p = await (db.select(db.products)..where((t) => t.id.equals(pId))).getSingle();
      expect(p.currentPurchasePrice, 5500); // تم تحديث سعر الشراء إلى 55.00 EGP
    });

    test('سيناريو 15: شراء كميات كسرية دقيقة', () async {
      final sId = await addSupplier('مورد جملة حبوب');
      final pId = await addProduct('فول صويا', currentQuantity: Decimal.parse('1.250'), purchasePrice: 40000, unit: 'طن');

      // شراء 3.750 طن بسعر 400.00 EGP (40000 قرش) للطن = 1500.00 EGP (150000 قرش)
      final res = await purchaseRepo.createPurchase(
        CreatePurchaseParams(
          supplierId: sId,
          purchaseDate: DateTime.now(),
          items: [
            PurchaseItemParam(productId: pId, quantity: Decimal.parse('3.750'), unitCost: const Money(40000)),
          ],
          paidAmountAtCreation: Money.zero,
        ),
      );

      expect(res.isSuccess, isTrue);
      expect(res.dataOrNull!.totalAmount, const Money(150000));
      expect(await getProductStock(pId), Decimal.parse('5.000'));
    });

    test('سيناريو 16: شراء أصناف متعددة في نفس الفاتورة وتوزيع البنود', () async {
      final sId = await addSupplier('مورد متعدد');
      final p1 = await addProduct('بسكويت 1', currentQuantity: Decimal.fromInt(5), purchasePrice: 500);
      final p2 = await addProduct('بسكويت 2', currentQuantity: Decimal.fromInt(10), purchasePrice: 750);

      final res = await purchaseRepo.createPurchase(
        CreatePurchaseParams(
          supplierId: sId,
          purchaseDate: DateTime.now(),
          items: [
            PurchaseItemParam(productId: p1, quantity: Decimal.fromInt(10), unitCost: const Money(500)),
            PurchaseItemParam(productId: p2, quantity: Decimal.fromInt(20), unitCost: const Money(750)),
          ],
          paidAmountAtCreation: Money.zero,
        ),
      );

      expect(res.isSuccess, isTrue);
      // (10 * 500 = 5000) + (20 * 750 = 15000) = 20000 قرش (200.00 EGP)
      expect(res.dataOrNull!.totalAmount, const Money(20000));
      expect(await getProductStock(p1), Decimal.fromInt(15));
      expect(await getProductStock(p2), Decimal.fromInt(30));
    });

    test('سيناريو 17: إلغاء وعكس فاتورة شراء (Purchase Reversal) وخصم البضاعة والمستحقات', () async {
      await seedCashbox(100000);
      final sId = await addSupplier('مورد عكس');
      final pId = await addProduct('صابون', currentQuantity: Decimal.fromInt(20), purchasePrice: 2000);

      // شراء 10 قطع بـ 20000 قرش، دفع 10000 قرش ومتبقي 10000 قرش
      final createRes = await purchaseRepo.createPurchase(
        CreatePurchaseParams(
          supplierId: sId,
          purchaseDate: DateTime.now(),
          items: [
            PurchaseItemParam(productId: pId, quantity: Decimal.fromInt(10), unitCost: const Money(2000)),
          ],
          paidAmountAtCreation: const Money(10000),
        ),
      );
      final purchaseId = createRes.dataOrNull!.id;
      expect(await getProductStock(pId), Decimal.fromInt(30));
      expect(await getCashboxBalance(), 90000);
      expect(await getSupplierBalance(sId), 10000);

      // عكس الفاتورة
      final revRes = await purchaseRepo.reversePurchase(purchaseId: purchaseId);
      expect(revRes.isSuccess, isTrue);
      expect(await getProductStock(pId), Decimal.fromInt(20)); // عادت 20
      expect(await getCashboxBalance(), 100000); // عادت النقدية
      expect(await getSupplierBalance(sId), 0); // عاد رصيد المورد صفراً
    });

    test('سيناريو 18: منع عكس فاتورة شراء إذا بيعت البضاعة بالفعل (منع المخزون السالب عند العكس)', () async {
      final sId = await addSupplier('مورد منع عكس');
      final cId = await addCustomer('زبون مستهلك');
      final pId = await addProduct('حلاوة طحينية', currentQuantity: Decimal.zero, purchasePrice: 3000, salePrice: 4000);

      // 1. شراء 5 قطع
      final pRes = await purchaseRepo.createPurchase(
        CreatePurchaseParams(
          supplierId: sId,
          purchaseDate: DateTime.now(),
          items: [
            PurchaseItemParam(productId: pId, quantity: Decimal.fromInt(5), unitCost: const Money(3000)),
          ],
          paidAmountAtCreation: Money.zero,
        ),
      );
      final pIdBuy = pRes.dataOrNull!.id;

      // 2. بيع 4 قطع للزبون (المتبقي في المخزن 1 فقط)
      await saleRepo.createSale(
        CreateSaleParams(
          customerId: cId,
          saleDate: DateTime.now(),
          items: [
            SaleItemParam(productId: pId, quantity: Decimal.fromInt(4), unitPrice: const Money(4000)),
          ],
          paidAmountAtCreation: Money.zero,
        ),
      );

      // 3. محاولة عكس فاتورة الشراء الأصلية (تتطلب خصم 5 قطع ولكن المتاح 1 فقط!)
      final revRes = await purchaseRepo.reversePurchase(purchaseId: pIdBuy);
      expect(revRes.isFailure, isTrue);
      expect(revRes.failureOrNull, isA<InsufficientStockFailure>());
      expect(await getProductStock(pId), Decimal.fromInt(1)); // بقي كما هو
    });
  });

  // =========================================================================
  // DOMAIN 3: مرتجعات المبيعات وحماية الخزينة (Scenarios 19 - 25)
  // =========================================================================
  group('المجال 3: دورة مرتجعات المبيعات (7 سيناريوهات)', () {
    test('سيناريو 19: مرتجع مبيعات نقدي فوري - رد البضاعة للمخزن وصرف النقدية من الخزينة', () async {
      await seedCashbox(20000);
      final cId = await addCustomer('عميل مرتجع كاش');
      final pId = await addProduct('منتج مرتجع 1', currentQuantity: Decimal.fromInt(10), salePrice: 2000);

      // مرتجع 2 قطعة نقداً بسعر 20.00 EGP = 40.00 EGP (4000 قرش)
      final res = await returnRepo.createCustomerReturn(
        CreateCustomerReturnParams(
          customerId: cId,
          returnDate: DateTime.now(),
          items: [
            ReturnItemParam(productId: pId, quantity: Decimal.fromInt(2), unitPrice: const Money(2000)),
          ],
          refundCashAmount: const Money(4000), // كاش فوري
        ),
      );

      expect(res.isSuccess, isTrue);
      expect(await getProductStock(pId), Decimal.fromInt(12)); // زاد المخزون
      expect(await getCashboxBalance(), 16000); // 20000 - 4000 = 16000
      expect(await getCustomerBalance(cId), 0);
    });

    test('سيناريو 20: حماية الخزينة - رفض المرتجع النقدي إذا كان رصيد الخزينة لا يكفي', () async {
      await seedCashbox(1500); // 15.00 EGP فقط
      final cId = await addCustomer('عميل مرتجع خزينة ضعيفة');
      final pId = await addProduct('منتج غالي', currentQuantity: Decimal.fromInt(5), salePrice: 5000);

      // محاولة استرداد 50.00 EGP (5000 قرش) كاش بينما الخزينة بها 1500 فقط
      final res = await returnRepo.createCustomerReturn(
        CreateCustomerReturnParams(
          customerId: cId,
          returnDate: DateTime.now(),
          items: [
            ReturnItemParam(productId: pId, quantity: Decimal.fromInt(1), unitPrice: const Money(5000)),
          ],
          refundCashAmount: const Money(5000),
        ),
      );

      expect(res.isFailure, isTrue);
      expect(res.failureOrNull, isA<ValidationFailure>());
      expect(await getProductStock(pId), Decimal.fromInt(5)); // لم يتغير المخزون
      expect(await getCashboxBalance(), 1500); // لم تخصم الخزينة
    });

    test('سيناريو 21: مرتجع مبيعات آجل - تخفيض دين العميل دون لمس الخزينة', () async {
      await seedCashbox(10000);
      final cId = await addCustomer('عميل مدين', initialBalance: 15000); // عليه 150.00 EGP
      final pId = await addProduct('منتج آجل', currentQuantity: Decimal.fromInt(10), salePrice: 3000);

      // إرجاع قطعتين بقيمة 60.00 EGP (6000 قرش) تخصم من حسابه
      final res = await returnRepo.createCustomerReturn(
        CreateCustomerReturnParams(
          customerId: cId,
          returnDate: DateTime.now(),
          items: [
            ReturnItemParam(productId: pId, quantity: Decimal.fromInt(2), unitPrice: const Money(3000)),
          ],
          refundCashAmount: Money.zero, // بدون صرف نقدية
        ),
      );

      expect(res.isSuccess, isTrue);
      expect(await getProductStock(pId), Decimal.fromInt(12));
      expect(await getCashboxBalance(), 10000); // لم تمس الخزينة
      expect(await getCustomerBalance(cId), 9000); // انخفض الدين من 15000 إلى 9000
    });

    test('سيناريو 22: مرتجع جزئي من فاتورة بيع سابقة', () async {
      final cId = await addCustomer('عميل فاتورة بيع');
      final pId = await addProduct('علبة شوكولاتة', currentQuantity: Decimal.fromInt(20), salePrice: 2500);

      // 1. بيع 5 علب على الحساب
      final saleRes = await saleRepo.createSale(
        CreateSaleParams(
          customerId: cId,
          saleDate: DateTime.now(),
          items: [
            SaleItemParam(productId: pId, quantity: Decimal.fromInt(5), unitPrice: const Money(2500)),
          ],
          paidAmountAtCreation: Money.zero,
        ),
      );
      final saleId = saleRes.dataOrNull!.id;
      expect(await getCustomerBalance(cId), 12500);

      // 2. إرجاع علبتين فقط مرتبطتين بالفاتورة
      final retRes = await returnRepo.createCustomerReturn(
        CreateCustomerReturnParams(
          originalSaleId: saleId,
          customerId: cId,
          returnDate: DateTime.now(),
          items: [
            ReturnItemParam(productId: pId, quantity: Decimal.fromInt(2), unitPrice: const Money(2500)),
          ],
          refundCashAmount: Money.zero,
        ),
      );

      expect(retRes.isSuccess, isTrue);
      expect(await getCustomerBalance(cId), 7500); // 12500 - 5000 = 7500
      expect(await getProductStock(pId), Decimal.fromInt(17)); // 15 + 2 = 17
    });

    test('سيناريو 23: مرتجع مبيعات بكميات كسرية (وزن بالجرامات)', () async {
      final cId = await addCustomer('عميل وزن');
      final pId = await addProduct('لحم مفروم', currentQuantity: Decimal.parse('3.500'), salePrice: 38000, unit: 'كجم');

      // إرجاع 0.750 كجم بسعر 380.00 EGP = 285.00 EGP (28500 قرش) آجل
      final res = await returnRepo.createCustomerReturn(
        CreateCustomerReturnParams(
          customerId: cId,
          returnDate: DateTime.now(),
          items: [
            ReturnItemParam(productId: pId, quantity: Decimal.parse('0.750'), unitPrice: const Money(38000)),
          ],
          refundCashAmount: Money.zero,
        ),
      );

      expect(res.isSuccess, isTrue);
      expect(await getProductStock(pId), Decimal.parse('4.250')); // 3.500 + 0.750 = 4.250
      expect(await getCustomerBalance(cId), -28500); // رصيد دائن للعميل
    });

    test('سيناريو 24: مرتجع مبيعات مختلط (جزء كاش وجزء خصم من الحساب)', () async {
      await seedCashbox(10000);
      final cId = await addCustomer('عميل مكس', initialBalance: 10000); // عليه 100.00 EGP
      final pId = await addProduct('صنف مكس', currentQuantity: Decimal.fromInt(10), salePrice: 10000);

      // إرجاع صنف بقيمة 100.00 EGP (10000 قرش)، دفع له 30.00 كاش (3000 قرش)، وخصم 70.00 (7000 قرش) من دينه
      final res = await returnRepo.createCustomerReturn(
        CreateCustomerReturnParams(
          customerId: cId,
          returnDate: DateTime.now(),
          items: [
            ReturnItemParam(productId: pId, quantity: Decimal.fromInt(1), unitPrice: const Money(10000)),
          ],
          refundCashAmount: const Money(3000), // كاش 30
        ),
      );

      expect(res.isSuccess, isTrue);
      expect(await getCashboxBalance(), 7000); // 10000 - 3000 = 7000
      expect(await getCustomerBalance(cId), 3000); // دينه كان 10000 - 7000 = 3000
    });

    test('سيناريو 25: مرتجع كامل لفاتورة بيع بالكامل وتصفير رصيدها', () async {
      final cId = await addCustomer('عميل إرجاع تام');
      final pId = await addProduct('صنف تام', currentQuantity: Decimal.fromInt(10), salePrice: 5000);

      final saleRes = await saleRepo.createSale(
        CreateSaleParams(
          customerId: cId,
          saleDate: DateTime.now(),
          items: [
            SaleItemParam(productId: pId, quantity: Decimal.fromInt(3), unitPrice: const Money(5000)),
          ],
          paidAmountAtCreation: Money.zero,
        ),
      );
      final saleId = saleRes.dataOrNull!.id;
      expect(await getCustomerBalance(cId), 15000);

      // إرجاع الـ 3 قطع بالكامل
      final retRes = await returnRepo.createCustomerReturn(
        CreateCustomerReturnParams(
          originalSaleId: saleId,
          customerId: cId,
          returnDate: DateTime.now(),
          items: [
            ReturnItemParam(productId: pId, quantity: Decimal.fromInt(3), unitPrice: const Money(5000)),
          ],
          refundCashAmount: Money.zero,
        ),
      );

      expect(retRes.isSuccess, isTrue);
      expect(await getCustomerBalance(cId), 0); // صفر
      expect(await getProductStock(pId), Decimal.fromInt(10)); // عاد المخزون مكتملاً
    });
  });

  // =========================================================================
  // DOMAIN 4: مرتجعات المشتريات والموردين (Scenarios 26 - 31)
  // =========================================================================
  group('المجال 4: دورة مرتجعات المشتريات (6 سيناريوهات)', () {
    test('سيناريو 26: مرتجع شراء نقدي - خروج بضاعة من المخزن ودخول نقدية للخزينة', () async {
      await seedCashbox(5000);
      final sId = await addSupplier('مورد مرتجع نقدي');
      final pId = await addProduct('بضاعة تالفة', currentQuantity: Decimal.fromInt(10), purchasePrice: 2000);

      // إرجاع 3 قطع بسعر 20.00 EGP = 60.00 EGP (6000 قرش) نقداً
      final res = await returnRepo.createSupplierReturn(
        CreateSupplierReturnParams(
          supplierId: sId,
          returnDate: DateTime.now(),
          items: [
            ReturnItemParam(productId: pId, quantity: Decimal.fromInt(3), unitPrice: const Money(2000)),
          ],
          refundCashAmount: const Money(6000), // كاش وارد
        ),
      );

      expect(res.isSuccess, isTrue);
      expect(await getProductStock(pId), Decimal.fromInt(7)); // انخفض المخزون
      expect(await getCashboxBalance(), 11000); // 5000 + 6000 = 11000
      expect(await getSupplierBalance(sId), 0);
    });

    test('سيناريو 27: منع مرتجع شراء لبضاعة غير متوفرة في المخزن (منع المخزون السالب)', () async {
      final sId = await addSupplier('مورد منع مرتجع');
      final pId = await addProduct('صنف منتهي', currentQuantity: Decimal.fromInt(2), purchasePrice: 1000);

      // محاولة إرجاع 5 قطع بينما المتاح 2 فقط
      final res = await returnRepo.createSupplierReturn(
        CreateSupplierReturnParams(
          supplierId: sId,
          returnDate: DateTime.now(),
          items: [
            ReturnItemParam(productId: pId, quantity: Decimal.fromInt(5), unitPrice: const Money(1000)),
          ],
          refundCashAmount: Money.zero,
        ),
      );

      expect(res.isFailure, isTrue);
      expect(res.failureOrNull, isA<InsufficientStockFailure>());
      expect(await getProductStock(pId), Decimal.fromInt(2)); // لم يتغير
    });

    test('سيناريو 28: مرتجع شراء آجل - خروج بضاعة وتخفيض مديونية المورد دون لمس الخزينة', () async {
      await seedCashbox(20000);
      final sId = await addSupplier('مورد دائن', initialBalance: 30000); // مستحق له 300.00 EGP
      final pId = await addProduct('صنف مرتجع آجل', currentQuantity: Decimal.fromInt(20), purchasePrice: 5000);

      // إرجاع 4 قطع بقيمة 200.00 EGP (20000 قرش) تخصم من مستحقاته
      final res = await returnRepo.createSupplierReturn(
        CreateSupplierReturnParams(
          supplierId: sId,
          returnDate: DateTime.now(),
          items: [
            ReturnItemParam(productId: pId, quantity: Decimal.fromInt(4), unitPrice: const Money(5000)),
          ],
          refundCashAmount: Money.zero,
        ),
      );

      expect(res.isSuccess, isTrue);
      expect(await getProductStock(pId), Decimal.fromInt(16));
      expect(await getCashboxBalance(), 20000); // لم تمس الخزينة
      expect(await getSupplierBalance(sId), 10000); // انخفضت مديونيته من 30000 إلى 10000
    });

    test('سيناريو 29: مرتجع شراء جزئي من فاتورة شراء سابقة', () async {
      final sId = await addSupplier('مورد فاتورة شراء');
      final pId = await addProduct('كرتونة شيبسي', currentQuantity: Decimal.fromInt(5), purchasePrice: 4000);

      // 1. شراء 10 كراتين
      final pRes = await purchaseRepo.createPurchase(
        CreatePurchaseParams(
          supplierId: sId,
          purchaseDate: DateTime.now(),
          items: [
            PurchaseItemParam(productId: pId, quantity: Decimal.fromInt(10), unitCost: const Money(4000)),
          ],
          paidAmountAtCreation: Money.zero,
        ),
      );
      final purchaseId = pRes.dataOrNull!.id;

      // 2. إرجاع 3 كراتين فقط تالفة
      final retRes = await returnRepo.createSupplierReturn(
        CreateSupplierReturnParams(
          originalPurchaseId: purchaseId,
          supplierId: sId,
          returnDate: DateTime.now(),
          items: [
            ReturnItemParam(productId: pId, quantity: Decimal.fromInt(3), unitPrice: const Money(4000)),
          ],
          refundCashAmount: Money.zero,
        ),
      );

      expect(retRes.isSuccess, isTrue);
      expect(await getProductStock(pId), Decimal.fromInt(12)); // 15 - 3 = 12
      expect(await getSupplierBalance(sId), 28000); // 40000 - 12000 = 28000
    });

    test('سيناريو 30: مرتجع شراء لكميات كسرية (أوزان دقيقة)', () async {
      final sId = await addSupplier('مورد لحوم جملة');
      final pId = await addProduct('لحوم مبردة', currentQuantity: Decimal.parse('15.500'), purchasePrice: 25000, unit: 'كجم');

      // إرجاع 3.250 كجم بسعر 250.00 EGP = 812.50 EGP (81250 قرش)
      final res = await returnRepo.createSupplierReturn(
        CreateSupplierReturnParams(
          supplierId: sId,
          returnDate: DateTime.now(),
          items: [
            ReturnItemParam(productId: pId, quantity: Decimal.parse('3.250'), unitPrice: const Money(25000)),
          ],
          refundCashAmount: Money.zero,
        ),
      );

      expect(res.isSuccess, isTrue);
      expect(await getProductStock(pId), Decimal.parse('12.250'));
      expect(await getSupplierBalance(sId), -81250); // أصبح المورد مدين لنا بالمبلغ
    });

    test('سيناريو 31: مرتجع شراء كامل لفاتورة شراء بالكامل', () async {
      final sId = await addSupplier('مورد إرجاع كلي');
      final pId = await addProduct('بضاعة كاملة', currentQuantity: Decimal.fromInt(10), purchasePrice: 3000);

      final pRes = await purchaseRepo.createPurchase(
        CreatePurchaseParams(
          supplierId: sId,
          purchaseDate: DateTime.now(),
          items: [
            PurchaseItemParam(productId: pId, quantity: Decimal.fromInt(5), unitCost: const Money(3000)),
          ],
          paidAmountAtCreation: Money.zero,
        ),
      );
      final pIdBuy = pRes.dataOrNull!.id;

      final retRes = await returnRepo.createSupplierReturn(
        CreateSupplierReturnParams(
          originalPurchaseId: pIdBuy,
          supplierId: sId,
          returnDate: DateTime.now(),
          items: [
            ReturnItemParam(productId: pId, quantity: Decimal.fromInt(5), unitPrice: const Money(3000)),
          ],
          refundCashAmount: Money.zero,
        ),
      );

      expect(retRes.isSuccess, isTrue);
      expect(await getProductStock(pId), Decimal.fromInt(10));
      expect(await getSupplierBalance(sId), 0);
    });
  });

  // =========================================================================
  // DOMAIN 5: التحصيلات وسدادات الحسابات والتصفية (Scenarios 32 - 37)
  // =========================================================================
  group('المجال 5: تحصيلات وسدادات العملاء والموردين (6 سيناريوهات)', () {
    test('سيناريو 32: تحصيل نقدي جزئي من عميل مدين - زيادة الخزينة وتخفيض الدين', () async {
      await seedCashbox(10000);
      final cId = await addCustomer('عميل سداد جزئي', initialBalance: 25000); // عليه 250.00 EGP

      // سداد 100.00 EGP (10000 قرش)
      final res = await customerPaymentRepo.recordPayment(
        customerId: cId,
        amount: const Money(10000),
        paymentDate: DateTime.now(),
        note: 'دفعة تحت الحساب',
      );

      expect(res.isSuccess, isTrue);
      expect(await getCashboxBalance(), 20000); // 10000 + 10000 = 20000
      expect(await getCustomerBalance(cId), 15000); // 25000 - 10000 = 15000
    });

    test('سيناريو 33: تحصيل نقدي يغطي كامل دين العميل وتصفيره تماماً (0.00 ج.م)', () async {
      await seedCashbox(5000);
      final cId = await addCustomer('عميل تصفية', initialBalance: 17550); // 175.50 EGP

      final res = await customerPaymentRepo.recordPayment(
        customerId: cId,
        amount: const Money(17550),
        paymentDate: DateTime.now(),
        note: 'تصفية الحساب بالكامل',
      );

      expect(res.isSuccess, isTrue);
      expect(await getCashboxBalance(), 22550);
      expect(await getCustomerBalance(cId), 0); // صفر تام
    });

    test('سيناريو 34: تحصيل نقدي أكبر من دين العميل وتحويله لدائن (له رصيد)', () async {
      await seedCashbox(5000);
      final cId = await addCustomer('عميل دفع زيادة', initialBalance: 3000); // عليه 30.00 EGP

      // دفع 50.00 EGP (5000 قرش)
      final res = await customerPaymentRepo.recordPayment(
        customerId: cId,
        amount: const Money(5000),
        paymentDate: DateTime.now(),
      );

      expect(res.isSuccess, isTrue);
      expect(await getCashboxBalance(), 10000);
      expect(await getCustomerBalance(cId), -2000); // دائن بـ 20.00 EGP
    });

    test('سيناريو 35: سداد نقدي جزئي لمورد من الخزينة', () async {
      await seedCashbox(50000);
      final sId = await addSupplier('مورد سداد جزئي', initialBalance: 40000); // له 400.00 EGP

      final res = await supplierPaymentRepo.recordPayment(
        supplierId: sId,
        amount: const Money(15000),
        paymentDate: DateTime.now(),
        note: 'سداد دفعة من الفاتورة',
      );

      expect(res.isSuccess, isTrue);
      expect(await getCashboxBalance(), 35000); // 50000 - 15000 = 35000
      expect(await getSupplierBalance(sId), 25000); // 40000 - 15000 = 25000
    });

    test('سيناريو 36: سداد كامل يصفر حساب المورد بالكامل', () async {
      await seedCashbox(100000);
      final sId = await addSupplier('مورد تصفية حساب', initialBalance: 65400); // 654.00 EGP

      final res = await supplierPaymentRepo.recordPayment(
        supplierId: sId,
        amount: const Money(65400),
        paymentDate: DateTime.now(),
      );

      expect(res.isSuccess, isTrue);
      expect(await getCashboxBalance(), 34600); // 100000 - 65400 = 34600
      expect(await getSupplierBalance(sId), 0); // صفر تام
    });

    test('سيناريو 37: منع تسجيل سداد لعميل أو مورد غير نشط (موقوف)', () async {
      final cId = await db.into(db.customers).insert(
            CustomersCompanion.insert(
              name: 'عميل محظور',
              isActive: const Value(false),
            ),
          );

      final res = await customerPaymentRepo.recordPayment(
        customerId: cId,
        amount: const Money(5000),
        paymentDate: DateTime.now(),
      );

      expect(res.isFailure, isTrue);
      expect(res.failureOrNull, isA<ConflictFailure>());
    });
  });

  // =========================================================================
  // DOMAIN 6: حركة الصندوق والمصروفات والتدقيق التراكمي (Scenarios 38 - 42)
  // =========================================================================
  group('المجال 6: حركة الصندوق والمصروفات (5 سيناريوهات)', () {
    test('سيناريو 38: تسجيل مصروف تشغيلي وخصمه فورياً من الخزينة وتوثيقه', () async {
      await seedCashbox(20000);

      final res = await expenseRepo.recordExpense(
        category: 'كهرباء وإنارة',
        amount: const Money(3550), // 35.50 EGP
        expenseDate: DateTime.now(),
        note: 'فاتورة شهر سبتمبر',
      );

      expect(res.isSuccess, isTrue);
      expect(await getCashboxBalance(), 16450); // 20000 - 3550 = 16450
    });

    test('سيناريو 39: منع تسجيل مصروف بدون تحديد بند أو بمبلغ صفري', () async {
      final resEmpty = await expenseRepo.recordExpense(
        category: '   ',
        amount: const Money(1000),
        expenseDate: DateTime.now(),
      );
      expect(resEmpty.isFailure, isTrue);

      final resZero = await expenseRepo.recordExpense(
        category: 'صيانة',
        amount: Money.zero,
        expenseDate: DateTime.now(),
      );
      expect(resZero.isFailure, isTrue);
    });

    test('سيناريو 40: إيداع نقدي مباشر في الخزينة وتحديث الرصيد التراكمي', () async {
      await seedCashbox(10000);

      // إيداع 25000 قرش
      await db.into(db.cashboxTransactions).insert(
            CashboxTransactionsCompanion.insert(
              transactionType: 'deposit_in',
              amount: 25000,
              direction: 'in',
              balanceAfter: 35000,
              note: const Value('إيداع سيولة إضافية'),
            ),
          );

      expect(await getCashboxBalance(), 35000);
    });

    test('سيناريو 41: سحب نقدي مسحوبات شخصية وتحديث balanceAfter', () async {
      await seedCashbox(50000);

      await db.into(db.cashboxTransactions).insert(
            CashboxTransactionsCompanion.insert(
              transactionType: 'withdrawal_out',
              amount: 15000,
              direction: 'out',
              balanceAfter: 35000,
              note: const Value('مسحوبات الشركاء'),
            ),
          );

      expect(await getCashboxBalance(), 35000);
    });

    test('سيناريو 42: تتابع سريع لعشرات العمليات والتحقق من سلامة balanceAfter التراكمي', () async {
      var runningBalance = 100000;
      await seedCashbox(runningBalance);

      // تشغيل سلسلة من 10 حركات سريعة متعاقبة
      final amounts = [5000, -2000, 15000, -8000, -12000, 3000, -1000, 4500, -6500, 10000];
      for (final a in amounts) {
        final direction = a >= 0 ? 'in' : 'out';
        final amt = a.abs();
        runningBalance += a;

        await db.into(db.cashboxTransactions).insert(
              CashboxTransactionsCompanion.insert(
                transactionType: direction == 'in' ? 'sale_cash_in' : 'expense_out',
                amount: amt,
                direction: direction,
                balanceAfter: runningBalance,
              ),
            );
      }

      // المجموع الرياضي الدقيق: 100000 + 5000 - 2000 + 15000 - 8000 - 12000 + 3000 - 1000 + 4500 - 6500 + 10000 = 108000
      expect(await getCashboxBalance(), 108000);
    });
  });

  // =========================================================================
  // DOMAIN 7: الجرد والتسويات المخزنية (Scenarios 43 - 46)
  // =========================================================================
  group('المجال 7: الجرد والتسويات المخزنية (4 سيناريوهات)', () {
    test('سيناريو 43: تسوية جردية بالزيادة مع توثيق السبب الإلزامي', () async {
      final pId = await addProduct('علبة سمن', currentQuantity: Decimal.fromInt(10));

      final res = await inventoryRepo.recordAdjustment(
        productId: pId,
        quantityDelta: Decimal.fromInt(3), // زيادة 3 علب
        reason: 'عثور على بضاعة زائدة أثناء الجرد السنوي',
      );

      expect(res.isSuccess, isTrue);
      expect(await getProductStock(pId), Decimal.fromInt(13));
    });

    test('سيناريو 44: تسوية جردية بالعجز وخصم التوالف', () async {
      final pId = await addProduct('كرتونة بيض', currentQuantity: Decimal.fromInt(15));

      final res = await inventoryRepo.recordAdjustment(
        productId: pId,
        quantityDelta: Decimal.fromInt(-2), // عجز 2
        reason: 'كسر وتلف أثناء النقل',
      );

      expect(res.isSuccess, isTrue);
      expect(await getProductStock(pId), Decimal.fromInt(13));
    });

    test('سيناريو 45: منع تسوية عجز بأكثر من الكمية المتاحة حالياً', () async {
      final pId = await addProduct('زيت زيتون', currentQuantity: Decimal.fromInt(4));

      final res = await inventoryRepo.recordAdjustment(
        productId: pId,
        quantityDelta: Decimal.fromInt(-5), // طلب عجز 5 بينما المتاح 4
        reason: 'تلف كامل',
      );

      expect(res.isFailure, isTrue);
      expect(res.failureOrNull, isA<InsufficientStockFailure>());
      expect(await getProductStock(pId), Decimal.fromInt(4)); // لم يتغير
    });

    test('سيناريو 46: تسوية مخزنية لكميات كسرية بالجرامات', () async {
      final pId = await addProduct('توابل زعفران', currentQuantity: Decimal.parse('2.500'), unit: 'كجم');

      final res = await inventoryRepo.recordAdjustment(
        productId: pId,
        quantityDelta: Decimal.parse('-0.150'), // عجز 150 جرام
        reason: 'هدر وزن وتطاير طبيعي',
      );

      expect(res.isSuccess, isTrue);
      expect(await getProductStock(pId), Decimal.parse('2.350'));
    });
  });

  // =========================================================================
  // DOMAIN 8: الأرصدة الافتتاحية وبدء التشغيل (Scenarios 47 - 49)
  // =========================================================================
  group('المجال 8: الأرصدة الافتتاحية وبدء التشغيل (3 سيناريوهات)', () {
    test('سيناريو 47: تسجيل أرصدة افتتاحية شاملة وتوزيعها بدقة', () async {
      final pId = await addProduct('منتج افتتاحي', currentQuantity: Decimal.zero);
      final cId = await addCustomer('عميل افتتاحي');
      final sId = await addSupplier('مورد افتتاحي');

      final input = OpeningBalanceInput(
        cashboxBalance: const Money(100000), // 1000.00 EGP
        products: [
          ProductOpeningBalance(
            productId: pId,
            productName: 'منتج افتتاحي',
            unit: 'قطعة',
            initialQuantity: Decimal.fromInt(50),
          ),
        ],
        customers: [
          StakeholderOpeningBalance(
            stakeholderId: cId,
            name: 'عميل افتتاحي',
            balance: const Money(15000), // عليه 150.00
          ),
        ],
        suppliers: [
          StakeholderOpeningBalance(
            stakeholderId: sId,
            name: 'مورد افتتاحي',
            balance: const Money(30000), // له 300.00
          ),
        ],
      );

      final res = await openingBalanceRepo.saveOpeningBalances(input);
      expect(res.isSuccess, isTrue);

      expect(await getCashboxBalance(), 100000);
      expect(await getProductStock(pId), Decimal.fromInt(50));
      expect(await getCustomerBalance(cId), 15000);
      expect(await getSupplierBalance(sId), 30000);
    });

    test('سيناريو 48: منع تكرار حفظ الأرصدة الافتتاحية بعد حفظها أول مرة', () async {
      const input = OpeningBalanceInput(
        cashboxBalance: Money.fromPiastres(50000),
        products: [],
        customers: [],
        suppliers: [],
      );

      final first = await openingBalanceRepo.saveOpeningBalances(input);
      expect(first.isSuccess, isTrue);

      // محاولة حفظ مرة ثانية
      final second = await openingBalanceRepo.saveOpeningBalances(input);
      expect(second.isFailure, isTrue);
      expect(second.failureOrNull, isA<ConflictFailure>());
    });

    test('سيناريو 49: الرصيد الافتتاحي يظهر كأول حركة في كشف الحساب التراكمي', () async {
      final cId = await addCustomer('عميل كشف حساب');
      final input = OpeningBalanceInput(
        cashboxBalance: Money.zero,
        products: const [],
        customers: [
          StakeholderOpeningBalance(
            stakeholderId: cId,
            name: 'عميل كشف حساب',
            balance: const Money(5000),
          ),
        ],
        suppliers: const [],
      );
      await openingBalanceRepo.saveOpeningBalances(input);

      final entries = await (db.select(db.customerLedgerEntries)..where((t) => t.customerId.equals(cId))).get();
      expect(entries.length, 1);
      expect(entries.first.entryType, 'opening_balance');
      expect(entries.first.amount, 5000);
      expect(entries.first.balanceAfter, 5000);
    });
  });

  // =========================================================================
  // DOMAIN 9: التكامل الشامل ودورات الحياة والضغط الشديد (Scenarios 50 - 55)
  // =========================================================================
  group('المجال 9: دورات الحياة الكاملة والضغط وسجل التدقيق (6 سيناريوهات)', () {
    test('سيناريو 50: دورة حياة المنتج الكاملة End-to-End ومطابقة الرصيد الرياضي التام', () async {
      // رصيد مبدئي = 10
      final pId = await addProduct('منتج الدورة الشاملة', currentQuantity: Decimal.fromInt(10), purchasePrice: 1000, salePrice: 1500);
      final cId = await addCustomer('عميل الدورة');
      final sId = await addSupplier('مورد الدورة');

      // 1. شراء 20 قطعة -> المخزون يصبح 30
      await purchaseRepo.createPurchase(
        CreatePurchaseParams(
          supplierId: sId,
          purchaseDate: DateTime.now(),
          items: [PurchaseItemParam(productId: pId, quantity: Decimal.fromInt(20), unitCost: const Money(1000))],
          paidAmountAtCreation: Money.zero,
        ),
      );
      expect(await getProductStock(pId), Decimal.fromInt(30));

      // 2. بيع 15 قطعة -> المخزون يصبح 15
      await saleRepo.createSale(
        CreateSaleParams(
          customerId: cId,
          saleDate: DateTime.now(),
          items: [SaleItemParam(productId: pId, quantity: Decimal.fromInt(15), unitPrice: const Money(1500))],
          paidAmountAtCreation: Money.zero,
        ),
      );
      expect(await getProductStock(pId), Decimal.fromInt(15));

      // 3. مرتجع عميل 3 قطع -> المخزون يصبح 18
      await returnRepo.createCustomerReturn(
        CreateCustomerReturnParams(
          customerId: cId,
          returnDate: DateTime.now(),
          items: [ReturnItemParam(productId: pId, quantity: Decimal.fromInt(3), unitPrice: const Money(1500))],
        ),
      );
      expect(await getProductStock(pId), Decimal.fromInt(18));

      // 4. مرتجع مورد قطعتين -> المخزون يصبح 16
      await returnRepo.createSupplierReturn(
        CreateSupplierReturnParams(
          supplierId: sId,
          returnDate: DateTime.now(),
          items: [ReturnItemParam(productId: pId, quantity: Decimal.fromInt(2), unitPrice: const Money(1000))],
        ),
      );
      expect(await getProductStock(pId), Decimal.fromInt(16));

      // 5. تسوية جردية عجز قطعة واحدة -> المخزون يصبح 15
      await inventoryRepo.recordAdjustment(
        productId: pId,
        quantityDelta: Decimal.fromInt(-1),
        reason: 'تلف قطعة أثناء النقل',
      );
      expect(await getProductStock(pId), Decimal.fromInt(15));

      // 6. بيع نهائي لـ 15 قطعة -> المخزون يصبح صفر تماماً
      await saleRepo.createSale(
        CreateSaleParams(
          customerId: cId,
          saleDate: DateTime.now(),
          items: [SaleItemParam(productId: pId, quantity: Decimal.fromInt(15), unitPrice: const Money(1500))],
          paidAmountAtCreation: Money.zero,
        ),
      );
      expect(await getProductStock(pId), Decimal.zero); // رصيد صفر تام دون انحراف كسر مليم واحد
    });

    test('سيناريو 51: دورة حياة العميل المالية الكاملة حتى تصفير الحساب إلى 0.00 ج.م', () async {
      await seedCashbox(100000);
      final cId = await addCustomer('عميل دورة حياة');
      final pId = await addProduct('بضاعة عميل', currentQuantity: Decimal.fromInt(50), salePrice: 2000);

      // 1. بيع آجل بـ 200.00 EGP (20000 قرش)
      await saleRepo.createSale(
        CreateSaleParams(
          customerId: cId,
          saleDate: DateTime.now(),
          items: [SaleItemParam(productId: pId, quantity: Decimal.fromInt(10), unitPrice: const Money(2000))],
          paidAmountAtCreation: Money.zero,
        ),
      );
      expect(await getCustomerBalance(cId), 20000);

      // 2. سداد جزئي 70.00 EGP (7000 قرش) -> متبقي 13000 قرش
      await customerPaymentRepo.recordPayment(customerId: cId, amount: const Money(7000), paymentDate: DateTime.now());
      expect(await getCustomerBalance(cId), 13000);

      // 3. مرتجع بيع بـ 30.00 EGP (3000 قرش) آجل -> متبقي 10000 قرش
      await returnRepo.createCustomerReturn(
        CreateCustomerReturnParams(
          customerId: cId,
          returnDate: DateTime.now(),
          items: [ReturnItemParam(productId: pId, quantity: Decimal.fromInt(1.5.toInt()), unitPrice: const Money(2000))],
        ),
      );
      // هنا 1 * 2000 = 2000 قرش
      final curBal = await getCustomerBalance(cId);

      // 4. سداد نهائي للمتبقي كاملاً
      await customerPaymentRepo.recordPayment(
        customerId: cId,
        amount: Money.fromPiastres(curBal),
        paymentDate: DateTime.now(),
      );

      // النتيجة: رصيد العميل 0.00 ج.م بالضبط
      expect(await getCustomerBalance(cId), 0);
    });

    test('سيناريو 52: دورة حياة المورد المالية الكاملة حتى التصفية التامة', () async {
      await seedCashbox(200000);
      final sId = await addSupplier('مورد دورة حياة');
      final pId = await addProduct('بضاعة مورد', currentQuantity: Decimal.zero, purchasePrice: 5000);

      // 1. شراء آجل بـ 500.00 EGP (50000 قرش)
      await purchaseRepo.createPurchase(
        CreatePurchaseParams(
          supplierId: sId,
          purchaseDate: DateTime.now(),
          items: [PurchaseItemParam(productId: pId, quantity: Decimal.fromInt(10), unitCost: const Money(5000))],
          paidAmountAtCreation: Money.zero,
        ),
      );
      expect(await getSupplierBalance(sId), 50000);

      // 2. سداد 200.00 EGP (20000 قرش) للمورد من الخزينة -> متبقي 30000 قرش
      await supplierPaymentRepo.recordPayment(supplierId: sId, amount: const Money(20000), paymentDate: DateTime.now());
      expect(await getSupplierBalance(sId), 30000);

      // 3. مرتجع شراء قطعتين = 10000 قرش آجل -> متبقي 20000 قرش
      await returnRepo.createSupplierReturn(
        CreateSupplierReturnParams(
          supplierId: sId,
          returnDate: DateTime.now(),
          items: [ReturnItemParam(productId: pId, quantity: Decimal.fromInt(2), unitPrice: const Money(5000))],
        ),
      );
      expect(await getSupplierBalance(sId), 20000);

      // 4. سداد نهائي للمتبقي 20000 قرش من الخزينة
      await supplierPaymentRepo.recordPayment(supplierId: sId, amount: const Money(20000), paymentDate: DateTime.now());

      // النتيجة: رصيد المورد صفر تام
      expect(await getSupplierBalance(sId), 0);
    });

    test('سيناريو 53: الأمان الذري التام (Atomic Transaction Rollback) عند فشل أي خطوة', () async {
      final cId = await addCustomer('عميل الذرية');
      final p1 = await addProduct('صنف متوفر', currentQuantity: Decimal.fromInt(10));
      final p2 = await addProduct('صنف قليل', currentQuantity: Decimal.fromInt(1));

      // محاولة إنشاء فاتورة تحتوي على صنف متوفر وصنف يتجاوز المخزون
      final res = await saleRepo.createSale(
        CreateSaleParams(
          customerId: cId,
          saleDate: DateTime.now(),
          items: [
            SaleItemParam(productId: p1, quantity: Decimal.fromInt(5), unitPrice: const Money(1000)),
            SaleItemParam(productId: p2, quantity: Decimal.fromInt(5), unitPrice: const Money(1000)), // سيفشل هنا
          ],
          paidAmountAtCreation: Money.zero,
        ),
      );

      expect(res.isFailure, isTrue);
      // التأكد من أن الصنف الأول لم يخصم منه شيء إطلاقاً بسبب الـ Rollback
      expect(await getProductStock(p1), Decimal.fromInt(10));
      expect(await getProductStock(p2), Decimal.fromInt(1));
      expect(await getCustomerBalance(cId), 0);

      final salesCount = await (db.select(db.sales)).get();
      expect(salesCount.isEmpty, isTrue); // لم يتم حفظ أي فاتورة
    });

    test('سيناريو 54: مطابقة تقرير الأرباح والخسائر رياضياً بالمليم', () async {
      final cId = await addCustomer('عميل أرباح');
      // منتج تكلفته 10.00 EGP (1000 قرش) وسعر بيعه 16.00 EGP (1600 قرش)
      final pId = await addProduct('سلعة ربح', currentQuantity: Decimal.fromInt(100), purchasePrice: 1000, salePrice: 1600);

      // بيع 10 قطع = إيراد 16000 قرش، تكلفة 10000 قرش، مجمل ربح = 6000 قرش (60.00 EGP)
      final now = DateTime.now();
      await saleRepo.createSale(
        CreateSaleParams(
          customerId: cId,
          saleDate: now,
          items: [SaleItemParam(productId: pId, quantity: Decimal.fromInt(10), unitPrice: const Money(1600))],
          paidAmountAtCreation: const Money(16000),
        ),
      );

      final reportRes = await reportRepo.getProfitReport(from: now.subtract(const Duration(days: 1)), to: now.add(const Duration(days: 1)));
      expect(reportRes.isSuccess, isTrue);
      final report = reportRes.dataOrNull!;
      expect(report.totalRevenue, const Money(16000));
      expect(report.totalCost, const Money(10000));
      expect(report.totalGrossProfit, const Money(6000)); // 60.00 EGP بالضبط
    });

    test('سيناريو 55: سلامة وموثوقية سجل الرقابة والتدقيق الشامل (Audit Trail Integrity)', () async {
      final cId = await addCustomer('عميل تدقيق');
      final pId = await addProduct('سلعة تدقيق', currentQuantity: Decimal.fromInt(20), salePrice: 2000);

      await saleRepo.createSale(
        CreateSaleParams(
          customerId: cId,
          saleDate: DateTime.now(),
          items: [SaleItemParam(productId: pId, quantity: Decimal.fromInt(2), unitPrice: const Money(2000))],
          paidAmountAtCreation: const Money(4000),
          createdBy: 'admin_auditor',
        ),
      );

      final auditLogs = await (db.select(db.auditLog)..where((t) => t.entityType.equals('sale'))).get();
      expect(auditLogs.isNotEmpty, isTrue);
      final log = auditLogs.last;
      expect(log.action, 'create');
      expect(log.userId, 'admin_auditor');
      expect(log.payloadAfter, contains('customer_id'));
    });
  });
}
