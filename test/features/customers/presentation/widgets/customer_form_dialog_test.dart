import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/result/result.dart';
import 'package:sales_manager/features/customers/domain/entities/customer.dart';
import 'package:sales_manager/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:sales_manager/features/customers/presentation/widgets/customer_form_dialog.dart';

class MockCustomersCubit extends Mock implements CustomersCubit {}

class FakeCustomer extends Fake implements Customer {}

void main() {
  late MockCustomersCubit mockCubit;

  final sampleCustomer = Customer(
    id: 1,
    name: 'عميل موجود',
    phone: '01012345678',
    address: 'القاهرة',
    notes: 'ملاحظة',
    currentBalance: const Money.fromPiastres(5000),
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
    createdBy: 'admin',
  );

  setUpAll(() {
    registerFallbackValue(FakeCustomer());
    registerFallbackValue(Money.zero);
  });

  setUp(() {
    mockCubit = MockCustomersCubit();
  });

  Widget createWidgetUnderTest({Customer? customer}) {
    return MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => CustomerFormDialog.show(context, mockCubit, customer),
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ),
    );
  }

  group('CustomerFormDialog Widget Tests', () {
    testWidgets('Empty customer name shows validation error and does not call cubit',
        (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Submit with empty name
      final saveButton = find.text('تسجيل العميل');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('اسم العميل مطلوب ولا يمكن تركه فارغاً'), findsOneWidget);
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
        find.widgetWithText(TextFormField, 'اسم العميل *'),
        'محمود علي',
      );

      // Enter short/invalid phone
      await tester.enterText(
        find.widgetWithText(TextFormField, 'رقم الهاتف (اختياري)'),
        '12',
      );

      final saveButton = find.text('تسجيل العميل');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('يرجى إدخال رقم هاتف صحيح'), findsOneWidget);
      verifyZeroInteractions(mockCubit);
    });

    testWidgets('Valid inputs in add mode calls cubit.addCustomer and dismisses',
        (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      when(() => mockCubit.addCustomer(
            name: any(named: 'name'),
            phone: any(named: 'phone'),
            address: any(named: 'address'),
            notes: any(named: 'notes'),
            initialBalance: any(named: 'initialBalance'),
            createdBy: any(named: 'createdBy'),
          )).thenAnswer((_) async => Success(sampleCustomer));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Fill in fields
      await tester.enterText(
        find.widgetWithText(TextFormField, 'اسم العميل *'),
        'أحمد محمود',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'رقم الهاتف (اختياري)'),
        '01011112222',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'العنوان / المنطقة (اختياري)'),
        'الجيزة',
      );
      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'رصيد المديونية الافتتاحي بالجنيه (اختياري)',
        ),
        '100.00',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'ملاحظات إضافية (اختياري)'),
        'دفع نقدي',
      );

      final saveButton = find.text('تسجيل العميل');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      verify(() => mockCubit.addCustomer(
            name: 'أحمد محمود',
            phone: '01011112222',
            address: 'الجيزة',
            notes: 'دفع نقدي',
            initialBalance: const Money.fromPiastres(10000),
          )).called(1);

      // Dialog is popped and snackbar feedback is visible
      expect(find.text('تم تسجيل العميل الجديد بنجاح'), findsOneWidget);
    });

    testWidgets('Edit mode loads customer data and calls cubit.updateCustomer',
        (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final updatedCustomer = sampleCustomer.copyWith(
        name: 'عميل معدل',
        address: 'الإسكندرية',
      );

      when(() => mockCubit.updateCustomer(any()))
          .thenAnswer((_) async => Success(updatedCustomer));

      await tester.pumpWidget(createWidgetUnderTest(customer: sampleCustomer));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('تعديل بيانات العميل'), findsOneWidget);
      expect(find.text('عميل موجود'), findsOneWidget);
      expect(find.text('01012345678'), findsOneWidget);

      // Modify address
      await tester.enterText(
        find.widgetWithText(TextFormField, 'العنوان / المنطقة (اختياري)'),
        'الإسكندرية',
      );

      final saveButton = find.text('حفظ التعديلات');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      verify(() => mockCubit.updateCustomer(any())).called(1);
      expect(find.text('تم تعديل بيانات العميل بنجاح'), findsOneWidget);
    });
  });
}
