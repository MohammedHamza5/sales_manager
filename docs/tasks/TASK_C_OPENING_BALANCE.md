# TASK_C — المرحلة 3: الأرصدة الافتتاحية (P3-01)
> انتبه: هذه المهمة تعتمد على اكتمال TASK_B (العملاء والموردون). تأكد أن TASK_B مكتملة قبل البدء.

---

## السياق الإلزامي

اقرأ بالترتيب:
1. `docs/ARCHITECTURE_MASTER.md` — خاصةً §8 (التدفقات الذرية) والملاحظة في §7.14
2. `docs/AGENT_RULES.md`
3. `docs/DART_RULES.md`
4. `docs/FLUTTER_RULES.md`
5. `lib/features/products/data/repositories/product_repository_impl.dart` — مثال حي على Transaction

---

## دورك في النظام الكامل

شاشة الأرصدة الافتتاحية هي **نقطة الصفر** للنظام:
- قبلها: قاعدة بيانات فارغة
- بعدها: النظام جاهز للعمل (مخزون + ذمم عملاء + ذمم موردين + رصيد خزينة)
- تُكتب **مرة واحدة فقط** عند أول تشغيل
- **Transaction واحدة** تكتب في 4 جداول — أي فشل = Rollback كامل

---

## ما هو موجود بالفعل (لا تُعيد بناءه)

```
// الجداول:
inventory_movements   ← تكتب فيه رصيد المخزون الافتتاحي (movement_type = opening_balance)
products              ← تُحدّث current_quantity بعد الكتابة
customer_ledger_entries ← تكتب فيه الرصيد الافتتاحي للعملاء
customers             ← تُحدّث current_balance
supplier_ledger_entries ← تكتب فيه الرصيد الافتتاحي للموردين
suppliers             ← تُحدّث current_balance
cashbox_transactions  ← تكتب فيه رصيد الخزينة الافتتاحي
settings              ← تكتب فيه علامة "تم إدخال الأرصدة الافتتاحية" لمنع التكرار

// من TASK_B (يجب أن تكون جاهزة):
CustomerRepository.getCustomers()
SupplierRepository.getSuppliers()
GetProductsUseCase (موجودة من P1)
```

---

## الملفات المطلوبة

```
lib/features/opening_balance/domain/repositories/opening_balance_repository.dart
lib/features/opening_balance/domain/usecases/save_opening_balances_usecase.dart
lib/features/opening_balance/data/repositories/opening_balance_repository_impl.dart
lib/features/opening_balance/presentation/cubit/opening_balance_cubit.dart
lib/features/opening_balance/presentation/cubit/opening_balance_state.dart
lib/features/opening_balance/presentation/pages/opening_balance_page.dart
lib/features/opening_balance/presentation/widgets/product_balance_row.dart
lib/features/opening_balance/presentation/widgets/stakeholder_balance_row.dart
```

---

## نموذج البيانات المُدخَل

```dart
class OpeningBalanceInput {
  // مخزون
  final List<ProductOpeningBalance> products; // productId + initialQuantity (Decimal)
  
  // ذمم عملاء
  final List<StakeholderOpeningBalance> customers; // customerId + balance (Money) + effect
  
  // ذمم موردين
  final List<StakeholderOpeningBalance> suppliers; // supplierId + balance (Money) + effect
  
  // خزينة
  final Money cashboxBalance; // int قرش
}
```

---

## تدفق UseCase الذري (Transaction واحدة)

