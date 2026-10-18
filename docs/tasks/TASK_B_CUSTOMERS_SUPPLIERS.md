# TASK_B — المرحلة 2: العملاء والموردون (P2-01 إلى P2-04)
> هذا الملف هو مهمتك الكاملة. كل ما تحتاجه موجود هنا.

---

## السياق الإلزامي (اقرأ أولاً — إلزامي قبل أي كود)

اقرأ هذه الملفات بالترتيب:
1. `docs/ARCHITECTURE_MASTER.md` — المرجع المعماري الكامل
2. `docs/AGENT_RULES.md` — قواعد السلوك والقرارات المقفولة
3. `docs/DART_RULES.md` — معايير الكود
4. `docs/FLUTTER_RULES.md` — معايير الـUI والـCubit
5. `lib/features/products/` — **الكود المرجعي للنمط المعتمد** (اقرأه بالكامل)

---

## فهم دورك في النظام الكامل

أنت تبني الحجر الأساسي الذي **يعتمد عليه نصف النظام**:
- المبيعات (P4) لن تعمل بدون العملاء
- المشتريات (P5) لن تعمل بدون الموردين
- الأرصدة الافتتاحية (P3) تكتب في جداول الـLedger التي تبنيها أنت
- التقارير (P9) تجمع بيانات كشف الحساب الذي تبنيه أنت
- الـDashboard (P10) يعرض إجمالي ديون العملاء ومستحقات الموردين من `currentBalance`

لذلك **التصميم الصحيح هنا = النجاح لاحقاً**.

---

## ما هو موجود بالفعل (لا تُعيد بناءه)

### الجداول (كلها مُعرَّفة ومُولَّدة في الـDB):
```
lib/core/database/tables/stakeholders_tables.dart
```
تحتوي على: `Customers`, `Suppliers`, `CustomerLedgerEntries`, `SupplierLedgerEntries`

بنية جدول Customers/Suppliers:
```dart
id | name | phone? | address? | notes? | currentBalance (int, قرش) | isActive | createdAt | createdBy
```

بنية CustomerLedgerEntries / SupplierLedgerEntries:
```dart
id | customerId/supplierId (FK) | entryType | amount (int, قرش، دائماً موجب)
   | effect (increase/decrease) | balanceAfter (int) | referenceType? | referenceId? | note? | createdAt | createdBy
```

### Core utilities جاهزة للاستخدام:
```dart
import 'package:sales_manager/core/money/money.dart';        // Money class
import 'package:sales_manager/core/result/result.dart';       // Result<T>
import 'package:sales_manager/core/result/failures.dart';     // Failure types
import 'package:sales_manager/core/strings/app_strings.dart'; // كل النصوص
import 'package:sales_manager/core/widgets/states/loading_view.dart';
import 'package:sales_manager/core/widgets/states/empty_view.dart';
import 'package:sales_manager/core/widgets/states/error_view.dart';
```

---

## مهامك المطلوبة (P2-01 إلى P2-04)

### P2-01: كيان العميل + Repository + CRUD

**الملفات المطلوبة:**

```
lib/features/customers/domain/entities/customer.dart
lib/features/customers/domain/repositories/customer_repository.dart
lib/features/customers/domain/usecases/add_customer_usecase.dart
lib/features/customers/domain/usecases/update_customer_usecase.dart
lib/features/customers/domain/usecases/get_customers_usecase.dart
lib/features/customers/domain/usecases/watch_customers_usecase.dart
lib/features/customers/domain/usecases/toggle_customer_status_usecase.dart
lib/features/customers/data/daos/customers_dao.dart
lib/features/customers/data/models/customer_mapper.dart
lib/features/customers/data/repositories/customer_repository_impl.dart
lib/features/customers/presentation/cubit/customers_cubit.dart
lib/features/customers/presentation/cubit/customers_state.dart
lib/features/customers/presentation/pages/customers_page.dart
lib/features/customers/presentation/widgets/customer_form_dialog.dart
```

**Customer Entity (Domain — Dart نقي 100%):**
```dart
class Customer extends Equatable {
  final int id;
  final String name;
  final String? phone;
  final String? address;
  final String? notes;
  final Money currentBalance; // int قرش — Cache من الـLedger
  final bool isActive;
  final DateTime createdAt;
  final String createdBy;
  
  // computed helpers:
  bool get hasDebt => currentBalance.piastres > 0;
  bool get isCreditor => currentBalance.piastres < 0; // دفع أكثر مما عليه
}
```

