# TASK_E — المرحلة 5: المشتريات (P5-01 إلى P5-04)
> تعتمد على: TASK_B (الموردون) + TASK_C (الأرصدة الافتتاحية)
> تعمل بالتوازي مع TASK_D (المبيعات) — لا تعتمد عليها

---

## السياق الإلزامي

اقرأ بالترتيب:
1. `docs/ARCHITECTURE_MASTER.md` — خاصةً §8.2 (تدفق الشراء)
2. `docs/AGENT_RULES.md`
3. `docs/DART_RULES.md` + `docs/FLUTTER_RULES.md`
4. `lib/features/sales/` — **مرجعك الكود** (المشتريات = مرآة المبيعات)

---

## دورك في النظام الكامل

المشتريات تُحرّك النظام بالعكس تماماً عن المبيعات:
- مخزون المنتجات (يزيد)
- رصيد المورد (يزيد — نحن ندين له)
- رصيد الخزينة (ينقص إن نقدي أو جزئي)
- كشف حساب المورد (إدخال جديد)
- سجل حركة المخزون (إدخال موجب لكل صنف)
- سجل التتبع (AuditLog)

كلها في **Transaction واحدة**.

---

## ما هو موجود بالفعل

```
// الجداول (كلها في الـDB المُولَّد):
purchases, purchase_items, supplier_ledger_entries, suppliers
inventory_movements, cashbox_transactions, audit_log

// من TASK_B:
SupplierRepository + SuppliersDao

// من P1:
ProductRepository + GetProductsUseCase
```

---

## P5-01: نموذج الشراء (UI)

نفس `CreateSalePage` بالضبط مع هذه الفروق:
- **"المورد"** بدلاً من "العميل"
- **"سعر الشراء"** (auto من `currentPurchasePrice` قابل للتعديل)
- **لا قيد على الكمية** — يمكن شراء أي كمية (المخزون يزيد)
- **Preview الأثر:** "سيُضاف للمخزون X وحدة" + "سيزيد دين المورد Y جنيه" + "ستنقص الخزينة Z جنيه"
- `paidAmountAtCreation` ← ما دُفع للمورد الآن

---

## P5-02: UseCase الشراء الذري

**CreatePurchaseParams:**
```dart
class CreatePurchaseParams {
  final int supplierId;
  final DateTime purchaseDate;
  final List<PurchaseItemParam> items; // productId + quantity (Decimal) + unitCost (Money)
  final Money paidAmountAtCreation;
}
```

**تدفق `PurchaseRepositoryImpl.createPurchase()` — Transaction واحدة:**
```
1. احسب invoiceNo = MAX(invoice_no) + 1 (في جدول purchases)
2. أدرج purchases row
3. لكل صنف:
   a. أدرج purchase_items (مع Snapshot unit_cost_at_purchase)
   b. احسب balanceAfter = currentQuantity + quantity
   c. أدرج inventory_movements (purchase, موجب, balanceAfter)
   d. حدّث products.current_quantity += quantity
   e. حدّث products.current_purchase_price = unitCost (آخر سعر شراء)
4. احسب المتبقي = totalAmount - paidAmount
5. إذا المتبقي > 0:
   a. أدرج supplier_ledger_entries (purchase, increase, balanceAfter)
   b. حدّث suppliers.current_balance
6. إذا paidAmount > 0:
   a. احسب currentCashboxBalance من آخر صف في cashbox_transactions
   b. أدرج cashbox_transactions (purchase_cash_out, out, balanceAfter)
7. أدرج audit_log
8. Commit أو Rollback
```

---

## P5-03: قائمة المشتريات + التفاصيل

نفس `SalesListPage` + `SaleDetailPage` بالضبط مع:
- عرض اسم المورد بدلاً من العميل
- عرض "سعر الشراء" بدلاً من "سعر البيع"
- ألوان: أخضر = نقدي كامل، برتقالي = جزئي، أحمر = آجل كامل

---

## P5-04: عكس عملية شراء

