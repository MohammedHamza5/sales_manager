import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/result/failures.dart';
import 'package:sales_manager/core/result/result.dart';
import 'package:sales_manager/features/dashboard/domain/entities/daily_stats.dart';
import 'package:sales_manager/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:sales_manager/features/dashboard/domain/usecases/get_dashboard_data_usecase.dart';
import 'package:sales_manager/features/dashboard/domain/usecases/watch_dashboard_data_usecase.dart';
import 'package:sales_manager/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:sales_manager/features/dashboard/presentation/cubit/dashboard_state.dart';

class MockWatchDashboardDataUseCase extends Mock
    implements WatchDashboardDataUseCase {}

class MockGetDashboardDataUseCase extends Mock
    implements GetDashboardDataUseCase {}

void main() {
  late MockWatchDashboardDataUseCase mockWatch;
  late MockGetDashboardDataUseCase mockGet;
  late DashboardCubit cubit;

  const testData = DashboardData(
    cashboxBalance: Money.fromPiastres(50000),
    dailyStats: DailyStats(
      todaySales: Money.fromPiastres(12000),
      todayCollections: Money.fromPiastres(8000),
      todayPurchases: Money.fromPiastres(5000),
      todayExpenses: Money.fromPiastres(2000),
      todaySalesCount: 3,
      todayCollectionsCount: 2,
    ),
    totalCustomerDebt: Money.fromPiastres(15000),
    totalSupplierPayables: Money.fromPiastres(10000),
    lowStockProducts: [],
    recentActivities: [],
  );

  setUp(() {
    mockWatch = MockWatchDashboardDataUseCase();
    mockGet = MockGetDashboardDataUseCase();
    cubit = DashboardCubit(
      watchDashboardData: mockWatch,
      getDashboardData: mockGet,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('DashboardCubit Tests', () {
    test('initial state is DashboardInitial', () {
      expect(cubit.state, equals(const DashboardInitial()));
    });

    blocTest<DashboardCubit, DashboardState>(
      'init emits [DashboardLoading, DashboardLoaded] when stream emits',
      build: () {
        when(() => mockWatch()).thenAnswer(
          (_) => Stream.value(testData),
        );
        return cubit;
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        const DashboardLoading(),
        const DashboardLoaded(testData),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'refresh emits [DashboardLoading, DashboardLoaded] on success',
      build: () {
        when(() => mockGet()).thenAnswer(
          (_) async => const Success(testData),
        );
        return cubit;
      },
      act: (cubit) => cubit.refresh(),
      expect: () => [
        const DashboardLoading(),
        const DashboardLoaded(testData),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'refresh emits [DashboardLoading, DashboardError] on failure',
      build: () {
        when(() => mockGet()).thenAnswer(
          (_) async => const FailureResult(DatabaseFailure(
            message: 'حدث خطأ في قاعدة البيانات',
          )),
        );
        return cubit;
      },
      act: (cubit) => cubit.refresh(),
      expect: () => [
        const DashboardLoading(),
        const DashboardError('حدث خطأ في قاعدة البيانات'),
      ],
    );
  });
}
