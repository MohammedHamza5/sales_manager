import '../../../../core/result/result.dart';
import '../entities/opening_balance_input.dart';

abstract interface class OpeningBalanceRepository {
  /// Checks whether opening balances have already been committed to the system.
  Future<Result<bool>> isOpeningBalanceSaved();

  /// Commits opening balances atomically across cashbox, inventory, customers, and suppliers.
  Future<Result<void>> saveOpeningBalances(
    OpeningBalanceInput input, {
    String createdBy = 'admin',
  });
}
