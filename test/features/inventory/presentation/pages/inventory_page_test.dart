import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/di/injector.dart';
import 'package:sales_manager/core/strings/app_strings.dart';
import 'package:sales_manager/features/inventory/domain/entities/inventory_movement.dart';
import 'package:sales_manager/features/inventory/domain/usecases/watch_inventory_movements_usecase.dart';
import 'package:sales_manager/features/inventory/presentation/pages/inventory_page.dart';

class MockWatchInventoryMovementsUseCase extends Mock
    implements WatchInventoryMovementsUseCase {}

void main() {
  late MockWatchInventoryMovementsUseCase mockWatch;

  final sampleMovements = [
    InventoryMovement(
      id: 1,
      productId: 1,
      productName: 'سكر أبيض',
      productUnit: 'كيلو',
      type: MovementType.openingBalance,
      quantityDelta: Decimal.parse('100'),
      balanceAfter: Decimal.parse('100'),
      createdAt: DateTime(2026, 1, 1, 9, 0),
    ),
    InventoryMovement(
      id: 2,
      productId: 2,
      productName: 'شاي أحمر',
      productUnit: 'علبة',
      type: MovementType.purchase,
      quantityDelta: Decimal.parse('40'),
      balanceAfter: Decimal.parse('40'),
      createdAt: DateTime(2026, 1, 1, 10, 0),
    ),
  ];

  setUp(() async {
    mockWatch = MockWatchInventoryMovementsUseCase();

    await getIt.reset();
    getIt.registerSingleton<WatchInventoryMovementsUseCase>(mockWatch);
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('InventoryPage renders title, filter choices, and data table', (tester) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    when(() => mockWatch(productId: null, type: null))
        .thenAnswer((_) => Stream.value(sampleMovements));

    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: InventoryPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.inventoryMovements), findsOneWidget);
    expect(find.text('جميع العمليات'), findsOneWidget);
    expect(find.text('سكر أبيض'), findsOneWidget);
    expect(find.text('شاي أحمر'), findsOneWidget);
    expect(find.byType(DataTable), findsOneWidget);
  });
}
