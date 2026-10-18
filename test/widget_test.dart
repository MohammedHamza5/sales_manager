import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_manager/app/app.dart';
import 'package:sales_manager/core/database/app_database.dart';
import 'package:sales_manager/core/di/injector.dart';
import 'package:sales_manager/core/strings/app_strings.dart';

void main() {
  late AppDatabase db;

  setUpAll(() async {
    db = AppDatabase(NativeDatabase.memory());
    await initDependencies(database: db);
  });

  tearDownAll(() async {
    await db.close();
    await getIt.reset();
  });

  testWidgets('App smoke test renders navigation rail and dashboard', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const SalesManagerApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.text(AppStrings.dashboard), findsWidgets);
  });
}
