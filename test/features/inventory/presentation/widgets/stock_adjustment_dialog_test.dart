import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/di/injector.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/features/inventory/domain/usecases/record_stock_adjustment_usecase.dart';
import 'package:sales_manager/features/inventory/presentation/cubit/stock_adjustment_cubit.dart';
import 'package:sales_manager/features/inventory/presentation/widgets/stock_adjustment_dialog.dart';
import 'package:sales_manager/features/products/domain/entities/product.dart';

class MockRecordStockAdjustmentUseCase extends Mock
    implements RecordStockAdjustmentUseCase {}

class MockStockAdjustmentCubit extends Mock implements StockAdjustmentCubit {}

void main() {
  late MockRecordStockAdjustmentUseCase mockUseCase;

  final sampleProduct = Product(
    id: 10,
    name: 'زيت عباد الشمس',
    code: 'OIL-101',
    unit: 'لتر',
    currentSalePrice: const Money.fromPiastres(6500),
    currentPurchasePrice: const Money.fromPiastres(5200),
    currentQuantity: Decimal.parse('20'),
    createdAt: DateTime(2026, 1, 1),
  );

  setUp(() async {
    await getIt.reset();
    mockUseCase = MockRecordStockAdjustmentUseCase();
    getIt.registerSingleton<RecordStockAdjustmentUseCase>(mockUseCase);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget buildTestDialog({
    Product? preselectedProduct,
    List<Product>? availableProducts,
    StockAdjustmentCubit? cubit,
  }) {
    return MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: BlocProvider<StockAdjustmentCubit>(
            create: (_) =>
                cubit ??
                StockAdjustmentCubit(recordStockAdjustmentUseCase: mockUseCase),
            child: StockAdjustmentDialog(
              preselectedProduct: preselectedProduct,
              availableProducts: availableProducts,
            ),
          ),
        ),
      ),
    );
  }

  group('StockAdjustmentDialog Widget Tests', () {
    testWidgets('Renders preselected product details and title correctly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestDialog(preselectedProduct: sampleProduct),
      );
      await tester.pumpAndSettle();

      expect(find.text('تسوية مخزنية يدوية'), findsOneWidget);
      expect(find.text('زيت عباد الشمس'), findsOneWidget);
      expect(find.textContaining('OIL-101'), findsOneWidget);
      expect(find.textContaining('20 لتر'), findsWidgets);
      expect(find.text('خصم (عجز / تالف)'), findsOneWidget);
      expect(find.text('إضافة (فائض جرد)'), findsOneWidget);
    });

    testWidgets(
      'Live preview calculates decrease correctly and avoids surprise',
      (tester) async {
        tester.view.physicalSize = const Size(1366, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          buildTestDialog(preselectedProduct: sampleProduct),
        );
        await tester.pumpAndSettle();

        // Enter quantity 5 (decrease mode is default)
        final quantityFinder = find.byType(TextFormField).first;
        await tester.enterText(quantityFinder, '5');
        await tester.pumpAndSettle();

        // Check preview: Current 20, Delta - 5, Result 15
        expect(find.text('- 5 لتر'), findsOneWidget);
        expect(find.text('15 لتر'), findsOneWidget);
      },
    );

    testWidgets(
      'Strict zero-overselling enforcement: excess decrease shows warning banner',
      (tester) async {
        tester.view.physicalSize = const Size(1366, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          buildTestDialog(preselectedProduct: sampleProduct),
        );
        await tester.pumpAndSettle();

        // Current quantity is 20. Try to decrease by 25!
        final quantityFinder = find.byType(TextFormField).first;
        await tester.enterText(quantityFinder, '25');
        await tester.pumpAndSettle();

        // Warning banner must be visible
        expect(
          find.text(
            'حظر صارم: لا يمكن إنقاص المخزون بالسالب نهائياً وفق ميثاق النظام',
          ),
          findsOneWidget,
        );

        // Confirm button must be disabled
        final submitFinder = find.byWidgetPredicate((w) => w is ElevatedButton);
        expect(submitFinder, findsOneWidget);
        final button = tester.widget<ElevatedButton>(submitFinder);
        expect(button.onPressed, isNull);
      },
    );

    testWidgets('Switching to addition updates labels and preview', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestDialog(preselectedProduct: sampleProduct),
      );
      await tester.pumpAndSettle();

      // Click "إضافة (فائض جرد)"
      await tester.tap(find.text('إضافة (فائض جرد)'));
      await tester.pumpAndSettle();

      // Enter quantity 10
      final quantityFinder = find.byType(TextFormField).first;
      await tester.enterText(quantityFinder, '10');
      await tester.pumpAndSettle();

      // Preview should show + 10 and result 30
      expect(find.text('+ 10 لتر'), findsOneWidget);
      expect(find.text('30 لتر'), findsOneWidget);
      expect(find.text('تأكيد إضافة الرصيد'), findsOneWidget);
    });

    testWidgets('Clicking quick reason chip automatically fills reason text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestDialog(preselectedProduct: sampleProduct),
      );
      await tester.pumpAndSettle();

      // Click "بضاعة تالفة / هالكة" chip
      await tester.tap(find.text('بضاعة تالفة / هالكة'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(TextFormField, 'بضاعة تالفة / هالكة'),
        findsOneWidget,
      );
    });
  });
}
