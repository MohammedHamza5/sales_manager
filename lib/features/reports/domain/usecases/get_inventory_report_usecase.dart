import '../../../../core/result/result.dart';
import '../entities/inventory_report.dart';
import '../repositories/report_repository.dart';

class GetInventoryReportUseCase {
  final ReportRepository _repository;

  const GetInventoryReportUseCase(this._repository);

  Future<Result<InventoryReport>> call({
    int? productId,
    String? movementType,
    DateTime? from,
    DateTime? to,
  }) {
    return _repository.getInventoryReport(
      productId: productId,
      movementType: movementType,
      from: from,
      to: to,
    );
  }
}
