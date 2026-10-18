import '../../../../core/result/result.dart';
import '../entities/profit_report.dart';
import '../repositories/report_repository.dart';

class GetProfitReportUseCase {
  final ReportRepository _repository;

  const GetProfitReportUseCase(this._repository);

  Future<Result<ProfitReport>> call({
    required DateTime from,
    required DateTime to,
    int? productId,
  }) {
    return _repository.getProfitReport(
      from: from,
      to: to,
      productId: productId,
    );
  }
}
