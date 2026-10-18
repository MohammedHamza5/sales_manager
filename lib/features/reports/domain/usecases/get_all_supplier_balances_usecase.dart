import '../../../../core/result/result.dart';
import '../entities/supplier_account_report.dart';
import '../repositories/report_repository.dart';

class GetAllSupplierBalancesUseCase {
  final ReportRepository _repository;

  const GetAllSupplierBalancesUseCase(this._repository);

  Future<Result<List<SupplierBalanceSummary>>> call() {
    return _repository.getAllSupplierBalances();
  }
}
