import '../../../../core/result/result.dart';
import '../entities/collections_report.dart';
import '../repositories/report_repository.dart';

class GetCollectionsReportUseCase {
  final ReportRepository _repository;

  const GetCollectionsReportUseCase(this._repository);

  Future<Result<CollectionsReport>> call({
    required DateTime from,
    required DateTime to,
    int? customerId,
  }) {
    return _repository.getCollectionsReport(
      from: from,
      to: to,
      customerId: customerId,
    );
  }
}
