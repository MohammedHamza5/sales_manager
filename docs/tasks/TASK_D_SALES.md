# TASK_D — المرحلة 4: المبيعات (P4-01 إلى P4-04)
> تعتمد على: TASK_B (العملاء) + TASK_C (الأرصدة الافتتاحية)

---

## السياق الإلزامي

اقرأ بالترتيب:
1. `docs/ARCHITECTURE_MASTER.md` — خاصةً §8.1 (تدفق البيع الذري) و§9 (الشاشات)
2. `docs/AGENT_RULES.md` — خاصةً البند 6 (منع البيع بالسالب — قرار مقفول)
3. `docs/DART_RULES.md`
4. `docs/FLUTTER_RULES.md`
5. `lib/features/products/` و`lib/features/customers/` — مرجع الكود المبني

---

## دورك في النظام الكامل

المبيعات هي **قلب النظام** — تُحرّك:
- مخزون المنتجات (ينقص)
- رصيد العميل (يزيد إن آجل أو جزئي)
- رصيد الخزينة (يزيد إن نقدي أو جزئي)
- كشف حساب العميل (إدخال جديد)
- سجل حركة المخزون (إدخال جديد لكل صنف)
- سجل التتبع (AuditLog)

كلها في **Transaction واحدة**.

---

## P4-01: نموذج البيع (UI)

**نموذج الفاتورة يحتوي:**
```
[اختيار العميل] ← Dropdown/Search يستخدم GetCustomersUseCase
[تاريخ البيع] ← DatePicker (افتراضي: اليوم)
[جدول الأصناف]:
  - [اختيار المنتج] ← Search/Autocomplete يستخدم GetProductsUseCase
  - [الكمية] ← TextField (Decimal)
  - [السعر] ← auto من currentSalePrice (قابل للتعديل)
  - [الإجمالي] ← محسوب تلقائياً
  - [زر حذف الصنف]
[زر إضافة صنف]
[إجمالي الفاتورة] ← محسوب
[المبلغ المدفوع الآن] ← TextField (0 = آجل كامل، أقل من الإجمالي = جزئي)
[المتبقي على العميل] ← محسوب = الإجمالي - المدفوع

[Preview فوري للأثر:]
"سيتأثر مخزون X منتجات"
"سيُضاف للعميل دين بقيمة Y جنيه" أو "سيُسجَّل كبيع نقدي"
"سيُضاف للخزينة Z جنيه"
```