نفس منطق `ReverseSaleUseCase` بعكس الاتجاه:
```
1. تحقق أن الشراء لم يُعكس مسبقاً
2. تحقق أن عكس الكمية لن يُنتج مخزوناً سالباً
   (لو تم بيع جزء من المشتريات لاحقاً — تحقق من currentQuantity)
3. حدّث purchases.status = 'reversed'
4. لكل صنف: inventory_movements (reversal, سالب) + حدّث current_quantity
5. إذا كان هناك دين على المورد: supplier_ledger_entries (reversal, decrease) + حدّث current_balance
6. إذا دُفع للخزينة: cashbox_transactions (reversal, in)
7. audit_log
```

---

## الملفات المطلوبة

```
lib/features/purchases/domain/entities/purchase.dart
lib/features/purchases/domain/entities/purchase_item.dart
lib/features/purchases/domain/repositories/purchase_repository.dart
lib/features/purchases/domain/usecases/create_purchase_usecase.dart
lib/features/purchases/domain/usecases/get_purchases_usecase.dart
lib/features/purchases/domain/usecases/watch_purchases_usecase.dart
lib/features/purchases/domain/usecases/reverse_purchase_usecase.dart
lib/features/purchases/data/daos/purchases_dao.dart
lib/features/purchases/data/models/purchase_mapper.dart
lib/features/purchases/data/repositories/purchase_repository_impl.dart
lib/features/purchases/presentation/cubit/purchases_list_cubit.dart
lib/features/purchases/presentation/cubit/purchases_list_state.dart
lib/features/purchases/presentation/cubit/create_purchase_cubit.dart
lib/features/purchases/presentation/cubit/create_purchase_state.dart
lib/features/purchases/presentation/pages/purchases_list_page.dart
lib/features/purchases/presentation/pages/purchase_detail_page.dart
lib/features/purchases/presentation/pages/create_purchase_page.dart
```

---

## الملفات المشتركة التي تُعدَّل

**`injector.dart`:**
```dart
getIt.registerLazySingleton<PurchasesDao>(() => PurchasesDao(getIt()));
getIt.registerLazySingleton<PurchaseRepository>(() => PurchaseRepositoryImpl(db: getIt(), dao: getIt()));
getIt.registerLazySingleton<CreatePurchaseUseCase>(() => CreatePurchaseUseCase(getIt()));
getIt.registerLazySingleton<GetPurchasesUseCase>(() => GetPurchasesUseCase(getIt()));
getIt.registerLazySingleton<WatchPurchasesUseCase>(() => WatchPurchasesUseCase(getIt()));
getIt.registerLazySingleton<ReversePurchaseUseCase>(() => ReversePurchaseUseCase(getIt()));
```

**`app_database.dart`:** أضف `PurchasesDao` في قائمة `daos`

**`app_router.dart`:**
```dart
GoRoute(path: '/purchases', builder: (_, __) => const PurchasesListPage()),
GoRoute(path: '/purchases/create', builder: (_, __) => const CreatePurchasePage()),
GoRoute(path: '/purchases/:id', builder: (context, state) =>
  PurchaseDetailPage(id: int.parse(state.pathParameters['id']!))),
```

بعد التعديل: `dart run build_runner build --delete-conflicting-outputs`

---

## نقاط الترابط مع المراحل القادمة

### F (مدفوعات الموردين) تعتمد على:
- `purchase.id` — لربط الدفعة بفاتورة شراء
- `supplier.currentBalance` — يُقلَّل عند الدفع

### H (مرتجعات موردين) تعتمد على:
- `purchase.id` — المرتجع قد يرتبط بفاتورة شراء
- `products.current_quantity` — ينقص عند إعادة البضاعة للمورد

### I (تقرير المخزون) تعتمد على:
- `inventory_movements` بنوع `purchase`

---

## تعريف الاكتمال (DoD)

- [ ] `flutter analyze` = "No issues found!"
- [ ] `flutter test` = كل الاختبارات ناجحة
- [ ] Transaction ذرية كاملة (مخزون + لدجر مورد + خزينة + audit)
- [ ] `products.current_purchase_price` يُحدَّث بآخر سعر شراء
- [ ] عكس الشراء يتحقق من عدم إنتاج مخزون سالب
- [ ] قائمة المشتريات وتفاصيل الفاتورة تعمل
