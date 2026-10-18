import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/di/injector.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/features/inventory/domain/entities/inventory_movement.dart';
import 'package:sales_manager/features/inventory/domain/usecases/watch_inventory_movements_usecase.dart';
import 'package:sales_manager/features/inventory/presentation/cubit/product_movements_cubit.dart';
import 'package:sales_manager/features/inventory/presentation/widgets/product_movements_dialog.dart';
import 'package:sales_manager/features/products/domain/entities/product.dart';

class MockWatchInventoryMovementsUseCase extends Mock
    implements WatchInventoryMovementsUseCase {}

void main() {
  late MockWatchInventoryMovementsUseCase mockWatch;

  final sampleProduct = Product(
    id: 5,
    name: 'أرز فاخر',
    code: 'RICE-01',
    unit: 'كيلو',
    currentSalePrice: const Money.fromPiastres(3500),
    currentPurchasePrice: const Money.fromPiastres(2800),
    currentQuantity: Decimal.parse('45'),
    createdAt: DateTime(2026, 1, 1),
  );

  final sampleMovements = [
    InventoryMovement(
      id: 1,
      productId: 5,
      productName: 'أرز فاخر',
      productUnit: 'كيلو',
      type: MovementType.openingBalance,
      quantityDelta: Decimal.parse('50'),
      balanceAfter: Decimal.parse('50'),
      createdAt: DateTime(2026, 1, 1, 10, 0),
    ),
    InventoryMovement(
      id: 2,
      productId: 5,
      productName: 'أرز فاخر',
      productUnit: 'كيلو',
      type: MovementType.sale,
      quantityDelta: Decimal.parse('-5'),
      balanceAfter: Decimal.parse('45'),
      note: 'فاتورة مبيعات رقم 101',
      createdAt: DateTime(2026, 1, 1, 11, 0),
    ),
  ];

  setUp(() {
    mockWatch = MockWatchInventoryMovementsUseCase();

    getIt.reset();
    getIt.registerSingleton<WatchInventoryMovementsUseCase>(mockWatch);
  });

  tearDown(() {
    getIt.reset();
  });

  testWidgets('ProductMovementsDialog renders header, summary cards, and timeline rows', (tester) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    when(() => mockWatch(productId: 5, type: null))
        .thenAnswer((_) => Stream.value(sampleMovements));

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: BlocProvider(
              create: (context) => ProductMovementsCubit(
                watchMovementsUseCase: mockWatch,
                productId: 5,
              )..init(),
              child: ProductMovementsDialog(product: sampleProduct),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify product name and code
    expect(find.text('أرز فاخر'), findsWidgets);
    expect(find.text('RICE-01'), findsOneWidget);

    // Verify summary cards
    expect(find.text('الرصيد الفعلي الحالي'), findsOneWidget);
    expect(find.text('إجمالي الوارد (+)'), findsOneWidget);
    expect(find.text('إجمالي المنصرف (-)'), findsOneWidget);

    // Verify table movements
    expect(find.text('رصيد افتتاحي'), findsWidgets);
    expect(find.text('فاتورة بيع'), findsWidgets);
    expect(find.text('فاتورة مبيعات رقم 101'), findsOneWidget);
  });
}
