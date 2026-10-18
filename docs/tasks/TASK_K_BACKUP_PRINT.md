# TASK_K — المرحلة 12: النسخ الاحتياطي + الطباعة + سجل التتبع (P12-01 إلى P12-04)
> تعمل بشكل شبه مستقل — تعتمد على P0-02 فقط للـBackup، وعلى P4/P5/I للطباعة

---

## السياق الإلزامي

اقرأ بالترتيب:
1. `docs/ARCHITECTURE_MASTER.md` — §11 (النسخ الاحتياطي) و§12 (AuditLog) و§7.14
2. `docs/AGENT_RULES.md` — البند 8 (الطباعة: حرارية 80mm + A4 محسومة في V1)
3. `docs/DART_RULES.md` + `docs/FLUTTER_RULES.md`

---

## دورك في النظام الكامل

هذه المهمة تُكمل ثلاثة عناصر بنية تحتية:
1. **النسخ الاحتياطي** = حماية البيانات
2. **الطباعة** = مخرجات قابلة للتسليم للعميل
3. **سجل التتبع** = الشفافية الكاملة

---

## P12-01 + P12-02 + P12-03: النسخ الاحتياطي

### BackupService:
```dart
class BackupService {
  // نسخ يدوي: المستخدم يختار المجلد
  Future<Result<String>> createManualBackup() async {
    // 1. file_picker: اختر مجلد الحفظ
    // 2. سمّ الملف: backup_YYYYMMDD_HHmm.sqlite
    // 3. انسخ ملف DB من getApplicationSupportDirectory()
    // 4. أدرج في backups_meta
    // 5. أعد مسار النسخة
  }

  // نسخ تلقائي: يُستدعى عند إغلاق التطبيق أو أول تشغيل يومي
  Future<Result<void>> createAutoBackup() async {
    // 1. إنشاء مجلد backups داخل مجلد التطبيق
    // 2. نسخ الملف باسم auto_backup_YYYYMMDD.sqlite
    // 3. تطبيق سياسة الاحتفاظ: حذف النسخ الأقدم من آخر 7 نسخ تلقائية
    // 4. أدرج في backups_meta
  }

  // استعادة
  Future<Result<void>> restoreBackup(String backupFilePath) async {
    // 1. تحقق من schema_version في backups_meta
    // 2. أخذ نسخة أمان من القاعدة الحالية أولاً
    // 3. أغلق اتصال الـDB (db.close())
    // 4. استبدل ملف الـDB بملف النسخة
    // 5. أعد تشغيل التطبيق (exitCode أو Platform restart)
  }
}
```

### BackupRestorePage:
```
[قسم النسخ اليدوي]:
  زر "إنشاء نسخة احتياطية" ← يختار المجلد ويحفظ
  زر "تصدير لـUSB" ← نفس آلية النسخ اليدوي

[قسم النسخ التلقائي]:
  Toggle: تفعيل/تعطيل النسخ التلقائي
  عدد النسخ المحتفظ بها: Slider (1-30)

[قسم الاستعادة]:
  زر "اختيار ملف نسخة" ← file_picker
  تحذير واضح: "سيُستبدل قاعدة البيانات الحالية"
  زر "استعادة" ← بعد تأكيد المستخدم

[سجل النسخ]:
  جدول من backups_meta: التاريخ | النوع | الحجم | المسار
```

---

## P12-04: سجل التتبع (AuditLog Viewer)

### AuditLogPage:
```
[فلاتر]:
  نوع الكيان: product | customer | supplier | sale | purchase | payment | expense | return | adjustment | system
  الإجراء: create | update | cancel | reverse | activate | deactivate
  تاريخ من/إلى

[جدول]:
  التاريخ | نوع الكيان | الإجراء | التفاصيل (payload_after ملخص)
  
[عند الضغط على صف]:
  Dialog يعرض: payload_before vs payload_after كاملاً
```

**AuditLogRepository:**
```dart
abstract interface class AuditLogRepository {
  Future<Result<List<AuditLogEntry>>> getAuditLog({
    String? entityType,
    String? action,
    DateTime? from,
    DateTime? to,
    int limit = 100,
  });
  Stream<List<AuditLogEntry>> watchRecentAuditLog({int limit = 50});
}
```

---

## الطباعة (محسومة في V1: حرارية 80mm + A4)