```dart
// داخل db.transaction():

// 1. لكل منتج له رصيد افتتاحي > 0:
await db.into(db.inventoryMovements).insert(
  InventoryMovementsCompanion.insert(
    productId: productId,
    movementType: 'opening_balance',
    quantityDelta: qty,
    balanceAfter: qty,
    referenceType: const Value('opening_balance'),
    note: const Value('رصيد افتتاحي'),
  ),
);
await db.update(db.products)
  ..where((p) => p.id.equals(productId))
  ..write(ProductsCompanion(currentQuantity: Value(qty)));

// 2. لكل عميل له رصيد > 0:
await db.into(db.customerLedgerEntries).insert(
  CustomerLedgerEntriesCompanion.insert(
    customerId: customerId,
    entryType: 'opening_balance',
    amount: Value(balance.piastres),
    effect: 'increase', // العميل عليه دين لنا
    balanceAfter: Value(balance.piastres),
    note: const Value('رصيد افتتاحي'),
  ),
);
await db.update(db.customers)
  ..where((c) => c.id.equals(customerId))
  ..write(CustomersCompanion(currentBalance: Value(balance.piastres)));

// 3. لكل مورد له رصيد > 0:
// نفس الخطوة 2 مع suppliers/supplierLedgerEntries

// 4. رصيد الخزينة:
await db.into(db.cashboxTransactions).insert(
  CashboxTransactionsCompanion.insert(
    transactionType: 'opening_balance',
    amount: cashboxBalance.piastres,
    direction: 'in',
    balanceAfter: Value(cashboxBalance.piastres),
    note: const Value('رصيد خزينة افتتاحي'),
  ),
);

// 5. علامة الإعداد في Settings:
await db.into(db.settings).insertOnConflictUpdate(
  SettingsCompanion.insert(
    key: 'opening_balance_saved',
    value: 'true',
  ),
);

// 6. AuditLog واحد للعملية كلها:
await db.into(db.auditLog).insert(
  AuditLogCompanion.insert(
    entityType: 'system',
    entityId: 0,
    action: 'opening_balance',
    payloadAfter: Value(jsonEncode({
      'products_count': products.length,
      'customers_count': customers.length,
      'suppliers_count': suppliers.length,
      'cashbox': cashboxBalance.piastres,
    })),
  ),
);
```

---

## واجهة المستخدم

**شاشة متعددة الأقسام (Tabs أو Stepper):**

```
[قسم 1: رصيد الخزينة] — حقل واحد فقط
[قسم 2: مخزون المنتجات] — جدول: اسم المنتج | الوحدة | الكمية الافتتاحية
[قسم 3: ذمم العملاء] — جدول: اسم العميل | الرصيد (الدين علي العميل بالجنيه)
[قسم 4: ذمم الموردين] — جدول: اسم المورد | الرصيد (المستحق للمورد بالجنيه)
[زر: حفظ الأرصدة الافتتاحية] — يُفعَّل فقط عند إدخال بيانات صالحة
```

**قواعد الـUI:**
- الحقول التي قيمتها 0 = لا تُدرج في الـTransaction
- بعد الحفظ: رسالة تأكيد + إعادة توجيه للـDashboard
- إذا كانت `settings.opening_balance_saved = true`: اعرض رسالة "تم إدخال الأرصدة الافتتاحية مسبقاً" وأخفِ النموذج

---

## التوجيه (Router)

أضف في `lib/app/router/app_router.dart`:
```dart
GoRoute(
  path: '/opening-balance',
  builder: (context, state) => const OpeningBalancePage(),
),
```

وأضف في `injector.dart`:
```dart
getIt.registerLazySingleton<OpeningBalanceRepository>(
  () => OpeningBalanceRepositoryImpl(db: getIt()),
);
getIt.registerLazySingleton<SaveOpeningBalancesUseCase>(
  () => SaveOpeningBalancesUseCase(
    repository: getIt(),
    productRepository: getIt(), // لجلب قائمة المنتجات
    customerRepository: getIt(), // لجلب قائمة العملاء
    supplierRepository: getIt(), // لجلب قائمة الموردين
  ),
);
```

---

## نقاط الترابط الحرجة مع المراحل القادمة

### P4 (المبيعات) تعتمد على:
- `products.current_quantity` — المُحدَّثة هنا هي نقطة البداية لمنع البيع بالسالب
- `customers.current_balance` — نقطة البداية لكشف الحساب

### P7 (الخزينة) تعتمد على:
- `cashbox_transactions` أول صف هنا هو رصيد الخزينة الافتتاحي
- الرصيد الأولي = `opening_balance` — يجب أن يكون الصف الأقدم

### P9 (التقارير) تعتمد على:
- `inventory_movements` بنوع `opening_balance` يظهر في تقرير المخزون
- `customer_ledger_entries` بنوع `opening_balance` يظهر في كشف حساب العميل

---

## تعريف الاكتمال (DoD)

- [ ] `flutter analyze` = "No issues found!"
- [ ] `flutter test` = كل الاختبارات ناجحة
- [ ] Transaction واحدة تكتب في كل الجداول بشكل ذري
- [ ] إذا فشل حفظ أي جزء → Rollback كامل
- [ ] علامة `opening_balance_saved` تُخزَّن في Settings
- [ ] الشاشة تتحقق من العلامة عند الفتح وتمنع إعادة الإدخال
- [ ] `build_runner` شُغِّل بنجاح بعد أي تعديل على DAOs

---

## عند الانتهاء

أبلغ المستخدم بما يلي:
1. نتيجة `flutter analyze` و`flutter test`
2. تأكيد أن Transaction تكتب في الجداول الأربعة
3. تأكيد أن علامة `opening_balance_saved` تعمل
