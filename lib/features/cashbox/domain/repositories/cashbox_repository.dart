import '../../../../core/money/money.dart';
import '../../../../core/result/result.dart';
import '../entities/cashbox_summary.dart';
import '../entities/cashbox_transaction_entity.dart';

abstract interface class CashboxRepository {
  /// Watches cashbox transactions with optional reactive filters.
  Stream<List<CashboxTransactionEntity>> watchTransactions({
    String? direction,
    String? type,
    DateTime? from,
    DateTime? to,
  });

  /// Gets a snapshot list of transactions with optional filters.
  Future<Result<List<CashboxTransactionEntity>>> getTransactions({
    String? direction,
    String? type,
    DateTime? from,
    DateTime? to,
  });

  /// Gets the latest computed cashbox balance.
  Future<Result<Money>> getCurrentBalance();

  /// Watches the real-time cashbox balance.
  Stream<Money> watchCurrentBalance();

  /// Computes the daily financial summary for the given date.
  Future<Result<CashboxSummary>> getDailySummary(DateTime date);

  /// Watches the real-time daily financial summary for the given date.
  Stream<CashboxSummary> watchDailySummary(DateTime date);
}
