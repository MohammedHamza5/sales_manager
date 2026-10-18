# MASTER_PROJECT_TRACKER.md — لوحة المتابعة الشاملة للنظام وتنسيق المهام
> **المشروع:** Sales Manager — نظام إدارة المبيعات والمخزون والحسابات (Offline Windows Desktop)  
> **المرجع المعماري الأعلى:** [ARCHITECTURE_MASTER.md](file:///c:/Users/KimoStore/StudioProjects/sales_manager/docs/ARCHITECTURE_MASTER.md)  
> **ميثاق التطوير:** [AGENT_RULES.md](file:///c:/Users/KimoStore/StudioProjects/sales_manager/docs/AGENT_RULES.md)  
> **تاريخ آخر تحديث وفحص:** 2026-09-25  
> **الحالة الفنية الراهنة:** `flutter analyze` = **0 أخطاء / 0 تحذيرات (No issues found!)** | `flutter test` = **247+ اختبار ناجح (100%)**

---

## 1. بطاقة النبض الفني السريع (System Vital Signs)

| المؤشر | الحالة | القيمة / الملاحظة |
|---|:---:|---|
| **سلامة الكود (Linting)** | 🟢 سليم 100% | `flutter analyze` خالي تماماً من أي issues أو تحذيرات في كامل المشروع |
| **جناح الاختبارات (Unit, Integration & Widget Tests)** | 🟢 247/247 ناجح | كافة اختبارات الـDAOs والـTransactions والـCubits والـWidgets ناجحة بنسبة 100% |
| **قاعدة البيانات (Drift + SQLite)** | 🟢 22 جدولاً | الجداول مولدة بالكامل بـ[AppDatabase](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/core/database/app_database.dart) |
| **القرارات المقفولة 🔒** | 🟢 مطبقة بدقة | دقة الأموال (`int` قرش)، دقة الكميات (`Decimal`)، منع البيع بالسالب، Transactions ذرية |
| **حجم إنجاز النظام الإجمالي** | 🟢 **100%** | كافة المراحل من P0 إلى P13 مكتملة ومختبرة ومربوطة بالـRouter والـDI بنسبة 100% |

---

## 2. مصفوفة تتبع المراحل والوحدات (Master Phases Matrix)

| المرحلة | الوصف والمعمارية | نسبة الإنجاز | حالة الاختبارات | الملفات المرجعية | الخطوة التالية |
|---|---|:---:|:---:|---|---|
| **P0: الأساس المعماري** | Drift DB, DI (get_it), GoRouter, Theme, Money/Quantity, Result/Failure | **100%** 🟢 | مغطاة بالكامل | [injector.dart](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/core/di/injector.dart)<br>[app_database.dart](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/core/database/app_database.dart) | مستقرة |
| **P1: المنتجات والمخزون** | CRUD منتجات + حركات المخزون + تسويات المخزون (سبب إلزامي) | **100%** 🟢 | 17 اختباراً ناجحاً | [products](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/features/products)<br>[inventory](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/features/inventory) | مستقرة |
| **P2: العملاء والموردون** | العملاء + كشف الحساب (Ledger) + الموردون + كشف حساب المورد | **100%** 🟢 | 45 اختباراً ناجحاً | [customers](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/features/customers)<br>[suppliers](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/features/suppliers) | مستقرة |
| **P3: الأرصدة الافتتاحية** | شاشة الإعداد الأولي بـTransaction ذرية واحدة لكل الأطراف | **100%** 🟢 | 21 اختباراً ناجحاً | [opening_balance](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/features/opening_balance) | مستقرة |
| **P4: المبيعات (Sales)** | فاتورة متعددة الأصناف، منع بيع بالسالب، ترحيل رصيد وخزينة ومخزون وAudit، إلغاء وعكس | **100%** 🟢 | 4 اختبارات تكاملية | [sales](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/features/sales) | مستقرة ومربوطة بالـRouter |
| **P5: المشتريات (Purchases)** | فاتورة شراء متعددة الأصناف، تحديث سعر الشراء، عكس شراء مع فحص المخزون | **100%** 🟢 | 14 اختباراً ناجحاً | [purchases](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/features/purchases) | مستقرة ومربوطة بالـRouter |
| **P6: التحصيلات والمدفوعات** | تحصيل عميل مع ربط بفاتورة + سداد مورد + أثر الخزينة واللدجر ذرياً مع تدقيق كامل | **100%** 🟢 | 18 اختباراً ناجحاً | [customer_payments](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/features/customer_payments)<br>[supplier_payments](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/features/supplier_payments) | مكتملة ومربوطة بالشاشات وكشوف الحسابات والـRouter والـDI |
| **P7: الخزينة والمصروفات** | كشف حركة النقدية اليومي + تسجيل المصروفات وبنودها وخروجها من الخزينة | **100%** 🟢 | 26 اختباراً ناجحاً | [cashbox](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/features/cashbox)<br>[expenses](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/features/expenses) | مستقرة ومربوطة بالـRouter والـDI |
| **P8: المرتجعات (Returns)** | مرتجعات العملاء والموردين وتحديث المخزون واللدجر وAuditLog | **100%** 🟢 | اختبارات تكاملية ناجحة | [returns](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/features/returns) | مستقرة ومربوطة بالـRouter |
| **P9: التقارير السبعة المطورة** | 7 تقارير (مبيعات، تحصيلات، عملاء، موردين، مخزون، خزينة، أرباح وهامش الربح COGS) + أزرار فترات سريعة + تصدير CSV إكسل | **100%** 🟢 | 14 اختباراً ناجحاً (وحدات وتكامل) | [reports](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/features/reports) | مستقرة ومربوطة بالـRouter والـDI |
| **P10: لوحة التحكم (Dashboard)** | شاشة رئيسية عبر Drift Streams لبيانات اليوم، الديون، المستحقات، التنبيهات، وتخطيط متجاوب | **100%** 🟢 | 7 اختبارات ناجحة (Streams & Cubit & Widget) | [dashboard](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/features/dashboard) | مستقرة ومربوطة كالمسار الرئيسي `/` |
| **P11: البحث والفلاتر العامة** | بحث موحد شامل (Command Palette: Ctrl+F / Ctrl+K) واختصارات سريعة وفلاتر متقدمة | **100%** 🟢 | مغطاة بالكامل | [universal_search_dialog.dart](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/core/shortcuts/universal_search_dialog.dart)<br>[app_shortcuts.dart](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/core/shortcuts/app_shortcuts.dart) | مستقرة ومربوطة بالـRouter والشريط الجانبي |
| **P12: النسخ والطباعة والـAudit** | نسخ يدوي وتلقائي + استعادة + سجل تتبع كامل + طباعة A4 وحراري 80mm وكشوف الحساب | **100%** 🟢 | 12 اختباراً ناجحاً | [backup_restore](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/features/backup_restore)<br>[audit_log](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/features/audit_log) | مربوطة بالشاشات والإعدادات والـDI بالكامل |
| **P13: التصليب النهائي وQA** | تدقيق خلو الكود من الأخطاء (No issues found) واجتياز كل الاختبارات ودعم أحجام الشاشات | **100%** 🟢 | 247/247 اختبار ناجح | [TASK_L_FINAL_QA.md](file:///c:/Users/KimoStore/StudioProjects/sales_manager/docs/tasks/TASK_L_FINAL_QA.md) | مستقرة وجاهزة للإنتاج |

---

## 3. خريطة الترابط المعماري وتدفق البيانات (System Integration Map)

```mermaid
graph TD
    Products[المنتجات والمخزون P1] --> Sales[المبيعات P4]
    Products --> Purchases[المشتريات P5]
    Customers[العملاء واللدجر P2] --> Sales
    Suppliers[الموردون واللدجر P2] --> Purchases
    
    Sales --> CustomerPayments[التحصيلات P6]
    Purchases --> SupplierPayments[مدفوعات الموردين P6]
    
    Sales --> Cashbox[الخزينة P7]
    Purchases --> Cashbox
    CustomerPayments --> Cashbox
    SupplierPayments --> Cashbox
    Expenses[المصروفات P7] --> Cashbox
    
    Sales --> Returns[المرتجعات P8]
    Purchases --> Returns
    
    Sales --> Reports[التقارير الشاملة P9]
    Purchases --> Reports
    Cashbox --> Reports
    Customers --> Reports
    Suppliers --> Reports
    Products --> Reports
    
    Reports --> Dashboard[لوحة التحكم P10]
    Cashbox -. Drift Streams .-> Dashboard

    Search[البحث الموحد والاختصارات P11] -. التنقل السريع .-> Dashboard
    Search -. التنقل السريع .-> Sales
    Search -. التنقل السريع .-> Purchases
    Search -. التنقل السريع .-> Products
    Search -. التنقل السريع .-> Customers
    Search -. التنقل السريع .-> Suppliers
    Search -. التنقل السريع .-> Reports
```

---

## 4. قائمة المهام التنفيذية المنجزة (Completed Work Queue)

### 📌 المراحل المنجزة بالكامل بنسبة 100%:

#### 🎯 المهمة رقم 1: التحصيلات ومدفوعات الموردين (Phase 6 - TASK_F) ✅
- [x] إنشاء `CustomerPaymentsDao` و`SupplierPaymentsDao` وتسجيلهما في [AppDatabase](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/core/database/app_database.dart).
- [x] إكمال `CustomerPaymentRepositoryImpl` و`SupplierPaymentRepositoryImpl`.
- [x] بناء UseCases: `RecordCustomerPaymentUseCase`, `RecordSupplierPaymentUseCase`, `WatchCustomerPaymentsUseCase`, `GetAllPaymentsUseCase`.
- [x] بناء شاشات الـUI:
  - `CustomerPaymentsPage` + `RecordCustomerPaymentDialog` (مع إمكانية ربط الفاتورة ومعاينة الرصيد المتبقي).
  - `SupplierPaymentsPage` + `RecordSupplierPaymentDialog`.
- [x] إتاحة استدعاء تسجيل التحصيل والسداد مباشرة من شاشات العملاء والموردين وكشوف الحسابات ([CustomerLedgerDialog](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/features/customers/presentation/widgets/customer_ledger_dialog.dart) و[SupplierLedgerDialog](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/features/suppliers/presentation/widgets/supplier_ledger_dialog.dart)).
- [x] ربط المسارات في [app_router.dart](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/app/router/app_router.dart) وتحديث حقن التبعيات في [injector.dart](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/core/di/injector.dart).
- [x] كتابة واجتياز اختبارات التكامل للـTransactions في الذاكرة `NativeDatabase.memory()`.

#### 🎯 المهمة رقم 2: واجهة الخزينة وإدارة المصروفات (Phase 7 - TASK_G) ✅
- [x] تسجيل `CashboxDao` في [AppDatabase](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/core/database/app_database.dart).
- [x] تسجيل `CashboxRepository` واستخداماته في [injector.dart](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/core/di/injector.dart).
- [x] بناء `CashboxPage` التي تعرض: رصيد اليوم، ملخص الوارد والمنصرف، وجدول الحركات المصفى تفاعلياً.
- [x] بناء ميزة المصروفات (`expenses`): كيان، استخدام، نموذج تسجيل المصروفات بالبند والقيمة، مع خروج فوري من الخزينة وتسجيل AuditLog.
- [x] ربط المسارات في [app_router.dart](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/app/router/app_router.dart).

#### 🎯 المهمة رقم 3: منظومة التقارير الشاملة (Phase 9 - TASK_I) ✅
- [x] بناء طبقة `reports`:
  - تقرير المبيعات (مع فلاتر التاريخ والعميل والحالة).
  - تقرير التحصيلات اليومية والدورية.
  - كشوف حسابات العملاء الموحدة وحصر الديون.
  - كشوف حسابات الموردين وحصر المستحقات.
  - تقرير حركة وتقييم المخزون وتنبيهات النواقص.
  - تقرير الخزينة والأرباح التشغيلية وحساب تكلفة البضاعة المباعة COGS.
- [x] بناء شاشة التقارير مع التصفية السريعة والتصدير لملفات CSV.

#### 🎯 المهمة رقم 4: لوحة التحكم التفاعلية (Phase 10 - TASK_J) ✅
- [x] بناء `DashboardPage` التفاعلية باستخدام Drift Streams الحية:
  - بطاقة الخزينة الفورية.
  - إجمالي ديون العملاء وإجمالي مستحقات الموردين.
  - مبيعات اليوم، تحصيلات اليوم، مشتريات اليوم، مصروفات اليوم.
  - تنبيهات النواقص الحية وجدول الحركات الأخيرة.
- [x] تصميم متجاوب لكروت الإحصائيات (Responsive Stat Cards) لمنع الـOverflows والتوافق مع شاشات الديسكتوب.

#### 🎯 المهمة رقم 5: البحث الشامل واختصارات لوحة المفاتيح (Phase 11) ✅
- [x] بناء نافذة البحث الشامل التفاعلية [UniversalSearchDialog](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/core/shortcuts/universal_search_dialog.dart).
- [x] دعم اختصارات لوحة المفاتيح العالمية:
  - `Ctrl + F` / `Ctrl + K`: البحث الشامل والتنقل السريع.
  - `F1`: دليل الاختصارات الإرشادي.
  - `F2`: فاتورة بيع جديدة فوراً.
  - `F3`: فاتورة شراء جديدة فوراً.
  - `F10` / `Ctrl + Enter`: حفظ وإتمام الفاتورة.
  - `Esc`: إغلاق النوافذ والرجوع.
- [x] إضافة زر البحث الشامل السريع في الشريط الجانبي الرئيسي [app_router.dart](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/app/router/app_router.dart).

#### 🎯 المهمة رقم 6: الطباعة والنسخ الاحتياطي والـAudit Log (Phase 12) ✅
- [x] ربط الطباعة الحرارية (80mm) وطباعة الورق العادي (A4) لفواتير المبيعات والمشتريات.
- [x] دعم طباعة كشوف حسابات العملاء والموردين.
- [x] شاشة الإعدادات المتكاملة: النسخ الاحتياطي التلقائي واليدوي والاستعادة، وسجل التدقيق والعمليات.

#### 🎯 المهمة رقم 7: التصليب النهائي وضمان الجودة (Phase 13 - TASK_L) ✅
- [x] خلو الكود بالكامل من أي أخطاء أو تحذيرات (`flutter analyze`: No issues found!).
- [x] اجتياز 100% من اختبارات النظام (الوحدات، التكامل، واختبارات الـWidgets).
- [x] تدقيق منع البيع بالسالب وحفظ سلامة العمليات المالية الذرية (ACID Transactions).

---

## 5. سجل الحوكمة والقرارات الفنية المعتمدة 🔒

| الرقم | القرار | الوضع | مكان التطبيق والتأثير |
|---|---|:---:|---|
| **1** | منع البيع بالسالب قطعياً | 🔒 مقفول | مُطبَّق في [CreateSaleUseCase](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/features/sales/domain/usecases/create_sale_usecase.dart) و[CreateSalePage](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/features/sales/presentation/pages/create_sale_page.dart) |
| **2** | استخدام القرش `int` للأموال | 🔒 مقفول | ممنوع `double` منعاً باتاً؛ مطبق في كامل كيانات النظام عبر [Money](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/core/money/money.dart) |
| **3** | استخدام `Decimal` للكميات | 🔒 مقفول | مطبق في جميع جداول وحركات المخزون والمبيعات والمشتريات |
| **4** | الذرية عبر Single `db.transaction()` | 🔒 مقفول | مطبق في كل UseCase مركب، فشل أي قيد = تراجع كامل (Rollback) |
| **5** | التسجيل التلقائي في الـAudit Log | 🔒 مقفول | يُكتب السجل داخل نفس الـTransaction مع كل تعديل أو إنشاء |
| **6** | حظر الحذف النهائي (No Hard Delete) | 🔒 مقفول | التعطيل بـ`is_active = false`، والإلغاء بإنشاء حركة عكسية (Reversal) فقط |
| **7** | لغة النظام واتجاهه | 🔒 مقفول | عربي بالكامل RTL عبر نصوص موحدة في [app_strings.dart](file:///c:/Users/KimoStore/StudioProjects/sales_manager/lib/core/strings/app_strings.dart) |
| **8** | نمط إدارة الحالة | 🔒 مقفول | `Cubit` من حزمة `flutter_bloc` حصراً |

---

## 6. ميثاق التشغيل والتسليم (Release Status)

النظام الآن في حالة **جاهزية إنتاجية كاملة (Production-Ready)** لبيئة تشغيل Windows Desktop Offline:
1. **التحليل السليم:** `flutter analyze` = **0 أخطاء / 0 تحذيرات**.
2. **الاختبارات الشاملة:** `flutter test` = **247/247 اختبار ناجح (100%)**.
3. **التكامل بين كافة الأقسام:** المخزون، المبيعات، المشتريات، الخزينة، التحصيلات، السدادات، المصروفات، المرتجعات، التقارير، والنسخ الاحتياطي تعمل معاً في ترابط مالي ومخزني متكامل بنسبة 100%.
4. **التصميم البصري ونظام الثيم المزدوج (Dark/Light):** تم تحويل جميع الشاشات (17 موديول)، النوافذ المنبثقة، الجداول، البطاقات، والرسائل التفاعلية لتعمل بنظام `context.colors` الديناميكي بالكامل لدعم Dark Mode الليموني (#0A0A0A / #CBFA3A) و Light Mode الزيتوني (#FFFFFF / #556F01) بسلاسة لحظية.
