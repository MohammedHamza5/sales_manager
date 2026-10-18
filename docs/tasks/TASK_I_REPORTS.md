# TASK_I — المرحلة 9: التقارير الستة (P9-01 إلى P9-06)
> تعتمد على: كل المراحل من D إلى H

---

## السياق الإلزامي

اقرأ بالترتيب:
1. `docs/ARCHITECTURE_MASTER.md` — §10 (التقارير الستة)
2. `docs/AGENT_RULES.md`
3. `docs/FLUTTER_RULES.md`

---

## دورك في النظام الكامل

التقارير = طبقة قراءة فقط (Read-Only) فوق كل البيانات المتراكمة.
لا تكتب في قاعدة البيانات — فقط تجمع وتفلتر وتعرض.

---

## التقارير الستة

### P9-01: تقرير المبيعات
**المصدر:** `sales` + `sale_items` + `customers`
**الفلاتر:** تاريخ من/إلى (إلزامي) + عميل (اختياري) + الحالة (confirmed/reversed)
**المحتوى:**
```
إجمالي المبيعات | إجمالي المحصَّل | إجمالي الآجل
جدول: رقم الفاتورة | التاريخ | العميل | الإجمالي | المدفوع | المتبقي | الحالة
```

### P9-02: تقرير التحصيلات
**المصدر:** `customer_payments` + `customers`
**الفلاتر:** تاريخ من/إلى + عميل
**المحتوى:**
```
إجمالي المحصَّل في الفترة
جدول: التاريخ | العميل | المبلغ | ربط بفاتورة | ملاحظة
```

### P9-03: تقرير العملاء (كشف الحساب الموحَّد)
**المصدر:** `customers` + `customer_ledger_entries`
**الفلاتر:** عميل محدد + تاريخ من/إلى
**المحتوى:**
```
رصيد افتتاحي في بداية الفترة
جدول: التاريخ | نوع العملية | مدين | دائن | الرصيد بعدها
رصيد ختامي في نهاية الفترة
```
**قائمة إجمالية:** كل العملاء + رصيدهم الحالي + إجمالي الديون

### P9-04: تقرير الموردين (نفس P9-03 بالضبط للموردين)

### P9-05: تقرير المخزون
**المصدر:** `inventory_movements` + `products`
**الفلاتر:** منتج محدد + نوع الحركة + تاريخ من/إلى
**المحتوى:**
```
جدول حركات المخزون: التاريخ | المنتج | نوع الحركة | الكمية | الرصيد بعدها
ملخص: قائمة المنتجات + الكمية الحالية + تنبيه مخزون منخفض
```

### P9-06: تقرير الخزينة
**المصدر:** `cashbox_transactions` + `expenses`
**الفلاتر:** تاريخ من/إلى + نوع العملية
**المحتوى:**
```
رصيد الخزينة في بداية الفترة
إجمالي الوارد | إجمالي الصادر | الرصيد الختامي
جدول: التاريخ | نوع العملية | وارد | صادر | الرصيد
```

---

## المعمارية المشتركة للتقارير

### ReportRepository المشترك:
```dart
abstract interface class ReportRepository {
  // P9-01
  Future<Result<SalesReport>> getSalesReport({required DateTimeRange range, int? customerId});
  // P9-02
  Future<Result<CollectionsReport>> getCollectionsReport({required DateTimeRange range, int? customerId});
  // P9-03
  Future<Result<CustomerAccountReport>> getCustomerReport({required int customerId, required DateTimeRange range});
  Future<Result<List<CustomerBalanceSummary>>> getAllCustomerBalances();
  // P9-04
  Future<Result<SupplierAccountReport>> getSupplierReport({required int supplierId, required DateTimeRange range});
  Future<Result<List<SupplierBalanceSummary>>> getAllSupplierBalances();
  // P9-05
  Future<Result<InventoryReport>> getInventoryReport({int? productId, String? movementType, DateTimeRange? range});
  // P9-06
  Future<Result<CashboxReport>> getCashboxReport({required DateTimeRange range});
}
```

