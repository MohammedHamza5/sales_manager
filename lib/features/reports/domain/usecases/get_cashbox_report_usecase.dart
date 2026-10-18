import '../../../../core/result/result.dart';
import '../entities/cashbox_report.dart';
import '../repositories/report_repository.dart';

class GetCashboxReportUseCase {
  final ReportRepository _repository;

  const GetCashboxReportUseCase(this._repository);

  Future<Result<CashboxReport>> call({
    required DateTime from,
    required DateTime to,
    String? transactionType,
  }) {
    return _repository.getCashboxReport(
      from: from,
      to: to,
      transactionType: transactionType,
    );
  }
}