**CustomerRepository Interface:**
```dart
abstract interface class CustomerRepository {
  Future<Result<List<Customer>>> getCustomers({String? query, bool? isActiveOnly});
  Stream<List<Customer>> watchCustomers({String? query, bool? isActiveOnly});
  Future<Result<Customer>> getCustomerById(int id);
  Future<Result<Customer>> addCustomer({required String name, String? phone, String? address, String? notes});
  Future<Result<Customer>> updateCustomer(Customer customer);
  Future<Result<void>> toggleCustomerStatus(int id, bool isActive);
  // هذه ستُستخدم في P3 وP4 وP6 — أضفها كـinterface الآن حتى لو التنفيذ لاحقاً:
  Stream<List<CustomerLedgerEntry>> watchCustomerLedger(int customerId); // CustomerLedgerEntry من Drift
  Future<Result<List<CustomerLedgerEntry>>> getCustomerLedger(int customerId);
}
```

**CustomerRepositoryImpl — النمط المعتمد (مثل ProductRepositoryImpl تماماً):**
- `addCustomer` → Transaction: insert Customers + insert AuditLog
- `updateCustomer` → Transaction: update Customers + insert AuditLog (payloadBefore + payloadAfter)
- `toggleCustomerStatus` → Transaction: update isActive + insert AuditLog
- `watchCustomerLedger` → Stream مباشر من `customerLedgerEntries` بدون Transaction
- `getCustomerLedger` → Future من `customerLedgerEntries`

**مهم: `currentBalance` لا يُعدَّل مباشرة هنا.** يُعدَّل فقط عند البيع/التحصيل/المرتجع/الرصيد الافتتاحي — داخل Transaction تلك العملية.

---

### P2-02: شاشة قائمة العملاء + كشف الحساب

**CustomersPage:**
- نفس هيكل `ProductsPage` بالضبط (بحث + فلتر + قائمة)
- بطاقة العميل تعرض: الاسم، الهاتف، **الرصيد الحالي بالجنيه** (Money.format)
- لون الرصيد: أحمر إن كان > 0 (عليه دين)، أخضر إن كان 0، برتقالي إن كان سالب
- زر "عرض الحساب" يفتح `CustomerLedgerDialog` أو ينتقل لصفحة كشف الحساب

**CustomerLedgerPage (أو Dialog):**
```
كشف حساب: [اسم العميل]
الرصيد الحالي: X.XX جنيه

جدول:
التاريخ | نوع العملية | مدين (يزيد الدين) | دائن (يقلل الدين) | الرصيد بعدها
```

منطق العمود مدين/دائن:
- `effect = increase` → عمود "مدين" (زاد ما عليه)
- `effect = decrease` → عمود "دائن" (قلّ ما عليه)

هذا التحويل يتم في طبقة العرض فقط — في قاعدة البيانات يُخزَّن `effect: increase/decrease` فقط.

---

### P2-03: كيان المورد + Repository + CRUD

**نفس P2-01 تماماً** مع التغييرات:
- `Supplier` بدلاً من `Customer`
- `SupplierRepository` / `SupplierRepositoryImpl`
- `supplier_id` بدلاً من `customer_id`
- entryType في الـLedger: `purchase, payment, return, opening_balance, reversal`
- في كشف حساب المورد: "مدين" = ما يجب دفعه للمورد، "دائن" = ما دُفع له

---

### P2-04: شاشة قائمة الموردين + كشف الحساب

نفس P2-02 تماماً.

---

## الملفات التي يجب تعديلها في النظام المشترك

### 1. إضافة DAOs للـDatabase (`lib/core/database/app_database.dart`)

```dart
// في قسم daos:
@DriftDatabase(
  tables: [...], // لا تُعدّل قائمة الجداول — كلها موجودة
  daos: [
    ProductsDao,
    InventoryMovementsDao,
    CustomersDao,    // ← أضف هذا
    SuppliersDao,    // ← أضف هذا
  ],
)
```

### 2. تسجيل في DI (`lib/core/di/injector.dart`)

