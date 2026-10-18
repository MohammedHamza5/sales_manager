# TASK_G — المرحلة 7: الخزينة والمصروفات (P7-01 + P7-02)
> تعتمد على: TASK_F (التحصيلات والمدفوعات)

---

## السياق الإلزامي

اقرأ بالترتيب:
1. `docs/ARCHITECTURE_MASTER.md` — §7.9 (cashbox_transactions) و§9 (الخزينة)
2. `docs/AGENT_RULES.md` — خاصةً البند 7 (المصروفات محسومة ومبنية في V1)
3. `docs/DART_RULES.md` + `docs/FLUTTER_RULES.md`

---

## دورك في النظام الكامل

الخزينة = **سجل شامل لكل حركة نقدية** في المنشأة:
- كل بيع نقدي/جزئي → `sale_cash_in`
- كل تحصيل → `customer_payment_in`
- كل شراء نقدي/جزئي → `purchase_cash_out`
- كل دفع لمورد → `supplier_payment_out`
- كل مصروف → `expense_out`
- الرصيد الافتتاحي → `opening_balance`

الجدول **لا تُكتب فيه مباشرة** من هذه المهمة — بل تُقرأ منه. البيانات تأتي من المراحل السابقة.

---

## ما هو موجود بالفعل

```
// الجداول:
cashbox_transactions (تحتوي كل الحركات من P3+D+E+F)
expenses (جدول المصروفات — جاهز في DB)

// هيكل cashbox_transactions:
id | transaction_type | amount (int, قرش) | direction (in/out) |
   referenceType? | referenceId? | balance_after (int) | note? | created_at
```

---

## P7-01: شاشة الخزينة

### البنية:
```
[بطاقة الرصيد الحالي] ← آخر balance_after في cashbox_transactions
[ملخص اليوم]: إجمالي وارد | إجمالي صادر | صافي اليوم
[شريط فلتر]:
  - الكل
  - وارد فقط (direction = in)
  - صادر فقط (direction = out)
  - فلتر نوع: مبيعات | تحصيلات | مشتريات | مدفوعات موردين | مصروفات
  - فلتر تاريخ: من/إلى
[جدول الحركات]:
  التاريخ | نوع العملية (بالعربي) | وارد (+) | صادر (-) | الرصيد بعدها
```

### CashboxRepository:
```dart
abstract interface class CashboxRepository {
  Stream<List<CashboxTransaction>> watchTransactions({
    String? direction, // 'in' | 'out' | null
    String? type,
    DateTime? from,
    DateTime? to,
  });
  Future<Result<int>> getCurrentBalance(); // آخر balance_after
  Stream<int> watchCurrentBalance();
  Future<Result<CashboxSummary>> getDailySummary(DateTime date);
}
```

### CashboxSummary entity:
```dart
class CashboxSummary {
  final Money totalIn;
  final Money totalOut;
  final Money netAmount; // totalIn - totalOut
  final Money currentBalance;
}
```

---

## P7-02: المصروفات (Expenses — محسومة في V1)

### هيكل جدول expenses (موجود):
```
id | title (نص، اسم المصروف) | amount (int, قرش) |
   expense_date | category (text?) | note? | created_at | created_by
```

### نموذج تسجيل مصروف:
```
[اسم/وصف المصروف] ← TextField (إلزامي)
[المبلغ] ← TextField Money
[التاريخ] ← DatePicker
[الفئة] ← DropDown اختياري: "إيجار | مرتبات | كهرباء | نقل | متنوعات"
[ملاحظة] ← اختياري
```

### تدفق UseCase الذري — Transaction واحدة:
```
1. تحقق: title غير فارغ + amount > 0
2. أدرج expenses row
3. احسب newCashboxBalance = lastCashboxBalance - amount
4. أدرج cashbox_transactions (expense_out, out, balanceAfter = newCashboxBalance)
5. audit_log (entityType = 'expense')
6. Commit أو Rollback
```

