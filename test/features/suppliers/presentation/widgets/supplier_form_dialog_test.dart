import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/result/result.dart';
import 'package:sales_manager/features/suppliers/domain/entities/supplier.dart';
import 'package:sales_manager/features/suppliers/presentation/cubit/suppliers_cubit.dart';
import 'package:sales_manager/features/suppliers/presentation/widgets/supplier_form_dialog.dart';

class MockSuppliersCubit extends Mock implements SuppliersCubit {}

class FakeSupplier extends Fake implements Supplier {}

void main() {
  late MockSuppliersCubit mockCubit;

  final sampleSupplier = Supplier(
    id: 1,
    name: 'مورد تجريبي',
    phone: '01012345678',
    address: 'القاهرة',
    notes: 'ملاحظة',
    currentBalance: const Money.fromPiastres(5000),
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
    createdBy: 'admin',
  );

  setUpAll(() {
    registerFallbackValue(FakeSupplier());
    registerFallbackValue(Money.zero);
  });

  setUp(() {
    mockCubit = MockSuppliersCubit();
  });

  Widget createWidgetUnderTest({Supplier? supplier}) {
    return MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => SupplierFormDialog.show(context, mockCubit, supplier),
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ),
    );
  }

  group('SupplierFormDialog Widget Tests', () {
    testWidgets('Empty supplier name shows validation error and does not call cubit',
        (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Submit with empty name
      final saveButton = find.text('تسجيل المورد');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('اسم المورد مطلوب ولا يمكن تركه فارغاً'), findsOneWidget);
      verifyZeroInteractions(mockCubit);
    });

    testWidgets('Invalid phone format shows validation error', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Enter name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'اسم المورد أو الشركة *'),
        'شركة الأهرام',
      );

      // Enter short/invalid phone
      await tester.enterText(
        find.widgetWithText(TextFormField, 'رقم الهاتف (اختياري)'),
        '12',
      );

      final saveButton = find.text('تسجيل المورد');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('يرجى إدخال رقم هاتف صحيح'), findsOneWidget);
      verifyZeroInteractions(mockCubit);
    });

    testWidgets('Valid inputs in add mode calls cubit.addSupplier and dismisses',
        (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      when(() => mockCubit.addSupplier(
            name: any(named: 'name'),
            phone: any(named: 'phone'),
            address: any(named: 'address'),
            notes: any(named: 'notes'),
            initialBalance: any(named: 'initialBalance'),
            createdBy: any(named: 'createdBy'),
          )).thenAnswer((_) async => Success(sampleSupplier));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Fill in fields
      await tester.enterText(
        find.widgetWithText(TextFormField, 'اسم المورد أو الشركة *'),
        'شركة السلام للمقاولات',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'رقم الهاتف (اختياري)'),
        '01011112222',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'العنوان / المركز الرئيسي (اختياري)'),
        'العاشر من رمضان',
      );
      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'رصيد المديونية الافتتاحي للمورد بالجنيه (اختياري)',
        ),
        '250.00',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'ملاحظات إضافية (اختياري)'),
        'تحويل بنكي',
      );

      final saveButton = find.text('تسجيل المورد');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      verify(() => mockCubit.addSupplier(
            name: 'شركة السلام للمقاولات',
            phone: '01011112222',
            address: 'العاشر من رمضان',
            notes: 'تحويل بنكي',
            initialBalance: const Money.fromPiastres(25000),
          )).called(1);

      // Dialog is popped and snackbar feedback is visible
      expect(find.text('تم تسجيل المورد الجديد بنجاح'), findsOneWidget);
    });

    testWidgets('Edit mode loads supplier data and calls cubit.updateSupplier',
        (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final updatedSupplier = sampleSupplier.copyWith(
        name: 'مورد معدل',
        address: 'الإسكندرية',
      );

      when(() => mockCubit.updateSupplier(any()))
          .thenAnswer((_) async => Success(updatedSupplier));

      await tester.pumpWidget(createWidgetUnderTest(supplier: sampleSupplier));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('تعديل بيانات المورد'), findsOneWidget);
      expect(find.text('مورد تجريبي'), findsOneWidget);
      expect(find.text('01012345678'), findsOneWidget);

      // Modify address
      await tester.enterText(
        find.widgetWithText(TextFormField, 'العنوان / المركز الرئيسي (اختياري)'),
        'الإسكندرية',
      );

      final saveButton = find.text('حفظ التعديلات');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      verify(() => mockCubit.updateSupplier(any())).called(1);
      expect(find.text('تم تعديل بيانات المورد بنجاح'), findsOneWidget);
    });
  });
}
