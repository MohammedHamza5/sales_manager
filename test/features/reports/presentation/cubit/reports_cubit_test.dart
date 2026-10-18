import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/result/failures.dart';
import 'package:sales_manager/core/result/result.dart';
import 'package:sales_manager/features/reports/domain/entities/cashbox_report.dart';
import 'package:sales_manager/features/reports/domain/entities/collections_report.dart';
import 'package:sales_manager/features/reports/domain/entities/customer_account_report.dart';
import 'package:sales_manager/features/reports/domain/entities/profit_report.dart';
import 'package:sales_manager/features/reports/domain/entities/sales_report.dart';
import 'package:sales_manager/features/reports/domain/usecases/get_all_customer_balances_usecase.dart';
import 'package:sales_manager/features/reports/domain/usecases/get_all_supplier_balances_usecase.dart';
import 'package:sales_manager/features/reports/domain/usecases/get_cashbox_report_usecase.dart';
import 'package:sales_manager/features/reports/domain/usecases/get_collections_report_usecase.dart';
import 'package:sales_manager/features/reports/domain/usecases/get_customer_report_usecase.dart';
import 'package:sales_manager/features/reports/domain/usecases/get_inventory_report_usecase.dart';
import 'package:sales_manager/features/reports/domain/usecases/get_profit_report_usecase.dart';
import 'package:sales_manager/features/reports/domain/usecases/get_sales_report_usecase.dart';
import 'package:sales_manager/features/reports/domain/usecases/get_supplier_report_usecase.dart';
import 'package:sales_manager/features/reports/presentation/cubit/reports_cubit.dart';
import 'package:sales_manager/features/reports/presentation/cubit/reports_state.dart';

class MockGetSalesReportUseCase extends Mock implements GetSalesReportUseCase {}

class MockGetCollectionsReportUseCase extends Mock
    implements GetCollectionsReportUseCase {}

class MockGetCustomerReportUseCase extends Mock
    implements GetCustomerReportUseCase {}

class MockGetAllCustomerBalancesUseCase extends Mock
    implements GetAllCustomerBalancesUseCase {}

class MockGetSupplierReportUseCase extends Mock
    implements GetSupplierReportUseCase {}

class MockGetAllSupplierBalancesUseCase extends Mock
    implements GetAllSupplierBalancesUseCase {}

class MockGetInventoryReportUseCase extends Mock
    implements GetInventoryReportUseCase {}

class MockGetCashboxReportUseCase extends Mock
    implements GetCashboxReportUseCase {}

class MockGetProfitReportUseCase extends Mock
    implements GetProfitReportUseCase {}