### PrintService:
```dart
class PrintService {
  // فاتورة مبيعات — نسختان:
  Future<void> printSaleReceipt(Sale sale, List<SaleItem> items, String customerName);  // حراري 80mm
  Future<void> printSaleInvoice(Sale sale, List<SaleItem> items, String customerName);   // A4

  // فاتورة مشتريات
  Future<void> printPurchaseInvoice(Purchase purchase, List<PurchaseItem> items, String supplierName);

  // كشف حساب عميل
  Future<void> printCustomerStatement(Customer customer, List<CustomerLedgerEntry> entries);

  // أي تقرير
  Future<void> printReport(String title, List<Map<String, String>> data, List<String> headers);
}
```

**قوالب الطباعة:**

للحراري (80mm) — بسيط ومضغوط:
```
================================
       [اسم المنشأة]
================================
فاتورة رقم: XXX
التاريخ: DD/MM/YYYY
العميل: [الاسم]
--------------------------------
المنتج     الكمية     السعر    الإجمالي
...
--------------------------------
الإجمالي:      X,XXX.XX جنيه
المدفوع:       X,XXX.XX جنيه
المتبقي:       X,XXX.XX جنيه
================================
شكراً لتعاملكم معنا
```

للـA4 — احترافي:
- رأس مع بيانات المنشأة
- جدول أصناف منسق
- ملخص مالي
- توقيع المستلم

---

## الملفات المطلوبة

```
lib/core/backup/backup_service.dart
lib/core/backup/restore_service.dart
lib/core/print/print_service.dart
lib/core/print/templates/thermal_receipt_template.dart
lib/core/print/templates/a4_invoice_template.dart

lib/features/backup_restore/domain/repositories/backup_repository.dart
lib/features/backup_restore/domain/usecases/create_backup_usecase.dart
lib/features/backup_restore/domain/usecases/restore_backup_usecase.dart
lib/features/backup_restore/domain/usecases/list_backups_usecase.dart
lib/features/backup_restore/data/repositories/backup_repository_impl.dart
lib/features/backup_restore/presentation/pages/backup_restore_page.dart

lib/features/audit_log/domain/repositories/audit_log_repository.dart
lib/features/audit_log/domain/usecases/get_audit_log_usecase.dart
lib/features/audit_log/data/daos/audit_log_dao.dart
lib/features/audit_log/data/repositories/audit_log_repository_impl.dart
lib/features/audit_log/presentation/cubit/audit_log_cubit.dart
lib/features/audit_log/presentation/cubit/audit_log_state.dart
lib/features/audit_log/presentation/pages/audit_log_page.dart
```

---

## الملفات المشتركة التي تُعدَّل

**`injector.dart`:** أضف BackupService + PrintService + AuditLogDao + كل UseCases

**`app_database.dart`:** أضف `AuditLogDao` في قائمة `daos`

**`app_router.dart`:**
```dart
GoRoute(path: '/settings/backup', builder: (_, __) => const BackupRestorePage()),
GoRoute(path: '/settings/audit-log', builder: (_, __) => const AuditLogPage()),
```

**`app_router.dart` — NavigationRail:** أضف "الإعدادات" كـ wrapper يحوي: النسخ الاحتياطي + سجل التتبع

**`main.dart`:** في `initState` أو `runApp`: استدع `BackupService.createAutoBackup()` إذا كان آخر نسخة أمس.

**بعد التعديل:** `dart run build_runner build --delete-conflicting-outputs`

---

## نقطة تكامل مع التقارير (TASK_I) والمبيعات (TASK_D):

`PrintService` تُستخدم في:
- `SaleDetailPage` → زر طباعة
- `PurchaseDetailPage` → زر طباعة
- `CustomerReportPage` → زر طباعة كشف الحساب
- `SalesReportPage` → زر طباعة التقرير

يجب أن يكون `PrintService` مُسجَّلاً في `getIt` وقابلاً للحصول عليه من أي شاشة.

---

## تعريف الاكتمال (DoD)

- [x] `flutter analyze` = "No issues found!"
- [x] `flutter test` = كل الاختبارات ناجحة
- [x] النسخ اليدوي يُنشئ ملف .sqlite في المسار المختار
- [x] النسخ التلقائي يعمل + سياسة الاحتفاظ بـ7 نسخ تعمل
- [x] الاستعادة تأخذ نسخة أمان أولاً ثم تستبدل
- [x] الطباعة الحرارية تُنتج PDF/صفحة مناسبة لـ80mm
- [x] الطباعة A4 تُنتج فاتورة احترافية
- [x] سجل التتبع يعرض كل العمليات مع فلاتر تعمل
- [x] ربط أوامر وقوالب الطباعة بشاشات التفاصيل وكشوف الحساب
