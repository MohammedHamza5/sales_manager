import '../../../../core/result/result.dart';
import '../entities/cashbox_summary.dart';
import '../repositories/cashbox_repository.dart';

class GetCashboxSummaryUseCase {
  final CashboxRepository _repository;

  const GetCashboxSummaryUseCase(this._repository);

  Future<Result<CashboxSummary>> call(DateTime date) {
    return _repository.getDailySummary(date);
  }
}