void main() {
  late MockGetSalesReportUseCase mockGetSales;
  late MockGetCollectionsReportUseCase mockGetCollections;
  late MockGetCustomerReportUseCase mockGetCustomer;
  late MockGetAllCustomerBalancesUseCase mockGetAllCustomerBalances;
  late MockGetSupplierReportUseCase mockGetSupplier;
  late MockGetAllSupplierBalancesUseCase mockGetAllSupplierBalances;
  late MockGetInventoryReportUseCase mockGetInventory;
  late MockGetCashboxReportUseCase mockGetCashbox;
  late MockGetProfitReportUseCase mockGetProfit;
  late ReportsCubit cubit;

  final now = DateTime.now();

  setUp(() {
    mockGetSales = MockGetSalesReportUseCase();
    mockGetCollections = MockGetCollectionsReportUseCase();
    mockGetCustomer = MockGetCustomerReportUseCase();
    mockGetAllCustomerBalances = MockGetAllCustomerBalancesUseCase();
    mockGetSupplier = MockGetSupplierReportUseCase();
    mockGetAllSupplierBalances = MockGetAllSupplierBalancesUseCase();
    mockGetInventory = MockGetInventoryReportUseCase();
    mockGetCashbox = MockGetCashboxReportUseCase();
    mockGetProfit = MockGetProfitReportUseCase();

    cubit = ReportsCubit(
      getSalesReport: mockGetSales,
      getCollectionsReport: mockGetCollections,
      getCustomerReport: mockGetCustomer,
      getAllCustomerBalances: mockGetAllCustomerBalances,
      getSupplierReport: mockGetSupplier,
      getAllSupplierBalances: mockGetAllSupplierBalances,
      getInventoryReport: mockGetInventory,
      getCashboxReport: mockGetCashbox,
      getProfitReport: mockGetProfit,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('ReportsCubit Tests', () {
    test('initial state is ReportsInitial', () {
      expect(cubit.state, equals(const ReportsInitial()));
    });

    blocTest<ReportsCubit, ReportsState>(
      'loadSalesReport emits [ReportsLoading, SalesReportLoaded] when sales exist',
      build: () {
        when(() => mockGetSales(
              from: any(named: 'from'),
              to: any(named: 'to'),
              customerId: any(named: 'customerId'),
              status: any(named: 'status'),
            )).thenAnswer(
          (_) async => Success(
            SalesReport(
              from: now,
              to: now,
              totalSales: const Money.fromPiastres(50000),
              totalPaid: const Money.fromPiastres(20000),
              totalRemaining: const Money.fromPiastres(30000),
              salesCount: 1,
              items: [
                SalesReportItem(
                  invoiceNo: 1,
                  saleDate: now,
                  customerName: 'عميل 1',
                  totalAmount: const Money.fromPiastres(50000),
                  paidAmount: const Money.fromPiastres(20000),
                  remainingAmount: const Money.fromPiastres(30000),
                  status: 'confirmed',
                ),
              ],
            ),
          ),
        );
        return cubit;
      },
      act: (cubit) => cubit.loadSalesReport(from: now, to: now),
      expect: () => [
        const ReportsLoading(),
        isA<SalesReportLoaded>(),
      ],
    );

    blocTest<ReportsCubit, ReportsState>(
      'loadSalesReport emits [ReportsLoading, ReportsEmpty] when items are empty',
      build: () {
        when(() => mockGetSales(
              from: any(named: 'from'),
              to: any(named: 'to'),
              customerId: any(named: 'customerId'),
              status: any(named: 'status'),
            )).thenAnswer(
          (_) async => Success(
            SalesReport(
              from: now,
              to: now,
              totalSales: Money.zero,
              totalPaid: Money.zero,
              totalRemaining: Money.zero,
              salesCount: 0,
              items: const [],
            ),
          ),
        );
        return cubit;
      },
      act: (cubit) => cubit.loadSalesReport(from: now, to: now),
      expect: () => [
        const ReportsLoading(),
        const ReportsEmpty('لا توجد مبيعات مسجلة في هذه الفترة'),
      ],
    );

    blocTest<ReportsCubit, ReportsState>(
      'loadSalesReport emits [ReportsLoading, ReportsError] on failure',
      build: () {
        when(() => mockGetSales(
              from: any(named: 'from'),
              to: any(named: 'to'),
              customerId: any(named: 'customerId'),
              status: any(named: 'status'),
            )).thenAnswer(
          (_) async => const FailureResult(DatabaseFailure(message: 'خطأ في قاعدة البيانات')),
        );
        return cubit;
      },
      act: (cubit) => cubit.loadSalesReport(from: now, to: now),
      expect: () => [
        const ReportsLoading(),
        const ReportsError('خطأ في قاعدة البيانات'),
      ],
    );

    blocTest<ReportsCubit, ReportsState>(
      'loadCollectionsReport emits [ReportsLoading, CollectionsReportLoaded] when data exists',
      build: () {
        when(() => mockGetCollections(
              from: any(named: 'from'),
              to: any(named: 'to'),
              customerId: any(named: 'customerId'),
            )).thenAnswer(
          (_) async => Success(
            CollectionsReport(
              from: now,
              to: now,
              totalCollected: const Money.fromPiastres(10000),
              paymentsCount: 1,
              items: [
                CollectionReportItem(
                  paymentId: 1,
                  paymentDate: now,
                  customerName: 'عميل 1',
                  amount: const Money.fromPiastres(10000),
                ),
              ],
            ),
          ),
        );
        return cubit;
      },
      act: (cubit) => cubit.loadCollectionsReport(from: now, to: now),
      expect: () => [
        const ReportsLoading(),
        isA<CollectionsReportLoaded>(),
      ],
    );

    blocTest<ReportsCubit, ReportsState>(
      'loadCustomerReport emits [ReportsLoading, CustomerReportLoaded] with balance list',
      build: () {
        when(() => mockGetAllCustomerBalances()).thenAnswer(
          (_) async => const Success([
            CustomerBalanceSummary(
              customerId: 1,
              customerName: 'عميل أ',
              phone: '01000000000',
              balance: Money.fromPiastres(5000),
            ),
          ]),
        );
        return cubit;
      },
      act: (cubit) => cubit.loadCustomerReport(),
      expect: () => [
        const ReportsLoading(),
        isA<CustomerReportLoaded>(),
      ],
    );

    blocTest<ReportsCubit, ReportsState>(
      'loadCashboxReport emits [ReportsLoading, CashboxReportLoaded]',
      build: () {
        when(() => mockGetCashbox(
              from: any(named: 'from'),
              to: any(named: 'to'),
              transactionType: any(named: 'transactionType'),
            )).thenAnswer(
          (_) async => Success(
            CashboxReport(
              from: now,
              to: now,
              openingBalance: Money.zero,
              closingBalance: const Money.fromPiastres(10000),
              totalIn: const Money.fromPiastres(15000),
              totalOut: const Money.fromPiastres(5000),
              netCashflow: const Money.fromPiastres(10000),
              transactions: [
                CashboxReportItem(
                  id: 1,
                  date: now,
                  transactionType: 'مبيعات نقدية',
                  direction: 'in',
                  amount: const Money.fromPiastres(15000),
                  balanceAfter: const Money.fromPiastres(15000),
                ),
              ],
            ),
          ),
        );
        return cubit;
      },
      act: (cubit) => cubit.loadCashboxReport(from: now, to: now),
      expect: () => [
        const ReportsLoading(),
        isA<CashboxReportLoaded>(),
      ],
    );

    blocTest<ReportsCubit, ReportsState>(
      'emits [ReportsLoading, ProfitReportLoaded] when loadProfitReport succeeds',
      build: () {
        when(() => mockGetProfit(
              from: any(named: 'from'),
              to: any(named: 'to'),
            )).thenAnswer(
          (_) async => Success(
            ProfitReport(
              from: now,
              to: now,
              totalRevenue: const Money.fromPiastres(10000),
              totalCost: const Money.fromPiastres(6000),
              totalGrossProfit: const Money.fromPiastres(4000),
              overallMarginPercentage: 40.0,
              items: [
                ProfitReportItem(
                  productId: 1,
                  productName: 'منتج تجريبي',
                  unit: 'قطعة',
                  soldQuantity: Decimal.fromInt(10),
                  totalRevenue: const Money.fromPiastres(10000),
                  totalCost: const Money.fromPiastres(6000),
                  grossProfit: const Money.fromPiastres(4000),
                  marginPercentage: 40.0,
                ),
              ],
            ),
          ),
        );
        return cubit;
      },
      act: (cubit) => cubit.loadProfitReport(from: now, to: now),
      expect: () => [
        const ReportsLoading(),
        isA<ProfitReportLoaded>(),
      ],
    );
  });
}
