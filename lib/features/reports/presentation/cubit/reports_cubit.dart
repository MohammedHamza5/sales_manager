import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/result.dart';
import '../../domain/usecases/get_all_customer_balances_usecase.dart';
import '../../domain/usecases/get_all_supplier_balances_usecase.dart';
import '../../domain/usecases/get_cashbox_report_usecase.dart';
import '../../domain/usecases/get_collections_report_usecase.dart';
import '../../domain/usecases/get_customer_report_usecase.dart';
import '../../domain/usecases/get_inventory_report_usecase.dart';
import '../../domain/usecases/get_profit_report_usecase.dart';
import '../../domain/usecases/get_sales_report_usecase.dart';
import '../../domain/usecases/get_supplier_report_usecase.dart';
import 'reports_state.dart';

class ReportsCubit extends Cubit<ReportsState> {
  final GetSalesReportUseCase _getSalesReport;
  final GetCollectionsReportUseCase _getCollectionsReport;
  final GetCustomerReportUseCase _getCustomerReport;
  final GetAllCustomerBalancesUseCase _getAllCustomerBalances;
  final GetSupplierReportUseCase _getSupplierReport;
  final GetAllSupplierBalancesUseCase _getAllSupplierBalances;
  final GetInventoryReportUseCase _getInventoryReport;
  final GetCashboxReportUseCase _getCashboxReport;
  final GetProfitReportUseCase _getProfitReport;

  ReportsCubit({
    required GetSalesReportUseCase getSalesReport,
    required GetCollectionsReportUseCase getCollectionsReport,
    required GetCustomerReportUseCase getCustomerReport,
    required GetAllCustomerBalancesUseCase getAllCustomerBalances,
    required GetSupplierReportUseCase getSupplierReport,
    required GetAllSupplierBalancesUseCase getAllSupplierBalances,
    required GetInventoryReportUseCase getInventoryReport,
    required GetCashboxReportUseCase getCashboxReport,
    required GetProfitReportUseCase getProfitReport,
  })  : _getSalesReport = getSalesReport,
        _getCollectionsReport = getCollectionsReport,
        _getCustomerReport = getCustomerReport,
        _getAllCustomerBalances = getAllCustomerBalances,
        _getSupplierReport = getSupplierReport,
        _getAllSupplierBalances = getAllSupplierBalances,
        _getInventoryReport = getInventoryReport,
        _getCashboxReport = getCashboxReport,
        _getProfitReport = getProfitReport,
        super(const ReportsInitial());

  Future<void> loadSalesReport({
    required DateTime from,
    required DateTime to,
    int? customerId,
    String? status,
  }) async {
    emit(const ReportsLoading());
    final result = await _getSalesReport(
      from: from,
      to: to,
      customerId: customerId,
      status: status,
    );

    switch (result) {
      case Success(:final data):
        if (data.items.isEmpty) {
          emit(const ReportsEmpty('لا توجد مبيعات مسجلة في هذه الفترة'));
        } else {
          emit(SalesReportLoaded(data));
        }
      case FailureResult(:final failure):
        emit(ReportsError(failure.message));
    }
  }

  Future<void> loadCollectionsReport({
    required DateTime from,
    required DateTime to,
    int? customerId,
  }) async {
    emit(const ReportsLoading());
    final result = await _getCollectionsReport(
      from: from,
      to: to,
      customerId: customerId,
    );

    switch (result) {
      case Success(:final data):
        if (data.items.isEmpty) {
          emit(const ReportsEmpty('لا توجد تحصيلات مسجلة في هذه الفترة'));
        } else {
          emit(CollectionsReportLoaded(data));
        }
      case FailureResult(:final failure):
        emit(ReportsError(failure.message));
    }
  }

