# TASK_H — المرحلة 8: المرتجعات (P8-01 + P8-02)
> تعتمد على: TASK_D (المبيعات) + TASK_E (المشتريات)
> تعمل بالتوازي مع TASK_G

---

## السياق الإلزامي

اقرأ بالترتيب:
1. `docs/ARCHITECTURE_MASTER.md` — §8.5 (مرتجع عميل) و§8.6 (مرتجع مورد) و§7.10
2. `docs/AGENT_RULES.md`
3. `docs/DART_RULES.md` + `docs/FLUTTER_RULES.md`
4. `lib/features/sales/` و`lib/features/purchases/` — مرجع الكود

---

## دورك في النظام الكامل

المرتجعات = عكس جزء أو كل عملية سابقة (بيع أو شراء):
- **مرتجع من عميل:** البضاعة ترجع → مخزون يزيد + رصيد عميل ينقص + لا تأثير على الخزينة (الأصل)
- **مرتجع لمورد:** البضاعة ترجع للمورد → مخزون ينقص + رصيد مورد ينقص

لاحظ: المرتجع لا يُلغي البيع/الشراء بالكامل — هو عملية جديدة مستقلة قد ترتبط بفاتورة أصلية اختيارياً.

---

## ما هو موجود بالفعل

```
// الجداول (كلها في DB):
returns_customer, return_customer_items
returns_supplier, return_supplier_items

// هيكل returns_customer:
id | original_sale_id (nullable) | customer_id | return_date | total_amount | note | created_at

// هيكل return_customer_items:
id | return_id | product_id | quantity (Decimal) | unit_price (int, قرش)
```

---

## P8-01: مرتجع من عميل

### نموذج المرتجع:
```
[اختيار العميل] ← Dropdown/Search
[ربط بفاتورة أصلية] ← اختياري: Dropdown فواتير العميل
  → إذا تم الربط: تُملأ الأصناف تلقائياً من الفاتورة (قابلة للتعديل)
[جدول أصناف المرتجع]:
  المنتج | الكمية المُرتجَعة | سعر الوحدة
[ملاحظة] ← اختياري
[Preview]: "سيرجع للمخزون X وحدة، سيُعدَّل رصيد العميل بـ Y جنيه"
```

### تدفق UseCase الذري — Transaction واحدة:
```
1. تحقق: كل الأصناف موجودة ونشطة
2. تحقق: الكمية المُرتجَعة > 0 لكل صنف
3. أدرج returns_customer + return_customer_items
4. لكل صنف:
   a. أدرج inventory_movements (customer_return, موجب, balanceAfter)
   b. حدّث products.current_quantity += quantityReturned
5. احسب totalReturnValue = sum(quantity * unit_price) لكل صنف
6. احسب newBalance = customer.currentBalance - totalReturnValue
7. أدرج customer_ledger_entries (return, decrease, balanceAfter = newBalance)
8. حدّث customers.current_balance = newBalance
9. audit_log
10. Commit أو Rollback
```

**ملاحظة:** مرتجع العميل لا يؤثر على الخزينة بشكل تلقائي — إذا كان هناك استرداد نقدي يُتعامل معه كتحصيل عكسي يُسجَّل يدوياً.

---

## P8-02: مرتجع لمورد

العكس التام لـP8-01:
```
1. أدرج returns_supplier + return_supplier_items
2. لكل صنف:
   a. أدرج inventory_movements (supplier_return, سالب, balanceAfter)
   b. حدّث products.current_quantity -= quantityReturned
   (تحقق: لا مخزون سالب)
3. احسب totalReturnValue
4. احسب newBalance = supplier.currentBalance - totalReturnValue
5. أدرج supplier_ledger_entries (return, decrease, balanceAfter)
6. حدّث suppliers.current_balance
7. audit_log
8. Commit أو Rollback
```

---

## الملفات المطلوبة

```
lib/features/returns/domain/entities/customer_return.dart
lib/features/returns/domain/entities/customer_return_item.dart
lib/features/returns/domain/entities/supplier_return.dart
lib/features/returns/domain/entities/supplier_return_item.dart
lib/features/returns/domain/repositories/returns_repository.dart
lib/features/returns/domain/usecases/create_customer_return_usecase.dart
lib/features/returns/domain/usecases/create_supplier_return_usecase.dart
lib/features/returns/domain/usecases/watch_customer_returns_usecase.dart
lib/features/returns/domain/usecases/watch_supplier_returns_usecase.dart
lib/features/returns/data/daos/returns_dao.dart
lib/features/returns/data/repositories/returns_repository_impl.dart
lib/features/returns/presentation/cubit/returns_cubit.dart
lib/features/returns/presentation/cubit/returns_state.dart
lib/features/returns/presentation/pages/returns_page.dart
lib/features/returns/presentation/widgets/customer_return_form.dart
lib/features/returns/presentation/widgets/supplier_return_form.dart
```

---

## الملفات المشتركة التي تُعدَّل

**`injector.dart`:** أضف ReturnsDao + ReturnsRepository + UseCases

**`app_database.dart`:** أضف `ReturnsDao` في قائمة `daos`

**`app_router.dart`:**
```dart
GoRoute(path: '/returns', builder: (_, __) => const ReturnsPage()),
```

**`app_router.dart` — MainDesktopShell:** أضف "المرتجعات" للـNavigationRail

**بعد التعديل:** `dart run build_runner build --delete-conflicting-outputs`

---

## نقاط الترابط مع المراحل القادمة

### I (التقارير) تعتمد على:
- `returns_customer` مع فلاتر تاريخ/عميل
- `inventory_movements` بنوع `customer_return` و`supplier_return`

### J (Dashboard) تعتمد على:
- عدد المرتجعات اليومية (Stream)

---

## تعريف الاكتمال (DoD)

- [ ] `flutter analyze` = "No issues found!"
- [ ] `flutter test` = كل الاختبارات ناجحة
- [ ] مرتجع العميل: مخزون يزيد + رصيد عميل ينقص (Transaction ذرية)
- [ ] مرتجع المورد: مخزون ينقص (مع منع السالب) + رصيد مورد ينقص
- [ ] الربط بفاتورة أصلية يعمل (اختياري)
- [ ] كشف حساب العميل/المورد يعرض المرتجعات
