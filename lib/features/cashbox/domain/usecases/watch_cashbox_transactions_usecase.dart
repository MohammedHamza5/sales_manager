import '../entities/cashbox_transaction_entity.dart';
import '../repositories/cashbox_repository.dart';

class WatchCashboxTransactionsUseCase {
  final CashboxRepository _repository;

  const WatchCashboxTransactionsUseCase(this._repository);

  Stream<List<CashboxTransactionEntity>> call({
    String? direction,
    String? type,
    DateTime? from,
    DateTime? to,
  }) {
    return _repository.watchTransactions(
      direction: direction,
      type: type,
      from: from,
      to: to,
    );
  }
}
