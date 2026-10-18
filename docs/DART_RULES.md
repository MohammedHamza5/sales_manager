# DART_RULES.md — معايير وقواعد كتابة كود Dart وقاعدة البيانات
> الإصدار: 1.0 · نظام إدارة المبيعات والمخزون والحسابات
> المرجع الأعلى: `docs/ARCHITECTURE_MASTER.md` · التزام صارم بـ Clean Architecture

---

## 1. الفصل الطبقي الصارم (Clean Architecture)

```
lib/features/<feature_name>/
  ├── domain/
  │   ├── entities/        # Immutable Domain Models (Freezed or Equatable)
  │   ├── repositories/    # Abstract Interfaces فقط
  │   └── usecases/        # Single Responsibility UseCases (Callable Classes)
  ├── data/
  │   ├── models/          # Drift Mappers & Data Transfer Objects
  │   ├── daos/            # Drift Table Access Objects
  │   └── repositories/    # Concrete Implementation + Transactions
  └── presentation/
      ├── cubit/           # State Management (Cubit + Sealed State)
      └── widgets/         # UI Components & Screens
```

### 1.1 قدسية طبقة الـ Domain
- **Dart نقي 100%:** ممنوع نهائيًا استيراد:
  - `package:flutter/...`
  - `package:drift/...`
  - `package:path_provider/...`
- الـ Domain يحتوي فقط على المنطق الحسابي والتحقق التجاري والعقود (Entities, Repository Interfaces, UseCases).
- أي استيراد لـ Flutter أو Drift داخل `domain/` يعتبر خطأ جسيمًا يُبطل المراجعة.

---

## 2. القواعد المالية والحسابية (Money & Numbers)

### 2.1 المبالغ المالية (Money)
- **ممنوع `double` منعًا باتًا لأي مبلغ مالي.**
- جميع المبالغ تُخزن وتُحسب كـ **`int`** بوحدة **القرش** (1 جنيه مصري = 100 قرش).
- مثال:
  - 150.50 ج.م تُخزن كـ `15050`.
  - 5.00 ج.م تُخزن كـ `500`.
- التحويل والتنسيق للعرض في الـUI يتم فقط عبر فئة مساعدة موحدة: `MoneyFormatter` أو `core/money/money.dart`.
- العمليات الحسابية (الجمع، الطرح، ضرب الكمية في السعر) تتم بدقة الأعداد الصحيحة.

### 2.2 الكميات (Quantities)
- **ممنوع `double` للكميات المخزنية.**
- تُستخدم حزمة **`decimal`** (`package:decimal`) لتمثيل الكميات الكسرية (مثل 1.250 كجم، 0.5 لتر).
- تُخزن في SQLite كنص `TEXT` عبر `DecimalConverter` المخصص في Drift لمنع أي فقد في الدقة الكسرية.

---

## 3. التعامل مع قاعدة البيانات (Drift & SQLite)

### 3.1 المعاملات الذرية (Transactions)
- أي عملية تمس أكثر من جدول واحد **يجب** أن تُنفذ داخل:
  ```dart
  await db.transaction(() async {
    // 1. تحديث أو إدراج في الجدول الأول
    // 2. تحديث حركة المخزون
    // 3. تحديث كشف الحساب
    // 4. تحديث الخزينة
    // 5. كتابة سجل التتبع (Audit Log)
  });
  ```
- فشل أي خطوة يرمي استثناءً يؤدي تلقائيًا إلى Rollback كامل، ولا يُترك النظام في حالة جزئية أبدًا.

### 3.2 سلامة الأرصدة التراكمية (Cached Balances)
- الحقول المشتقة مثل `products.current_quantity` و `customers.current_balance` و `cashbox.current_balance`:
  - **ممنوع تحديثها مباشرة أو عشوائيًا.**
  - لا يتم تعديلها إلا داخل نفس المعاملة (Transaction) التي تُدرج صفًا جديدًا في السجل المقابل (`inventory_movements`, `customer_ledger_entries`, `cashbox_transactions`).
  - هذا يضمن التطابق التام دائمًا بين رصيد الكيان ومجموع حركاته.

### 3.3 حظر الحذف والعمليات بأثر رجعي
- لا يتم تنفيذ `DELETE FROM` على المنتجات أو العملاء أو الموردين. يُستخدم حقل `is_active = false`.
- لا يتم تعديل أو حذف فواتير المبيعات أو المشتريات القديمة.
- لإلغاء فاتورة: تُنشأ عملية "عكس" (`reversal`) جديدة بنفس القيم ومعكوسة الإشارة، مع بقاء الفاتورة الأصلية موسومة كـ `reversed`.

---

## 4. معالجة الأخطاء والنتائج (Result & Failure Pattern)

- جميع الـ UseCases والـ Repositories ترجع نمط `Result<T>` مغلق (Sealed Class):
  ```dart
  sealed class Result<T> {
    const Result();
  }
  class Success<T> extends Result<T> {
    final T data;
    const Success(this.data);
  }
  class Failure<T> extends Result<T> {
    final AppFailure failure;
    const Failure(this.failure);
  }
  ```
- **ممنوع رمي Unhandled Exceptions إلى طبقة الـ UI.**
- أخطاء قاعدة البيانات وحالات عدم كفاية المخزون تُحول إلى كائنات `AppFailure` صريحة ومفهومة.

---

## 5. قواعد الأسلوب والتسميات (Dart Style Guide)

- الملفات: `snake_case.dart`.
- الكلاسات والـ Enums: `PascalCase`.
- المتغيرات والدوال: `camelCase`.
- الثوابت: `lowerCamelCase` أو `SCREAMING_SNAKE_CASE` للقيم الثابتة العالمية.
- الكلاسات غير القابلة للتعديل تحمل `@immutable` مع `final fields` و `const constructors` أينما أمكن.
- تجنب الأسماء الغامضة مثل `Helper` أو `Manager` دون غرض محدد.