### ExpenseRepository:
```dart
abstract interface class ExpenseRepository {
  Future<Result<Expense>> recordExpense({
    required String title,
    required Money amount,
    required DateTime expenseDate,
    String? category,
    String? note,
  });
  Future<Result<List<Expense>>> getExpenses({DateTime? from, DateTime? to, String? category});
  Stream<List<Expense>> watchExpenses({DateTime? from, DateTime? to});
}
```

---

## الملفات المطلوبة

```
lib/features/cashbox/domain/entities/cashbox_transaction_entity.dart
lib/features/cashbox/domain/entities/cashbox_summary.dart
lib/features/cashbox/domain/repositories/cashbox_repository.dart
lib/features/cashbox/domain/usecases/watch_cashbox_transactions_usecase.dart
lib/features/cashbox/domain/usecases/watch_cashbox_balance_usecase.dart
lib/features/cashbox/domain/usecases/get_cashbox_summary_usecase.dart
lib/features/cashbox/data/daos/cashbox_dao.dart
lib/features/cashbox/data/repositories/cashbox_repository_impl.dart
lib/features/cashbox/presentation/cubit/cashbox_cubit.dart
lib/features/cashbox/presentation/cubit/cashbox_state.dart
lib/features/cashbox/presentation/pages/cashbox_page.dart

lib/features/expenses/domain/entities/expense.dart
lib/features/expenses/domain/repositories/expense_repository.dart
lib/features/expenses/domain/usecases/record_expense_usecase.dart
lib/features/expenses/domain/usecases/watch_expenses_usecase.dart
lib/features/expenses/data/daos/expenses_dao.dart
lib/features/expenses/data/repositories/expense_repository_impl.dart
lib/features/expenses/presentation/cubit/expenses_cubit.dart
lib/features/expenses/presentation/cubit/expenses_state.dart
lib/features/expenses/presentation/pages/expenses_page.dart
lib/features/expenses/presentation/widgets/record_expense_dialog.dart
```

---

## الملفات المشتركة التي تُعدَّل

**`injector.dart`:** أضف CashboxDao + ExpensesDao + كل UseCases

**`app_database.dart`:** أضف `CashboxDao` و`ExpensesDao` في قائمة `daos`

**`app_router.dart`:**
```dart
GoRoute(path: '/cashbox', builder: (_, __) => const CashboxPage()),
GoRoute(path: '/expenses', builder: (_, __) => const ExpensesPage()),
```

**`app_router.dart` — MainDesktopShell:** أضف "المصروفات" للـNavigationRail

**بعد التعديل:** `dart run build_runner build --delete-conflicting-outputs`

---

## نقطة تكامل حرجة: balance_after

عند جلب `watchCurrentBalance()` — استخدم:
```dart
// آخر صف في cashbox_transactions مرتباً بـcreated_at تنازلياً
final lastTransaction = await (select(cashboxTransactions)
  ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
  ..limit(1)).getSingleOrNull();
return lastTransaction?.balanceAfter ?? 0;
```

---

## نقاط الترابط مع المراحل القادمة

### I (تقرير الخزينة) تعتمد على:
- `CashboxRepository.watchTransactions()` مع فلاتر التاريخ
- `ExpenseRepository.getExpenses()` مع فلتر فئة

### J (Dashboard) تعتمد على:
- `watchCurrentBalance()` — Stream فوري لرصيد الخزينة
- `getDailySummary(today)` — ملخص اليوم

---

## تعريف الاكتمال (DoD)

- [ ] `flutter analyze` = "No issues found!"
- [ ] `flutter test` = كل الاختبارات ناجحة
- [ ] الرصيد الحالي دقيق = آخر `balance_after` في الجدول
- [ ] الفلاتر (نوع + تاريخ + اتجاه) تعمل
- [ ] تسجيل مصروف: Transaction ذرية (expenses + cashbox + audit)
- [ ] Stream الخزينة يتحدث فورياً عند أي عملية جديدة (Drift Reactivity)
- [ ] `expenses` feature مبنية بالكامل وليست placeholder