### نمط الـUI المشترك لكل تقرير:
```
[شريط الفلاتر] ← DateRangePicker + dropdowns
[بطاقات KPI] ← ملخص أرقام كبير وواضح
[جدول البيانات] ← DataTable قابل للفرز
[زر طباعة] ← يُمرر البيانات لـ TASK_K
```

---

## الملفات المطلوبة

```
lib/features/reports/domain/entities/sales_report.dart
lib/features/reports/domain/entities/collections_report.dart
lib/features/reports/domain/entities/customer_account_report.dart
lib/features/reports/domain/entities/supplier_account_report.dart
lib/features/reports/domain/entities/inventory_report.dart
lib/features/reports/domain/entities/cashbox_report.dart
lib/features/reports/domain/repositories/report_repository.dart
lib/features/reports/domain/usecases/get_sales_report_usecase.dart
lib/features/reports/domain/usecases/get_collections_report_usecase.dart
lib/features/reports/domain/usecases/get_customer_report_usecase.dart
lib/features/reports/domain/usecases/get_supplier_report_usecase.dart
lib/features/reports/domain/usecases/get_inventory_report_usecase.dart
lib/features/reports/domain/usecases/get_cashbox_report_usecase.dart
lib/features/reports/data/daos/reports_dao.dart
lib/features/reports/data/repositories/report_repository_impl.dart
lib/features/reports/presentation/cubit/reports_cubit.dart
lib/features/reports/presentation/cubit/reports_state.dart
lib/features/reports/presentation/pages/reports_page.dart      # صفحة اختيار نوع التقرير
lib/features/reports/presentation/pages/sales_report_page.dart
lib/features/reports/presentation/pages/collections_report_page.dart
lib/features/reports/presentation/pages/customer_report_page.dart
lib/features/reports/presentation/pages/supplier_report_page.dart
lib/features/reports/presentation/pages/inventory_report_page.dart
lib/features/reports/presentation/pages/cashbox_report_page.dart
lib/features/reports/presentation/widgets/report_filter_bar.dart
lib/features/reports/presentation/widgets/kpi_cards_row.dart
lib/features/reports/presentation/widgets/sortable_data_table.dart
```

---

## الملفات المشتركة التي تُعدَّل

**`injector.dart`:** أضف ReportsDao + ReportRepository + كل 6 UseCases

**`app_database.dart`:** أضف `ReportsDao` في قائمة `daos`

**`app_router.dart`:**
```dart
GoRoute(path: '/reports', builder: (_, __) => const ReportsPage()),
GoRoute(path: '/reports/sales', builder: (_, __) => const SalesReportPage()),
GoRoute(path: '/reports/collections', builder: (_, __) => const CollectionsReportPage()),
GoRoute(path: '/reports/customers', builder: (_, __) => const CustomerReportPage()),
GoRoute(path: '/reports/suppliers', builder: (_, __) => const SupplierReportPage()),
GoRoute(path: '/reports/inventory', builder: (_, __) => const InventoryReportPage()),
GoRoute(path: '/reports/cashbox', builder: (_, __) => const CashboxReportPage()),
```

**بعد التعديل:** `dart run build_runner build --delete-conflicting-outputs`

---

## نقاط الترابط مع المراحل القادمة

### K (الطباعة) تعتمد على:
- كل Report entities → يجب أن تحتوي على كل البيانات اللازمة للطباعة
- اجعل كل `XxxReport` entity قابلاً للتمرير مباشرة لدالة الطباعة

### J (Dashboard) تعتمد على:
- `getSalesReport(today)` → مبيعات اليوم
- `getCollectionsReport(today)` → تحصيلات اليوم

---

## تعريف الاكتمال (DoD)

- [ ] `flutter analyze` = "No issues found!"
- [ ] `flutter test` = كل الاختبارات ناجحة
- [ ] كل تقرير له صفحة مستقلة مع فلاتر تعمل
- [ ] حسابات الإجماليات صحيحة (اختبارات وحدة)
- [ ] تقرير كشف الحساب يعرض رصيداً متتالياً صحيحاً
- [ ] تقرير المخزون يعرض كل أنواع الحركات
- [ ] كل تقرير لديه زر "طباعة" (placeholder حتى TASK_K)
