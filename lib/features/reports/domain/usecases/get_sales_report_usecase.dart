import '../../../../core/result/result.dart';
import '../entities/sales_report.dart';
import '../repositories/report_repository.dart';

class GetSalesReportUseCase {
  final ReportRepository _repository;

  const GetSalesReportUseCase(this._repository);

  Future<Result<SalesReport>> call({
    required DateTime from,
    required DateTime to,
    int? customerId,
    String? status,
  }) {
    return _repository.getSalesReport(
      from: from,
      to: to,
      customerId: customerId,
      status: status,
    );
  }
}
