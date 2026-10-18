import '../../../../core/money/money.dart';
import '../repositories/cashbox_repository.dart';

class WatchCashboxBalanceUseCase {
  final CashboxRepository _repository;

  const WatchCashboxBalanceUseCase(this._repository);

  Stream<Money> call() {
    return _repository.watchCurrentBalance();
  }
}
