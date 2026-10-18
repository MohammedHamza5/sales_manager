# TASK_J — المرحلة 10: لوحة التحكم Dashboard (P10-01 + P10-02)
> تعتمد على: TASK_I (التقارير) — الأخيرة من سلسلة البيانات

---

## السياق الإلزامي

اقرأ بالترتيب:
1. `docs/ARCHITECTURE_MASTER.md` — §10 (Dashboard)
2. `docs/AGENT_RULES.md`
3. `docs/FLUTTER_RULES.md`
4. `lib/features/reports/` — ستستخدم UseCases التقارير مباشرة

---

## دورك في النظام الكامل

الـDashboard = **الشاشة الرئيسية عند فتح التطبيق** — عرض حيّ ومباشر لحالة المنشأة.
يستخدم **Drift Streams** فقط — كل تغيير في البيانات = تحديث فوري للـDashboard بدون زر تحديث.

---

## P10-01: استعلامات التجميع (Streams)

### DashboardRepository:
```dart
abstract interface class DashboardRepository {
  // رصيد الخزينة الحالي
  Stream<Money> watchCashboxBalance();

  // إحصاءات اليوم
  Stream<DailyStats> watchTodayStats();

  // إجمالي ديون العملاء
  Stream<Money> watchTotalCustomerDebt();

  // إجمالي مستحقات الموردين
  Stream<Money> watchTotalSupplierPayables();

  // تنبيهات المخزون المنخفض
  Stream<List<Product>> watchLowStockAlerts();

  // آخر 10 عمليات
  Stream<List<RecentActivity>> watchRecentActivities();
}
```

### DailyStats entity:
```dart
class DailyStats {
  final Money todaySales;         // من sales اليوم
  final Money todayCollections;   // من customer_payments اليوم
  final Money todayPurchases;     // من purchases اليوم
  final Money todayExpenses;      // من expenses اليوم
  final int todaySalesCount;
  final int todayCollectionsCount;
}
```

### RecentActivity entity:
```dart
class RecentActivity {
  final String type;        // 'sale' | 'purchase' | 'payment' | 'expense' | 'return'
  final String description; // "بيع لـ [اسم العميل]"
  final Money amount;
  final DateTime time;
}
```

---

## P10-02: واجهة Dashboard

### التخطيط (Layout):

```
Row:
  [بطاقة الخزينة]     [إجمالي الديون]     [إجمالي المستحقات]
  
Row:
  [مبيعات اليوم]      [تحصيلات اليوم]    [مشتريات اليوم]    [مصروفات اليوم]

Row:
  [تنبيهات المخزون المنخفض]     [آخر العمليات]
```

### تفاصيل كل بطاقة:

**بطاقة الخزينة:**
- رقم كبير = الرصيد الحالي
- Stream مباشر = يتحدث فوراً عند أي عملية
- لون أخضر إذا > 0، أحمر إذا = 0

**بطاقات اليوم (4 بطاقات):**
- كل بطاقة: العدد + الإجمالي بالجنيه
- أيقونة + لون مميز لكل نوع
- Stream يُحدَّث عند إضافة أي عملية

**تنبيهات المخزون المنخفض:**
- قائمة المنتجات التي `isLowStock == true`
- عرض: اسم المنتج + الكمية الحالية + الحد الأدنى
- عند الضغط: انتقل لصفحة المنتج

**آخر العمليات:**
- ListView من `watchRecentActivities()` — آخر 10 عمليات
- لكل عملية: أيقونة النوع + الوصف + المبلغ + الوقت
- عند الضغط: انتقل للعملية المرتبطة

---

## الملفات المطلوبة

```
lib/features/dashboard/domain/entities/daily_stats.dart
lib/features/dashboard/domain/entities/recent_activity.dart
lib/features/dashboard/domain/repositories/dashboard_repository.dart
lib/features/dashboard/domain/usecases/watch_dashboard_data_usecase.dart
lib/features/dashboard/data/daos/dashboard_dao.dart
lib/features/dashboard/data/repositories/dashboard_repository_impl.dart
lib/features/dashboard/presentation/cubit/dashboard_cubit.dart
lib/features/dashboard/presentation/cubit/dashboard_state.dart
lib/features/dashboard/presentation/pages/dashboard_page.dart
lib/features/dashboard/presentation/widgets/cashbox_balance_card.dart
lib/features/dashboard/presentation/widgets/daily_stats_row.dart
lib/features/dashboard/presentation/widgets/low_stock_alerts.dart
lib/features/dashboard/presentation/widgets/recent_activities_list.dart
lib/features/dashboard/presentation/widgets/stat_card.dart
```

---

## الملفات المشتركة التي تُعدَّل

**`injector.dart`:** أضف DashboardDao + DashboardRepository + WatchDashboardDataUseCase

**`app_database.dart`:** أضف `DashboardDao` في قائمة `daos`

**`app_router.dart`:** شاشة `/` = `DashboardPage()` (بدلاً من Scaffold placeholder)

**بعد التعديل:** `dart run build_runner build --delete-conflicting-outputs`

---

## تنفيذ Streams في DashboardRepositoryImpl

```dart
// مثال: watchTodayStats()
@override
Stream<DailyStats> watchTodayStats() {
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  // نجمع عدة streams ونحوّل كل تغيير لـDailyStats جديد
  return Rx.combineLatest4(
    _watchTodaySales(startOfDay, endOfDay),
    _watchTodayCollections(startOfDay, endOfDay),
    _watchTodayPurchases(startOfDay, endOfDay),
    _watchTodayExpenses(startOfDay, endOfDay),
    (sales, collections, purchases, expenses) => DailyStats(
      todaySales: sales,
      todayCollections: collections,
      todayPurchases: purchases,
      todayExpenses: expenses,
    ),
  );
}
```

أضف `rxdart: ^0.28.0` لـpubspec.yaml إذا احتجت `Rx.combineLatest4`.
أو استخدم `StreamZip` من dart:async بديلاً.

---

## نقاط الترابط مع المراحل القادمة

### K (النسخ الاحتياطي) تعتمد على:
- لا ترابط مباشر — لكن زر "نسخ احتياطي" يمكن وضعه في قائمة الإعدادات

---

## تعريف الاكتمال (DoD)

- [ ] `flutter analyze` = "No issues found!"
- [ ] `flutter test` = كل الاختبارات ناجحة
- [ ] كل البطاقات تتحدث فورياً بدون إعادة تشغيل (Drift Streams)
- [ ] رصيد الخزينة دقيق ومحدَّث في الوقت الفعلي
- [ ] تنبيهات المخزون المنخفض تظهر فقط للمنتجات التي لها threshold
- [ ] الضغط على أي عنصر ينتقل للصفحة المرتبطة
- [ ] شاشة الـDashboard هي الشاشة الأولى عند فتح التطبيق
