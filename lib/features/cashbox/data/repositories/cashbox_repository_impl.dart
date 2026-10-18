import '../../../../core/money/money.dart';
import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/cashbox_summary.dart';
import '../../domain/entities/cashbox_transaction_entity.dart';
import '../../domain/repositories/cashbox_repository.dart';
import '../daos/cashbox_dao.dart';
import '../../../../core/database/app_database.dart';

class CashboxRepositoryImpl implements CashboxRepository {
  final CashboxDao _dao;

  CashboxRepositoryImpl(this._dao);

  @override
  Stream<List<CashboxTransactionEntity>> watchTransactions({
    String? direction,
    String? type,
    DateTime? from,
    DateTime? to,
  }) {
    return _dao
        .watchTransactions(
          direction: direction,
          type: type,
          from: from,
          to: to,
        )
        .map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<Result<List<CashboxTransactionEntity>>> getTransactions({
    String? direction,
    String? type,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final rows = await _dao.getTransactions(
        direction: direction,
        type: type,
        from: from,
        to: to,
      );
      return Success(rows.map(_toDomain).toList());
    } catch (e) {
      return FailureResult(
        DatabaseFailure(message: 'فشل في جلب حركات الخزينة: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<Money>> getCurrentBalance() async {
    try {
      final latest = await _dao.getLatestTransaction();
      if (latest == null) {
        return const Success(Money.zero);
      }
      return Success(Money.fromPiastres(latest.balanceAfter));
    } catch (e) {
      return FailureResult(
        DatabaseFailure(message: 'فشل في استعلام رصيد الخزينة: ${e.toString()}'),
      );
    }
  }

  @override
  Stream<Money> watchCurrentBalance() {
    return _dao.watchLatestTransaction().map((latest) {
      if (latest == null) return Money.zero;
      return Money.fromPiastres(latest.balanceAfter);
    });
  }

  @override
  Future<Result<CashboxSummary>> getDailySummary(DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

      final rows = await _dao.getTransactionsBetween(start, end);
      final currentBalanceRes = await getCurrentBalance();
      final currentBal = currentBalanceRes.dataOrNull ?? Money.zero;

      return Success(_calculateSummary(rows, currentBal));
    } catch (e) {
      return FailureResult(
        DatabaseFailure(message: 'فشل في حساب ملخص الخزينة اليومي: ${e.toString()}'),
      );
    }
  }

  @override
  Stream<CashboxSummary> watchDailySummary(DateTime date) {
    final start = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    return _dao.watchTransactionsBetween(start, end).asyncMap((rows) async {
      final currentBalanceRes = await getCurrentBalance();
      final currentBal = currentBalanceRes.dataOrNull ?? Money.zero;
      return _calculateSummary(rows, currentBal);
    });
  }

  CashboxSummary _calculateSummary(
    List<CashboxTransactionEntry> rows,
    Money currentBalance,
  ) {
    int totalInPiastres = 0;
    int totalOutPiastres = 0;

    for (final row in rows) {
      if (row.direction == 'in') {
        totalInPiastres += row.amount;
      } else if (row.direction == 'out') {
        totalOutPiastres += row.amount;
      }
    }

    final totalIn = Money.fromPiastres(totalInPiastres);
    final totalOut = Money.fromPiastres(totalOutPiastres);
    final netAmount = totalIn - totalOut;

    return CashboxSummary(
      totalIn: totalIn,
      totalOut: totalOut,
      netAmount: netAmount,
      currentBalance: currentBalance,
      transactionCount: rows.length,
    );
  }

  CashboxTransactionEntity _toDomain(CashboxTransactionEntry row) {
    return CashboxTransactionEntity(
      id: row.id,
      transactionType: row.transactionType,
      amount: Money.fromPiastres(row.amount),
      direction: row.direction,
      balanceAfter: Money.fromPiastres(row.balanceAfter),
      referenceType: row.referenceType,
      referenceId: row.referenceId,
      note: row.note,
      createdAt: row.createdAt,
      createdBy: row.createdBy,
    );
  }
}
