import '../../../../core/result/result.dart';
import '../repositories/opening_balance_repository.dart';

class CheckOpeningBalanceStatusUseCase {
  final OpeningBalanceRepository _repository;

  const CheckOpeningBalanceStatusUseCase(this._repository);

  Future<Result<bool>> call() {
    return _repository.isOpeningBalanceSaved();
  }
}