**قاعدة منع البيع بالسالب (قرار مقفول #6):**
قبل الحفظ — لكل صنف:
- إذا الكمية المطلوبة > `product.currentQuantity` → أظهر خطأ فورياً في الصف
- زر "حفظ" يبقى معطّلاً حتى تُحلّ كل الأخطاء
- لا حوار تأكيد، الرفض مباشر

---

## P4-02: UseCase البيع الذري

```dart
class CreateSaleUseCase {
  final SaleRepository _repo;
  CreateSaleUseCase(this._repo);
  
  Future<Result<Sale>> call(CreateSaleParams params) => _repo.createSale(params);
}
```

**CreateSaleParams:**
```dart
class CreateSaleParams {
  final int customerId;
  final DateTime saleDate;
  final List<SaleItemParam> items; // productId + quantity (Decimal) + unitPrice (Money)
  final Money paidAmountAtCreation; // ما دُفع الآن
}
```

**تدفق `SaleRepositoryImpl.createSale()` — Transaction واحدة:**
```
1. تحقق: لكل صنف → currentQuantity >= المطلوب (وإلا: InsufficientStockFailure)
2. احسب invoiceNo = MAX(invoice_no) + 1
3. أدرج sales row
4. لكل صنف:
   a. أدرج sale_items row (مع Snapshot السعر)
   b. أدرج inventory_movements (sale, سالب, balance_after محسوب)
   c. حدّث products.current_quantity
5. احسب المتبقي = totalAmount - paidAmount
6. إذا المتبقي > 0:
   a. أدرج customer_ledger_entries (sale, increase, balanceAfter محسوب)
   b. حدّث customers.current_balance
7. إذا paidAmount > 0:
   a. احسب currentCashboxBalance من آخر صف في cashbox_transactions
   b. أدرج cashbox_transactions (sale_cash_in, in, balanceAfter)
8. أدرج audit_log
9. Commit أو Rollback
```

**Failure types جديدة (أضفها في `failures.dart`):**
```dart
class InsufficientStockFailure extends Failure {
  final int productId;
  final String productName;
  final Decimal available;
  final Decimal requested;
}
```

---

## P4-03: قائمة المبيعات + تفاصيل الفاتورة

**SalesListPage:**
- قائمة مبيعات مع فلتر تاريخ + بحث باسم عميل/رقم فاتورة
- بطاقة الفاتورة: رقم الفاتورة | اسم العميل | التاريخ | الإجمالي | المدفوع | المتبقي | الحالة (confirmed/reversed)
- ألوان: أخضر = نقدي كامل، برتقالي = جزئي، أحمر = آجل كامل، رمادي = مُلغاة

**SaleDetailPage:**
- رأس الفاتورة + جدول الأصناف + ملخص مالي
- زر "طباعة" (يمرر بيانات الفاتورة لـP12)
- زر "إلغاء/عكس" (ينتقل لـP4-04)

---

## P4-04: إلغاء/عكس عملية بيع

**قاعدة لا تُكسر:** لا حذف، لا تعديل — فقط Reversal جديد.

```
Transaction عكس البيع:
1. تحقق أن البيع لم يُعكس مسبقاً (status != reversed)
2. حدّث sales.status = 'reversed'
3. لكل صنف أصلي:
   a. أدرج inventory_movements (reversal, موجب) + حدّث current_quantity
4. إذا كان هناك دين على العميل من هذا البيع:
   a. أدرج customer_ledger_entries (reversal, decrease) + حدّث current_balance
5. إذا كان هناك مبلغ دخل الخزينة:
   a. أدرج cashbox_transactions (reversal, out)
6. audit_log
```

---

## الملفات المطلوبة

```
lib/features/sales/domain/entities/sale.dart
lib/features/sales/domain/entities/sale_item.dart
lib/features/sales/domain/repositories/sale_repository.dart
lib/features/sales/domain/usecases/create_sale_usecase.dart
lib/features/sales/domain/usecases/get_sales_usecase.dart
lib/features/sales/domain/usecases/watch_sales_usecase.dart
lib/features/sales/domain/usecases/reverse_sale_usecase.dart
lib/features/sales/data/daos/sales_dao.dart
lib/features/sales/data/models/sale_mapper.dart
lib/features/sales/data/repositories/sale_repository_impl.dart
lib/features/sales/presentation/cubit/sales_list_cubit.dart
lib/features/sales/presentation/cubit/sales_list_state.dart
lib/features/sales/presentation/cubit/create_sale_cubit.dart
lib/features/sales/presentation/cubit/create_sale_state.dart
lib/features/sales/presentation/pages/sales_list_page.dart
lib/features/sales/presentation/pages/sale_detail_page.dart
lib/features/sales/presentation/pages/create_sale_page.dart
lib/features/sales/presentation/widgets/sale_item_row.dart
lib/features/sales/presentation/widgets/product_search_field.dart
```

---

## الملفات المشتركة التي تُعدَّل

### injector.dart:
```dart
getIt.registerLazySingleton<SalesDao>(() => SalesDao(getIt()));
getIt.registerLazySingleton<SaleRepository>(() => SaleRepositoryImpl(db: getIt(), dao: getIt()));
getIt.registerLazySingleton<CreateSaleUseCase>(() => CreateSaleUseCase(getIt()));
getIt.registerLazySingleton<GetSalesUseCase>(() => GetSalesUseCase(getIt()));
getIt.registerLazySingleton<WatchSalesUseCase>(() => WatchSalesUseCase(getIt()));
getIt.registerLazySingleton<ReverseSaleUseCase>(() => ReverseSaleUseCase(getIt()));
```

### app_database.dart:
```dart
daos: [..., SalesDao]
```

### app_router.dart:
```dart
GoRoute(path: '/sales', builder: (_, __) => const SalesListPage()),
GoRoute(path: '/sales/create', builder: (_, __) => const CreateSalePage()),
GoRoute(path: '/sales/:id', builder: (context, state) => SaleDetailPage(id: int.parse(state.pathParameters['id']!))),
```

### failures.dart:
أضف `InsufficientStockFailure`

---

## نقاط الترابط الحرجة مع المراحل القادمة

### P6 (التحصيلات) تعتمد على:
- `sale.id` — لربط الدفعة بفاتورة محددة (اختياري)
- `customer.currentBalance` — يُقلَّل عند التحصيل

### P8 (المرتجعات) تعتمد على:
- `sale.id` — المرتجع يرتبط بفاتورة أصلية (اختياري)

### P9 (التقارير) تعتمد على:
- `sales` + `sale_items` مع فلاتر تاريخ
- `inventory_movements` بنوع `sale`

### P10 (Dashboard) تعتمد على:
- Stream على `sales` اليوم — إجمالي مبيعات اليوم

### P12 (الطباعة) تعتمد على:
- `Sale` entity + `List<SaleItem>` entity + اسم العميل

---

## تعريف الاكتمال (DoD)

- [ ] `flutter analyze` = "No issues found!"
- [ ] `flutter test` = كل الاختبارات ناجحة
- [ ] البيع بالسالب مرفوض بالكامل في الـUseCase
- [ ] Transaction ذرية: فشل أي خطوة = Rollback كامل
- [ ] الرقم التسلسلي للفاتورة (invoiceNo) صحيح ومتسلسل
- [ ] كشف حساب العميل يُحدَّث فورياً بعد البيع (Drift Stream)
- [ ] حركة المخزون تُسجَّل لكل صنف
- [ ] رصيد الخزينة يُحدَّث عند البيع النقدي/الجزئي