  Future<void> loadCustomerReport({
    int? customerId,
    DateTime? from,
    DateTime? to,
  }) async {
    emit(const ReportsLoading());

    // 1. Fetch balances summary
    final balancesResult = await _getAllCustomerBalances();
    if (balancesResult.isFailure) {
      emit(ReportsError(balancesResult.failureOrNull!.message));
      return;
    }
    final allBalances = balancesResult.dataOrNull ?? [];

    // 2. Fetch specific statement if customerId provided
    if (customerId != null && from != null && to != null) {
      final accountResult = await _getCustomerReport(
        customerId: customerId,
        from: from,
        to: to,
      );
      switch (accountResult) {
        case Success(:final data):
          emit(CustomerReportLoaded(
            accountReport: data,
            allBalances: allBalances,
          ));
        case FailureResult(:final failure):
          emit(ReportsError(failure.message));
      }
    } else {
      if (allBalances.isEmpty) {
        emit(const ReportsEmpty('لا يوجد عملاء مسجلون حالياً'));
      } else {
        emit(CustomerReportLoaded(allBalances: allBalances));
      }
    }
  }

  Future<void> loadSupplierReport({
    int? supplierId,
    DateTime? from,
    DateTime? to,
  }) async {
    emit(const ReportsLoading());

    final balancesResult = await _getAllSupplierBalances();
    if (balancesResult.isFailure) {
      emit(ReportsError(balancesResult.failureOrNull!.message));
      return;
    }
    final allBalances = balancesResult.dataOrNull ?? [];

    if (supplierId != null && from != null && to != null) {
      final accountResult = await _getSupplierReport(
        supplierId: supplierId,
        from: from,
        to: to,
      );
      switch (accountResult) {
        case Success(:final data):
          emit(SupplierReportLoaded(
            accountReport: data,
            allBalances: allBalances,
          ));
        case FailureResult(:final failure):
          emit(ReportsError(failure.message));
      }
    } else {
      if (allBalances.isEmpty) {
        emit(const ReportsEmpty('لا يوجد موردون مسجلون حالياً'));
      } else {
        emit(SupplierReportLoaded(allBalances: allBalances));
      }
    }
  }

  Future<void> loadInventoryReport({
    int? productId,
    String? movementType,
    DateTime? from,
    DateTime? to,
  }) async {
    emit(const ReportsLoading());
    final result = await _getInventoryReport(
      productId: productId,
      movementType: movementType,
      from: from,
      to: to,
    );

    switch (result) {
      case Success(:final data):
        if (data.products.isEmpty && data.movements.isEmpty) {
          emit(const ReportsEmpty('لا توجد بيانات مخزون متوفرة'));
        } else {
          emit(InventoryReportLoaded(data));
        }
      case FailureResult(:final failure):
        emit(ReportsError(failure.message));
    }
  }

  Future<void> loadCashboxReport({
    required DateTime from,
    required DateTime to,
    String? transactionType,
  }) async {
    emit(const ReportsLoading());
    final result = await _getCashboxReport(
      from: from,
      to: to,
      transactionType: transactionType,
    );

    switch (result) {
      case Success(:final data):
        if (data.transactions.isEmpty && data.openingBalance.piastres == 0) {
          emit(const ReportsEmpty('لا توجد حركات نقدية مسجلة في هذه الفترة'));
        } else {
          emit(CashboxReportLoaded(data));
        }
      case FailureResult(:final failure):
        emit(ReportsError(failure.message));
    }
  }

  Future<void> loadProfitReport({
    required DateTime from,
    required DateTime to,
    int? productId,
  }) async {
    emit(const ReportsLoading());
    final result = await _getProfitReport(
      from: from,
      to: to,
      productId: productId,
    );

    switch (result) {
      case Success(:final data):
        if (data.items.isEmpty) {
          emit(const ReportsEmpty('لا توجد مبيعات لحساب الأرباح في هذه الفترة'));
        } else {
          emit(ProfitReportLoaded(data));
        }
      case FailureResult(:final failure):
        emit(ReportsError(failure.message));
    }
  }
}
