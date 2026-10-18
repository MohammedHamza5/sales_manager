# TASK_A — إصلاح عاجل: Lint Warning + Failing Tests
> هذا الملف هو مهمتك الكاملة. اقرأه من أوله لآخره ثم نفّذ.

---

## السياق الإلزامي (اقرأ أولاً)

اقرأ هذه الملفات بالترتيب قبل أي شيء:
1. `docs/ARCHITECTURE_MASTER.md`
2. `docs/AGENT_RULES.md`

---

## هدفك من هذه الدردشة

تحقيق:
- `flutter analyze` → "No issues found!"
- `flutter test` → "All tests passed!" (56/56)

لا شيء أكثر، لا شيء أقل.

---

## المشكلة الأولى — Lint Warning

**الملف:** `lib/features/inventory/presentation/pages/inventory_page.dart`
**السطر:** 84
**الخطأ:** `unawaited_futures` — Missing an `await` for the Future

**الكود الحالي (السطر 79–89):**
```dart
onPressed: () async {
  final getProducts = getIt<GetProductsUseCase>();
  final result = await getProducts();
  if (context.mounted) {
    final products = result.isSuccess ? (result.dataOrNull ?? <Product>[]) : <Product>[];
    StockAdjustmentDialog.show(   // هنا المشكلة: بلا await
      context,
      availableProducts: products,
    );
  }
},
```

**الإصلاح:**
```dart
onPressed: () async {
  final getProducts = getIt<GetProductsUseCase>();
  final result = await getProducts();
  if (!context.mounted) return;
  final products = result.isSuccess ? (result.dataOrNull ?? <Product>[]) : <Product>[];
  await StockAdjustmentDialog.show(
    context,
    availableProducts: products,
  );
},
```

تحقق من signature `StockAdjustmentDialog.show()` — إن أعادت `void` استخدم بدلاً عنه:
```dart
import 'dart:async';
// ثم:
unawaited(StockAdjustmentDialog.show(context, availableProducts: products));
```

---

## المشكلة الثانية — 4 Failing Tests

**الملف:** `test/features/inventory/presentation/widgets/stock_adjustment_dialog_test.dart`

**الاختبار الفاشل:** "Switching to addition updates labels and preview"

**الخطأ:** `WidgetController._getElementPoint` — العنصر غير قابل للنقر

**خطة الإصلاح:**
1. اقرأ `lib/features/inventory/presentation/widgets/stock_adjustment_dialog.dart` — ابحث عن زر التبديل بين "إضافة" و"خصم"
2. اقرأ الاختبار — ابحث عن السطر الذي يفشل (tester.tap)
3. قارن الـfinder المستخدم في الاختبار بالعنصر الحقيقي
4. الحلول المحتملة:
   - إذا العنصر خارج الـviewport: أضف `await tester.ensureVisible(finder)` قبل tap
   - إذا الـKey مختلف بين الـWidget والاختبار: وحّدهما
   - إذا الـWidget تغير هيكله: حدّث الاختبار ليعكس الواقع

---

## الأوامر

```bash
flutter analyze
flutter test
flutter test test/features/inventory/presentation/widgets/stock_adjustment_dialog_test.dart --verbose
```

---

## تعريف الاكتمال (DoD)

- [ ] `flutter analyze` = "No issues found!"
- [ ] `flutter test` = 56/56 passed
- [ ] لا تعديل على منطق الأعمال — إصلاح تقني فقط

---

## نقاط الترابط (لا تكسرها)

- `StockAdjustmentDialog.show()` تُستخدم في `inventory_page.dart` والاختبارات — لا تغير الـsignature
- `app_database.dart` و`injector.dart` خارج نطاق هذه المهمة تماماً
- لا تُعدّل على `StockAdjustmentCubit` أو `RecordStockAdjustmentUseCase`

---

## عند الانتهاء

أبلغ المستخدم بالنتيجة الدقيقة:
```
flutter analyze: No issues found.
flutter test: 56 tests passed, 0 failed.
```