أضف بنفس نمط Products (في نفس الملف، نفس الأسلوب):
```dart
// DAOs
getIt.registerLazySingleton<CustomersDao>(() => CustomersDao(getIt<AppDatabase>()));
getIt.registerLazySingleton<SuppliersDao>(() => SuppliersDao(getIt<AppDatabase>()));

// Repositories  
getIt.registerLazySingleton<CustomerRepository>(() => CustomerRepositoryImpl(db: getIt(), dao: getIt()));
getIt.registerLazySingleton<SupplierRepository>(() => SupplierRepositoryImpl(db: getIt(), dao: getIt()));

// UseCases
getIt.registerLazySingleton<GetCustomersUseCase>(() => GetCustomersUseCase(getIt()));
getIt.registerLazySingleton<WatchCustomersUseCase>(() => WatchCustomersUseCase(getIt()));
getIt.registerLazySingleton<AddCustomerUseCase>(() => AddCustomerUseCase(getIt()));
getIt.registerLazySingleton<UpdateCustomerUseCase>(() => UpdateCustomerUseCase(getIt()));
getIt.registerLazySingleton<ToggleCustomerStatusUseCase>(() => ToggleCustomerStatusUseCase(getIt()));
// نفس الشيء للـSupplier
```

### 3. وصل المسارات (`lib/app/router/app_router.dart`)

المسارات موجودة كـPlaceholder، استبدل المحتوى:
```dart
GoRoute(
  path: '/customers',
  builder: (context, state) => const CustomersPage(), // استبدل الـScaffold الـFakeة
),
GoRoute(
  path: '/suppliers',
  builder: (context, state) => const SuppliersPage(),
),
```

---

## بعد كتابة الـDAOs — شغّل هذا الأمر إلزامياً

```bash
dart run build_runner build --delete-conflicting-outputs
```

هذا يُولّد `customers_dao.g.dart` و`suppliers_dao.g.dart` — بدونه لن يُترجم المشروع.

---

## قواعد لا تُكسر

1. **`domain/`** = Dart نقي — ممنوع import `package:drift` أو `package:flutter`
2. **`currentBalance`** = `int` بالقرش — ممنوع `double` نهائياً
3. **AuditLog** في كل Transaction تُعدّل بيانات
4. **4 حالات UI إلزامية**: Loading / Empty / Error / Loaded
5. **`context.mounted`** بعد كل `await` في الـWidget
6. **`dispose()`** لكل `TextEditingController` و`FocusNode` و`StreamSubscription`
7. **لا حذف فعلي** — `isActive = false` فقط

---

## الاختبارات المطلوبة

```
test/features/customers/data/repositories/customer_repository_impl_test.dart
test/features/customers/domain/usecases/add_customer_usecase_test.dart
test/features/customers/presentation/cubit/customers_cubit_test.dart
test/features/suppliers/data/repositories/supplier_repository_impl_test.dart
test/features/suppliers/domain/usecases/add_supplier_usecase_test.dart
test/features/suppliers/presentation/cubit/suppliers_cubit_test.dart
```

ارجع لـ `test/features/products/` كمرجع للنمط.

---

## نقاط الترابط الحرجة مع المراحل القادمة

هذه العقود **يجب أن تبنيها صح الآن** لأن المراحل التالية تعتمد عليها:

### يستخدمها P3 (الأرصدة الافتتاحية):
- `CustomerRepository.getCustomers()` — لجلب قائمة العملاء
- `SupplierRepository.getSuppliers()` — لجلب قائمة الموردين
- جداول `customer_ledger_entries` و`supplier_ledger_entries` — ستُكتب فيها

### يستخدمها P4 (المبيعات):
- `CustomerRepository.watchCustomers()` — لاختيار العميل في فاتورة البيع
- `CustomerRepository.getCustomerById(id)` — للتحقق من وجود العميل
- `customers.currentBalance` — يُحدَّث داخل Transaction البيع

### يستخدمها P6 (التحصيلات):
- `CustomerRepository.watchCustomerLedger(customerId)` — لاختيار الفاتورة المرتبطة

### يستخدمها P9 (التقارير):
- `customers.currentBalance` aggregated — إجمالي الذمم
- `CustomerLedgerEntries` filtered by date range

### يستخدمها P10 (Dashboard):
- Stream على `customers.currentBalance` — بث فوري لإجمالي الديون

---

## تعريف الاكتمال (DoD)

- [ ] `flutter analyze` = "No issues found!"
- [ ] `flutter test` = كل الاختبارات ناجحة (القديمة + الجديدة)
- [ ] `/customers` و`/suppliers` تعملان فعلياً في الـApp
- [ ] شاشة كشف الحساب تعرض البيانات بشكل صحيح (حتى لو فارغة حالياً)
- [ ] `CustomersDao` و`SuppliersDao` مُسجَّلان في `app_database.dart` و`injector.dart`
- [ ] `build_runner` شُغِّل بنجاح

---

## عند الانتهاء

أبلغ المستخدم بالملفات المُنشأة والمُعدَّلة، وتأكد:
- عدد الاختبارات الجديدة التي تمر
- نتيجة `flutter analyze`
