# TASK_F — المرحلة 6: التحصيلات ومدفوعات الموردين (P6-01 + P6-02)
> تعتمد على: TASK_D (المبيعات) + TASK_E (المشتريات)

---

## السياق الإلزامي

اقرأ بالترتيب:
1. `docs/ARCHITECTURE_MASTER.md` — خاصةً §8.3 (تحصيل عميل) و§8.4 (دفع مورد)
2. `docs/AGENT_RULES.md`
3. `docs/DART_RULES.md` + `docs/FLUTTER_RULES.md`
4. `lib/features/sales/` و`lib/features/purchases/` — مرجع الكود

---

## دورك في النظام الكامل

التحصيلات والمدفوعات = نقطة التسوية المالية:
- العميل يدفع → رصيده ينقص + الخزينة ترتفع
- نحن ندفع للمورد → رصيده ينقص + الخزينة تنخفض
- يمكن ربط الدفعة بفاتورة محددة أو تركها عامة
- كلها في **Transaction واحدة**

---

## ما هو موجود بالفعل

```
// الجداول:
customer_payments, supplier_payments
customer_ledger_entries, supplier_ledger_entries
customers (current_balance), suppliers (current_balance)
cashbox_transactions

// من TASK_D: Sale entities + GetSalesUseCase
// من TASK_E: Purchase entities + GetPurchasesUseCase
// من TASK_B: CustomerRepository + SupplierRepository
```

---

## P6-01: تحصيل من عميل

### نموذج التحصيل:
```
[اختيار العميل] ← Dropdown/Search
[الرصيد الحالي للعميل] ← يُعرض تلقائياً (للمعلومية)
[المبلغ المُحصَّل] ← TextField (Money — int قرش)
[تاريخ التحصيل] ← DatePicker
[ربط بفاتورة] ← اختياري: Dropdown يعرض فواتير العميل غير المسددة بالكامل
[ملاحظة] ← TextField اختياري
[Preview الأثر] ← "سيتبقى على العميل X جنيه بعد التحصيل"
```

### تدفق UseCase الذري — Transaction واحدة:
```
1. تحقق: المبلغ > 0
2. تحقق: العميل موجود ونشط
3. احسب newBalance = customer.currentBalance - amount
   (يمكن أن يكون سالباً — دفع أكثر مما عليه، مقبول)
4. أدرج customer_payments (amount, payment_date, linked_sale_id?)
5. أدرج customer_ledger_entries (payment, decrease, balanceAfter = newBalance)
6. حدّث customers.current_balance = newBalance
7. احسب newCashboxBalance = lastCashboxBalance + amount
8. أدرج cashbox_transactions (customer_payment_in, in, balanceAfter = newCashboxBalance)
9. audit_log
10. Commit أو Rollback
```

### CustomerPaymentsRepository interface:
```dart
abstract interface class CustomerPaymentRepository {
  Future<Result<CustomerPayment>> recordPayment({
    required int customerId,
    required Money amount,
    required DateTime paymentDate,
    int? linkedSaleId,
    String? note,
  });
  Future<Result<List<CustomerPayment>>> getCustomerPayments({required int customerId});
  Stream<List<CustomerPayment>> watchCustomerPayments({required int customerId});
  Future<Result<List<CustomerPayment>>> getAllPayments({DateTime? from, DateTime? to});
}
```

---

## P6-02: دفع لمورد

نفس P6-01 بالعكس تماماً:
```
1. تحقق: المبلغ > 0 + المورد موجود ونشط
2. احسب newBalance = supplier.currentBalance - amount
3. أدرج supplier_payments (amount, payment_date, linked_purchase_id?)
4. أدرج supplier_ledger_entries (payment, decrease, balanceAfter)
5. حدّث suppliers.current_balance
6. احسب newCashboxBalance = lastCashboxBalance - amount
7. أدرج cashbox_transactions (supplier_payment_out, out, balanceAfter)
8. audit_log
9. Commit أو Rollback
```

