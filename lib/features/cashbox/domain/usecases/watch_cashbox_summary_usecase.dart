import '../entities/cashbox_summary.dart';
import '../repositories/cashbox_repository.dart';

class WatchCashboxSummaryUseCase {
  final CashboxRepository _repository;

  const WatchCashboxSummaryUseCase(this._repository);

  Stream<CashboxSummary> call(DateTime date) {
    return _repository.watchDailySummary(date);
  }
}
