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

  // State inspection helpers
  Future<int> getCashbox() async {
    final res = await cashboxRepo.getCurrentBalance();
    return res.dataOrNull?.piastres ?? 0;
  }

  Future<Decimal> getStock(int pId) async {
    final p = await (db.select(db.products)..where((t) => t.id.equals(pId))).getSingle();
    return p.currentQuantity;
  }

  Future<int> getCustBalance(int cId) async {
    final c = await (db.select(db.customers)..where((t) => t.id.equals(cId))).getSingle();
    return c.currentBalance;
  }

  Future<int> getSuppBalance(int sId) async {
    final s = await (db.select(db.suppliers)..where((t) => t.id.equals(sId))).getSingle();
    return s.currentBalance;
  }

  group('محاكاة واقعية شاملة لنشاط تجاري حقيقي (10 مراحل متعاقبة)', () {
    test('تشغيل دورة متجر كاملة من الافتتاح والمشتريات والمبيعات والمرتجعات والمصروفات والتسويات حتى تقفيل الحسابات', () async {
      final now = DateTime.now();

      // =======================================================================
      // التأسيس المبدئي: إضافة سجلات المنتجات والعملاء والموردين
      // =======================================================================
      // 1. المنتجات
      final pSugar = await db.into(db.products).insert(
            ProductsCompanion.insert(
              name: 'سكر أبيض النيل 1 كجم',
              code: const Value('SUGAR-01'),
              unit: 'كيس',
              currentPurchasePrice: 2800, // 28.00 ج.م
              currentSalePrice: 3500, // 35.00 ج.م
              currentQuantity: Value(Decimal.zero),
            ),
          );

      final pCheese = await db.into(db.products).insert(
            ProductsCompanion.insert(
              name: 'جبن رومي قديم',
              code: const Value('CHEESE-01'),
              unit: 'كجم',
              currentPurchasePrice: 26000, // 260.00 ج.م
              currentSalePrice: 34000, // 340.00 ج.م
              currentQuantity: Value(Decimal.zero),
            ),
          );

      final pOil = await db.into(db.products).insert(
            ProductsCompanion.insert(
              name: 'زيت ذرة كريستال 800 مل',
              code: const Value('OIL-01'),
              unit: 'زجاجة',
              currentPurchasePrice: 5200, // 52.00 ج.م
              currentSalePrice: 6500, // 65.00 ج.م
              currentQuantity: Value(Decimal.zero),
            ),
          );

      final pTea = await db.into(db.products).insert(
            ProductsCompanion.insert(
              name: 'شاي العروسة 250 جم',
              code: const Value('TEA-01'),
              unit: 'علبة',
              currentPurchasePrice: 3600, // 36.00 ج.م
              currentSalePrice: 4500, // 45.00 ج.م
              currentQuantity: Value(Decimal.zero),
            ),
          );

      // 2. العملاء
      final cWalkIn = await db.into(db.customers).insert(
            CustomersCompanion.insert(
              name: 'مستهلك نقدي (زبون عابر)',
              phone: const Value('01000000000'),
            ),
          );

      final cMahmoud = await db.into(db.customers).insert(
            CustomersCompanion.insert(
              name: 'الحاج محمود البقال (محل تجزئة)',
              phone: const Value('01111111111'),
            ),
          );

      final cRestaurant = await db.into(db.customers).insert(
            CustomersCompanion.insert(
              name: 'مطعم السعادة للوجبات',
              phone: const Value('01222222222'),
            ),
          );

      // 3. الموردين
      final sAhram = await db.into(db.suppliers).insert(
            SuppliersCompanion.insert(
              name: 'شركة الأهرام للصناعات الغذائية',
              phone: const Value('0233333333'),
            ),
          );

      final sDelta = await db.into(db.suppliers).insert(
            SuppliersCompanion.insert(
              name: 'مزارع الدلتا للألبان والجبن',
              phone: const Value('0244444444'),
            ),
          );

      final sAfia = await db.into(db.suppliers).insert(
            SuppliersCompanion.insert(
              name: 'مجموعة عافية للزيوت النباتية',
              phone: const Value('0255555555'),
            ),
          );

      // =======================================================================
      // المرحلة 1: الأرصدة الافتتاحية وبدء التشغيل (Day 1 - Opening)
      // =======================================================================
      final openingRes = await openingBalanceRepo.saveOpeningBalances(
        OpeningBalanceInput(
          cashboxBalance: const Money(2500000), // 25,000.00 ج.م في الخزينة
          products: [
            ProductOpeningBalance(productId: pSugar, productName: 'سكر', unit: 'كيس', initialQuantity: Decimal.fromInt(100)),
            ProductOpeningBalance(productId: pCheese, productName: 'جبن', unit: 'كجم', initialQuantity: Decimal.parse('25.500')),
            ProductOpeningBalance(productId: pOil, productName: 'زيت', unit: 'زجاجة', initialQuantity: Decimal.fromInt(50)),
            ProductOpeningBalance(productId: pTea, productName: 'شاي', unit: 'علبة', initialQuantity: Decimal.fromInt(80)),
          ],
          customers: [
            StakeholderOpeningBalance(stakeholderId: cMahmoud, name: 'الحاج محمود', balance: const Money(50000)), // عليه 500.00 ج.م
          ],
          suppliers: [
            StakeholderOpeningBalance(stakeholderId: sAhram, name: 'شركة الأهرام', balance: const Money(120000)), // له 1,200.00 ج.م
          ],
        ),
      );
      expect(openingRes.isSuccess, isTrue, reason: 'حفظ الأرصدة الافتتاحية بنجاح');

      // تدقيق أرصدة اليوم الأول
      expect(await getCashbox(), 2500000);
      expect(await getStock(pSugar), Decimal.fromInt(100));
      expect(await getStock(pCheese), Decimal.parse('25.500'));
      expect(await getStock(pOil), Decimal.fromInt(50));
      expect(await getStock(pTea), Decimal.fromInt(80));
      expect(await getCustBalance(cMahmoud), 50000);
      expect(await getSuppBalance(sAhram), 120000);

      // =======================================================================
      // المرحلة 2: توريدات المشتريات الضخمة (Day 2 - Stocking up)
      // =======================================================================
      // شراء 1: من شركة الأهرام (150 سكر @ 28 = 4200، 100 شاي @ 36 = 3600. إجمالي 7800 ج.م. دفع 3000 كاش ومتبقي 4800 آجل)
      final buyAhram = await purchaseRepo.createPurchase(
        CreatePurchaseParams(
          supplierId: sAhram,
          purchaseDate: now.add(const Duration(hours: 1)),
          items: [
            PurchaseItemParam(productId: pSugar, quantity: Decimal.fromInt(150), unitCost: const Money(2800)),
            PurchaseItemParam(productId: pTea, quantity: Decimal.fromInt(100), unitCost: const Money(3600)),
          ],
          paidAmountAtCreation: const Money(300000), // دفع 3,000.00 ج.م
        ),
      );
      expect(buyAhram.isSuccess, isTrue);

      // شراء 2: من مزارع الدلتا (40.000 كجم جبن @ 260 = 10,400 ج.م آجل بالكامل)
      final buyDelta = await purchaseRepo.createPurchase(
        CreatePurchaseParams(
          supplierId: sDelta,
          purchaseDate: now.add(const Duration(hours: 2)),
          items: [
            PurchaseItemParam(productId: pCheese, quantity: Decimal.parse('40.000'), unitCost: const Money(26000)),
          ],
          paidAmountAtCreation: Money.zero,
        ),
      );
      expect(buyDelta.isSuccess, isTrue);

      // شراء 3: من مجموعة عافية (100 زجاجة زيت @ 52 = 5,200 ج.م كاش بالكامل)
      final buyAfia = await purchaseRepo.createPurchase(
        CreatePurchaseParams(
          supplierId: sAfia,
          purchaseDate: now.add(const Duration(hours: 3)),
          items: [
            PurchaseItemParam(productId: pOil, quantity: Decimal.fromInt(100), unitCost: const Money(5200)),
          ],
          paidAmountAtCreation: const Money(520000), // دفع 5,200.00 ج.م
        ),
      );
      expect(buyAfia.isSuccess, isTrue);

      // تدقيق أرصدة اليوم الثاني:
      // الخزينة: 25000 - 3000 - 5200 = 16,800.00 ج.م (1680000 قرش)
      expect(await getCashbox(), 1680000);
      expect(await getStock(pSugar), Decimal.fromInt(250)); // 100 + 150
      expect(await getStock(pCheese), Decimal.parse('65.500')); // 25.5 + 40
      expect(await getStock(pOil), Decimal.fromInt(150)); // 50 + 100
      expect(await getStock(pTea), Decimal.fromInt(180)); // 80 + 100
      expect(await getSuppBalance(sAhram), 600000); // 1200 + 4800 = 6000 ج.م
      expect(await getSuppBalance(sDelta), 1040000); // 10400 ج.م
      expect(await getSuppBalance(sAfia), 0); // كاش بالكامل

      // =======================================================================
      // المرحلة 3: يوم بيع نشط ومتنوع (Day 3 - Peak Sales Activity)
      // =======================================================================
      // بيع 1 (عميل عابر كاش): 5 سكر @ 35 = 175، 2 زيت @ 65 = 130، 1 شاي @ 45 = 45. إجمالي 350.00 ج.م كاش
      final s1 = await saleRepo.createSale(
        CreateSaleParams(
          customerId: cWalkIn,
          saleDate: now.add(const Duration(hours: 4)),
          items: [
            SaleItemParam(productId: pSugar, quantity: Decimal.fromInt(5), unitPrice: const Money(3500)),
            SaleItemParam(productId: pOil, quantity: Decimal.fromInt(2), unitPrice: const Money(6500)),
            SaleItemParam(productId: pTea, quantity: Decimal.fromInt(1), unitPrice: const Money(4500)),
          ],
          paidAmountAtCreation: const Money(35000),
        ),
      );
      expect(s1.isSuccess, isTrue);

      // بيع 2 (وزن دقيق كاش): 1.750 كجم جبن رومي @ 340 = 595.00 ج.م كاش
      final s2 = await saleRepo.createSale(
        CreateSaleParams(
          customerId: cWalkIn,
          saleDate: now.add(const Duration(hours: 5)),
          items: [
            SaleItemParam(productId: pCheese, quantity: Decimal.parse('1.750'), unitPrice: const Money(34000)),
          ],
          paidAmountAtCreation: const Money(59500),
        ),
      );
      expect(s2.isSuccess, isTrue);

      // بيع 3 (للحاج محمود البقال - دفع جزئي): 40 سكر @ 35 = 1400، 20 شاي @ 45 = 900. إجمالي 2300 ج.م. دفع 800 كاش ومتبقي 1500 آجل
      final s3 = await saleRepo.createSale(
        CreateSaleParams(
          customerId: cMahmoud,
          saleDate: now.add(const Duration(hours: 6)),
          items: [
            SaleItemParam(productId: pSugar, quantity: Decimal.fromInt(40), unitPrice: const Money(3500)),
            SaleItemParam(productId: pTea, quantity: Decimal.fromInt(20), unitPrice: const Money(4500)),
          ],
          paidAmountAtCreation: const Money(80000), // دفع 800 ج.م
        ),
      );
      expect(s3.isSuccess, isTrue);

      // بيع 4 (لمطعم السعادة - آجل 100%): 25 زيت @ 65 = 1625، 10.250 كجم جبن @ 340 = 3485، 30 سكر @ 35 = 1050. إجمالي 6160 ج.م
      final s4 = await saleRepo.createSale(
        CreateSaleParams(
          customerId: cRestaurant,
          saleDate: now.add(const Duration(hours: 7)),
          items: [
            SaleItemParam(productId: pOil, quantity: Decimal.fromInt(25), unitPrice: const Money(6500)),
            SaleItemParam(productId: pCheese, quantity: Decimal.parse('10.250'), unitPrice: const Money(34000)),
            SaleItemParam(productId: pSugar, quantity: Decimal.fromInt(30), unitPrice: const Money(3500)),
          ],
          paidAmountAtCreation: Money.zero,
        ),
      );
      expect(s4.isSuccess, isTrue);

      // تدقيق أرصدة اليوم الثالث:
      // الخزينة: 16800 + 350 + 595 + 800 = 18,545.00 ج.م (1854500 قرش)
      expect(await getCashbox(), 1854500);
      expect(await getStock(pSugar), Decimal.fromInt(175)); // 250 - 5 - 40 - 30
      expect(await getStock(pCheese), Decimal.parse('53.500')); // 65.5 - 1.75 - 10.25
      expect(await getStock(pOil), Decimal.fromInt(123)); // 150 - 2 - 25
      expect(await getStock(pTea), Decimal.fromInt(159)); // 180 - 1 - 20
      expect(await getCustBalance(cMahmoud), 200000); // 500 + 1500 = 2000 ج.م
      expect(await getCustBalance(cRestaurant), 616000); // 6160 ج.م

      // =======================================================================
      // المرحلة 4: المرتجعات ومعالجة العيوب (Day 4 - Customer & Supplier Returns)
      // =======================================================================
      // مرتجع 1: زبون عابر يعيد زجاجة زيت تالفة الغطاء ويسترد 65.00 ج.م كاش
      final r1 = await returnRepo.createCustomerReturn(
        CreateCustomerReturnParams(
          originalSaleId: s1.dataOrNull!.id,
          customerId: cWalkIn,
          returnDate: now.add(const Duration(hours: 8)),
          items: [
            ReturnItemParam(productId: pOil, quantity: Decimal.fromInt(1), unitPrice: const Money(6500)),
          ],
          refundCashAmount: const Money(6500),
        ),
      );
      expect(r1.isSuccess, isTrue);

      // مرتجع 2: الحاج محمود البقال يعيد 5 أكياس سكر @ 35 = 175.00 ج.م تخصم من حسابه
      final r2 = await returnRepo.createCustomerReturn(
        CreateCustomerReturnParams(
          originalSaleId: s3.dataOrNull!.id,
          customerId: cMahmoud,
          returnDate: now.add(const Duration(hours: 9)),
          items: [
            ReturnItemParam(productId: pSugar, quantity: Decimal.fromInt(5), unitPrice: const Money(3500)),
          ],
          refundCashAmount: Money.zero,
        ),
      );
      expect(r2.isSuccess, isTrue);

      // مرتجع 3: مرتجع شراء لشركة الأهرام لـ 10 أكياس سكر تالفة @ 28 = 280.00 ج.م تخصم من مستحقاتهم
      final r3 = await returnRepo.createSupplierReturn(
        CreateSupplierReturnParams(
          originalPurchaseId: buyAhram.dataOrNull!.id,
          supplierId: sAhram,
          returnDate: now.add(const Duration(hours: 10)),
          items: [
            ReturnItemParam(productId: pSugar, quantity: Decimal.fromInt(10), unitPrice: const Money(2800)),
          ],
          refundCashAmount: Money.zero,
        ),
      );
      expect(r3.isSuccess, isTrue);

      // تدقيق أرصدة اليوم الرابع:
      // الخزينة: 18545 - 65 = 18,480.00 ج.م (1848000 قرش)
      expect(await getCashbox(), 1848000);
      expect(await getStock(pOil), Decimal.fromInt(124)); // 123 + 1
      expect(await getStock(pSugar), Decimal.fromInt(170)); // 175 + 5 - 10
      expect(await getCustBalance(cMahmoud), 182500); // 2000 - 175 = 1825 ج.م
      expect(await getSuppBalance(sAhram), 572000); // 6000 - 280 = 5720 ج.م

      // =======================================================================
      // المرحلة 5: المصروفات التشغيلية والسيولة (Day 5 - Expenses & Cashbox Injections)
      // =======================================================================
      // 1. إيداع سيولة إضافية من المالك في الخزينة: 5,000.00 ج.م (500000 قرش)
      await db.into(db.cashboxTransactions).insert(
            CashboxTransactionsCompanion.insert(
              transactionType: 'deposit_in',
              amount: 500000,
              direction: 'in',
              balanceAfter: 1848000 + 500000,
              note: const Value('إيداع سيولة نقدية من صاحب المحل'),
            ),
          );
      expect(await getCashbox(), 2348000);

      // 2. تسجيل 3 مصروفات تشغيلية
      final exp1 = await expenseRepo.recordExpense(
        category: 'كهرباء وتكييف',
        amount: const Money(45000), // 450.00 ج.م
        expenseDate: now.add(const Duration(hours: 11)),
      );
      expect(exp1.isSuccess, isTrue);

      final exp2 = await expenseRepo.recordExpense(
        category: 'إيجار المخزن',
        amount: const Money(120000), // 1,200.00 ج.م
        expenseDate: now.add(const Duration(hours: 12)),
      );
      expect(exp2.isSuccess, isTrue);

      final exp3 = await expenseRepo.recordExpense(
        category: 'مستلزمات وبوفيه',
        amount: const Money(8550), // 85.50 ج.م
        expenseDate: now.add(const Duration(hours: 13)),
      );
      expect(exp3.isSuccess, isTrue);

      // إجمالي المصروفات = 450 + 1200 + 85.50 = 1735.50 ج.م
      // رصيد الخزينة = 23,480 - 1735.50 = 21,744.50 ج.م (2174450 قرش)
      expect(await getCashbox(), 2174450);

      // =======================================================================
      // المرحلة 6: التحصيلات وسداد الموردين (Day 6 - Collections & Supplier Payments)
      // =======================================================================
      // تحصيل 1: الحاج محمود البقال يسدد 1,000.00 ج.م نقداً
      final payCust1 = await customerPaymentRepo.recordPayment(
        customerId: cMahmoud,
        amount: const Money(100000),
        paymentDate: now.add(const Duration(hours: 14)),
      );
      expect(payCust1.isSuccess, isTrue);
      expect(await getCustBalance(cMahmoud), 82500); // 1825 - 1000 = 825 ج.م

      // تحصيل 2: مطعم السعادة يسدد 3,500.00 ج.م نقداً
      final payCust2 = await customerPaymentRepo.recordPayment(
        customerId: cRestaurant,
        amount: const Money(350000),
        paymentDate: now.add(const Duration(hours: 15)),
      );
      expect(payCust2.isSuccess, isTrue);
      expect(await getCustBalance(cRestaurant), 266000); // 6160 - 3500 = 2660 ج.م

      // الخزينة بعد التحصيلات: 21,744.50 + 1,000 + 3,500 = 26,244.50 ج.م
      expect(await getCashbox(), 2624450);

      // سداد 1: دفع 3,000.00 ج.م لشركة الأهرام نقداً من الخزينة
      final paySupp1 = await supplierPaymentRepo.recordPayment(
        supplierId: sAhram,
        amount: const Money(300000),
        paymentDate: now.add(const Duration(hours: 16)),
      );
      expect(paySupp1.isSuccess, isTrue);
      expect(await getSuppBalance(sAhram), 272000); // 5720 - 3000 = 2720 ج.م

      // سداد 2: دفع 4,000.00 ج.م لمزارع الدلتا للألبان نقداً من الخزينة
      final paySupp2 = await supplierPaymentRepo.recordPayment(
        supplierId: sDelta,
        amount: const Money(400000),
        paymentDate: now.add(const Duration(hours: 17)),
      );
      expect(paySupp2.isSuccess, isTrue);
      expect(await getSuppBalance(sDelta), 640000); // 10400 - 4000 = 6400 ج.م

      // الخزينة بعد السدادات: 26,244.50 - 3,000 - 4,000 = 19,244.50 ج.م (1924450 قرش)
      expect(await getCashbox(), 1924450);

      // =======================================================================
      // المرحلة 7: الجرد المخزني الفعلي والتسويات (Day 7 - Physical Audit)
      // =======================================================================
      // تسوية 1: العثور على كيس سكر إضافي أثناء الجرد (+1 كيس)
      final adj1 = await inventoryRepo.recordAdjustment(
        productId: pSugar,
        quantityDelta: Decimal.fromInt(1),
        reason: 'عثور على كيس زائد أثناء الجرد الأسبوعي',
      );
      expect(adj1.isSuccess, isTrue);
      expect(await getStock(pSugar), Decimal.fromInt(171)); // 170 + 1 = 171

      // تسوية 2: عجز جفاف وتقطيع في الجبن الرومي (-0.350 كجم)
      final adj2 = await inventoryRepo.recordAdjustment(
        productId: pCheese,
        quantityDelta: Decimal.parse('-0.350'),
        reason: 'هدر وزن وتطاير وجفاف طبيعي أثناء التقطيع',
      );
      expect(adj2.isSuccess, isTrue);
      expect(await getStock(pCheese), Decimal.parse('53.150')); // 53.500 - 0.350 = 53.150

      // =======================================================================
      // المرحلة 8: اختبارات الحافة والمنع والأمان (Day 8 - Edge-Cases & Attack Guard)
      // =======================================================================
      // محاولة بيع 200 كيس سكر بينما المتوفر 171
      final failSale = await saleRepo.createSale(
        CreateSaleParams(
          customerId: cWalkIn,
          saleDate: now.add(const Duration(hours: 18)),
          items: [
            SaleItemParam(productId: pSugar, quantity: Decimal.fromInt(200), unitPrice: const Money(3500)),
          ],
          paidAmountAtCreation: Money.zero,
        ),
      );
      expect(failSale.isFailure, isTrue);
      expect(failSale.failureOrNull, isA<InsufficientStockFailure>());
      expect(await getStock(pSugar), Decimal.fromInt(171), reason: 'لم يتأثر المخزون إطلاقاً');

      // محاولة إرجاع 60 كجم جبن للمورد بينما المتوفر 53.150 كجم
      final failSuppRet = await returnRepo.createSupplierReturn(
        CreateSupplierReturnParams(
          supplierId: sDelta,
          returnDate: now.add(const Duration(hours: 19)),
          items: [
            ReturnItemParam(productId: pCheese, quantity: Decimal.fromInt(60), unitPrice: const Money(26000)),
          ],
        ),
      );
      expect(failSuppRet.isFailure, isTrue);
      expect(failSuppRet.failureOrNull, isA<InsufficientStockFailure>());
      expect(await getStock(pCheese), Decimal.parse('53.150'));

      // محاولة مرتجع نقدي للزبون بمبلغ 50,000 ج.م بينما الخزينة 19,244.50 ج.م
      final failCustRet = await returnRepo.createCustomerReturn(
        CreateCustomerReturnParams(
          customerId: cWalkIn,
          returnDate: now.add(const Duration(hours: 20)),
          items: [
            ReturnItemParam(productId: pSugar, quantity: Decimal.fromInt(1), unitPrice: const Money(3500)),
          ],
          refundCashAmount: const Money(5000000), // 50,000.00 ج.م
        ),
      );
      expect(failCustRet.isFailure, isTrue);
      expect(failCustRet.failureOrNull, isA<ValidationFailure>());
      expect(await getCashbox(), 1924450, reason: 'لم تمس الخزينة');

      // =======================================================================
      // المرحلة 9: مطابقة التقارير والقوائم المالية (Day 9 - Financial Reports Audit)
      // =======================================================================
      final dateFrom = now.subtract(const Duration(days: 1));
      final dateTo = now.add(const Duration(days: 2));

      // 1. تقرير حركة الخزينة
      final cashboxReportRes = await reportRepo.getCashboxReport(from: dateFrom, to: dateTo);
      expect(cashboxReportRes.isSuccess, isTrue);
      final cbReport = cashboxReportRes.dataOrNull!;
      expect(cbReport.closingBalance, const Money(1924450)); // 19,244.50 ج.م بالضبط

      // 2. تقرير المخزون وقيمة بضاعة آخر المدة بالتكلفة
      final invReportRes = await reportRepo.getInventoryReport(from: dateFrom, to: dateTo);
      expect(invReportRes.isSuccess, isTrue);
      final invReport = invReportRes.dataOrNull!;
      expect(invReport.totalProductsCount, 4);

      // التحقق من تقييم المخزون بالتكلفة الدقيقة بالقرش:
      // سكر: 171 * 28 = 4,788.00 ج.م (478800 قرش)
      // جبن: 53.150 * 260 = 13,819.00 ج.م (1381900 قرش)
      // زيت: 124 * 52 = 6,448.00 ج.م (644800 قرش)
      // شاي: 159 * 36 = 5,724.00 ج.م (572400 قرش)
      // إجمالي قيمة المخزون بالتكلفة = 4788 + 13819 + 6448 + 5724 = 30,779.00 ج.م (3077900 قرش)
      expect(invReport.totalValuationAtCost, const Money(3077900));

      // 3. تقرير كشف حساب العميل (الحاج محمود البقال)
      final custReportRes = await reportRepo.getCustomerReport(customerId: cMahmoud, from: dateFrom, to: dateTo);
      expect(custReportRes.isSuccess, isTrue);
      final custReport = custReportRes.dataOrNull!;
      expect(custReport.closingBalance, const Money(82500)); // 825.00 ج.م

      // 4. تقرير كشف حساب المورد (شركة الأهرام)
      final suppReportRes = await reportRepo.getSupplierReport(supplierId: sAhram, from: dateFrom, to: dateTo);
      expect(suppReportRes.isSuccess, isTrue);
      final suppReport = suppReportRes.dataOrNull!;
      expect(suppReport.closingBalance, const Money(272000)); // 2,720.00 ج.م

      // 5. تقرير إجمالي مستحقات الموردين والعملاء
      final allCustRes = await reportRepo.getAllCustomerBalances();
      expect(allCustRes.isSuccess, isTrue);
      final custBalances = allCustRes.dataOrNull!;
      final totalCustDebt = custBalances.fold<int>(0, (sum, c) => sum + c.balance.piastres);
      expect(totalCustDebt, 82500 + 266000); // 3,485.00 ج.م (348500 قرش)

      final allSuppRes = await reportRepo.getAllSupplierBalances();
      expect(allSuppRes.isSuccess, isTrue);
      final suppBalances = allSuppRes.dataOrNull!;
      final totalSuppDue = suppBalances.fold<int>(0, (sum, s) => sum + s.balance.piastres);
      expect(totalSuppDue, 272000 + 640000); // 9,120.00 ج.م (912000 قرش)

      // =======================================================================
      // المرحلة 10: المراجعة المحاسبية الرياضية الصفرية (Day 10 - Zero-Drift Audit)
      // =======================================================================
      // 1. التأكد من عدم وجود أي مليم تائه في الخزينة
      final allCashboxTxs = await (db.select(db.cashboxTransactions)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
      var calculatedCashbox = 0;
      for (final tx in allCashboxTxs) {
        if (tx.direction == 'in') {
          calculatedCashbox += tx.amount;
        } else {
          calculatedCashbox -= tx.amount;
        }
        expect(tx.balanceAfter, calculatedCashbox, reason: 'تطابق الرصيد التراكمي balanceAfter في الحركة رقم ${tx.id}');
      }
      expect(calculatedCashbox, 1924450);

      // 2. التحقق من سلامة سجل التدقيق الرقابي الكامل
      final auditLogs = await (db.select(db.auditLog)).get();
      expect(auditLogs.isNotEmpty, isTrue);
      expect(auditLogs.any((a) => a.entityType == 'sale'), isTrue);
      expect(auditLogs.any((a) => a.entityType == 'purchase'), isTrue);
      expect(auditLogs.any((a) => a.entityType == 'system' && a.action == 'opening_balance'), isTrue);

      // النتيجة النهائية:
      // المتجر يعمل بنسبة 100% وبدقة محاسبية مطلقة على مستوى القرش وكسر الجرام!
    });
  });
}