---

## الملفات المطلوبة

```
lib/features/customer_payments/domain/entities/customer_payment.dart
lib/features/customer_payments/domain/repositories/customer_payment_repository.dart
lib/features/customer_payments/domain/usecases/record_customer_payment_usecase.dart
lib/features/customer_payments/domain/usecases/watch_customer_payments_usecase.dart
lib/features/customer_payments/domain/usecases/get_all_payments_usecase.dart
lib/features/customer_payments/data/daos/customer_payments_dao.dart
lib/features/customer_payments/data/repositories/customer_payment_repository_impl.dart
lib/features/customer_payments/presentation/cubit/record_payment_cubit.dart
lib/features/customer_payments/presentation/cubit/record_payment_state.dart
lib/features/customer_payments/presentation/pages/customer_payments_page.dart
lib/features/customer_payments/presentation/widgets/record_payment_dialog.dart

lib/features/supplier_payments/domain/entities/supplier_payment.dart
lib/features/supplier_payments/domain/repositories/supplier_payment_repository.dart
lib/features/supplier_payments/domain/usecases/record_supplier_payment_usecase.dart
lib/features/supplier_payments/domain/usecases/watch_supplier_payments_usecase.dart
lib/features/supplier_payments/data/daos/supplier_payments_dao.dart
lib/features/supplier_payments/data/repositories/supplier_payment_repository_impl.dart
lib/features/supplier_payments/presentation/cubit/record_supplier_payment_cubit.dart
lib/features/supplier_payments/presentation/cubit/record_supplier_payment_state.dart
lib/features/supplier_payments/presentation/pages/supplier_payments_page.dart
lib/features/supplier_payments/presentation/widgets/record_supplier_payment_dialog.dart
```

---

## الملفات المشتركة التي تُعدَّل

**`injector.dart`:** أضف DAOs + Repositories + UseCases للـcustomer_payments و supplier_payments

**`app_database.dart`:** أضف `CustomerPaymentsDao` و`SupplierPaymentsDao` في قائمة `daos`

**`app_router.dart`:**
```dart
GoRoute(path: '/customer-payments', builder: (_, __) => const CustomerPaymentsPage()),
GoRoute(path: '/supplier-payments', builder: (_, __) => const SupplierPaymentsPage()),
```

**بعد التعديل:** `dart run build_runner build --delete-conflicting-outputs`

---

## نقطة تكامل مهمة: RecordPaymentDialog يُفتح من مكانين

سيُستخدم `RecordPaymentDialog` من:
1. صفحة قائمة التحصيلات (`CustomerPaymentsPage`)
2. صفحة تفاصيل العميل (`CustomersPage` → كشف الحساب) — زر "تسجيل تحصيل"

لذلك: اجعل الـDialog قابلاً للاستدعاء مع `customerId` مُمرَّر كمعامل.

---

## نقاط الترابط مع المراحل القادمة

### G (الخزينة) تعتمد على:
- `cashbox_transactions` بنوع `customer_payment_in` و`supplier_payment_out`
- الـStream على cashbox_transactions يُحدَّث فورياً

### I (التقارير) تعتمد على:
- `customer_payments` مع فلاتر تاريخ (تقرير التحصيلات)
- `supplier_payments` مع فلاتر تاريخ (تقرير المدفوعات)

### J (Dashboard) تعتمد على:
- Stream على `customer_payments` اليوم — إجمالي التحصيلات اليومية

---

## تعريف الاكتمال (DoD)

- [ ] `flutter analyze` = "No issues found!"
- [ ] `flutter test` = كل الاختبارات ناجحة
- [ ] Transaction ذرية: لدجر + رصيد + خزينة + audit في خطوة واحدة
- [ ] الربط الاختياري بفاتورة يعمل
- [ ] RecordPaymentDialog قابل للاستدعاء من أي شاشة
- [ ] رصيد العميل/المورد يُحدَّث فورياً بعد التسجيل
