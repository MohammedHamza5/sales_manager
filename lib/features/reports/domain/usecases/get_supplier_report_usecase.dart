import '../../../../core/result/result.dart';
import '../entities/supplier_account_report.dart';
import '../repositories/report_repository.dart';

class GetSupplierReportUseCase {
  final ReportRepository _repository;

  const GetSupplierReportUseCase(this._repository);

  Future<Result<SupplierAccountReport>> call({
    required int supplierId,
    required DateTime from,
    required DateTime to,
  }) {
    return _repository.getSupplierReport(
      supplierId: supplierId,
      from: from,
      to: to,
    );
  }
}
