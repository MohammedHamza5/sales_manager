import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/payments_cashbox_tables.dart';

part 'cashbox_dao.g.dart';

@DriftAccessor(tables: [CashboxTransactions])
class CashboxDao extends DatabaseAccessor<AppDatabase> with _$CashboxDaoMixin {
  CashboxDao(super.db);

  /// Inserts a new transaction into cashbox_transactions.
  Future<int> insertTransaction(CashboxTransactionsCompanion companion) {
    return into(cashboxTransactions).insert(companion);
  }

  /// Retrieves the single latest transaction row (by ID descending).
  Future<CashboxTransactionEntry?> getLatestTransaction() {
    return (select(cashboxTransactions)
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Watches the latest transaction reactively.
  Stream<CashboxTransactionEntry?> watchLatestTransaction() {
    return (select(cashboxTransactions)
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(1))
        .watchSingleOrNull();
  }

  SimpleSelectStatement<CashboxTransactions, CashboxTransactionEntry> _buildTransactionsQuery({
    String? direction,
    String? type,
    DateTime? from,
    DateTime? to,
  }) {
    final query = select(cashboxTransactions);
    query.where((t) {
      Expression<bool> predicate = const Constant(true);
      if (direction != null && direction.isNotEmpty) {
        predicate = predicate & t.direction.equals(direction);
      }
      if (type != null && type.isNotEmpty) {
        predicate = predicate & t.transactionType.equals(type);
      }
      if (from != null) {
        predicate = predicate & t.createdAt.isBiggerOrEqualValue(from);
      }
      if (to != null) {
        predicate = predicate & t.createdAt.isSmallerOrEqualValue(to);
      }
      return predicate;
    });
    query.orderBy([(t) => OrderingTerm.desc(t.id)]);
    return query;
  }

  /// Fetches transactions based on criteria.
  Future<List<CashboxTransactionEntry>> getTransactions({
    String? direction,
    String? type,
    DateTime? from,
    DateTime? to,
  }) {
    return _buildTransactionsQuery(
      direction: direction,
      type: type,
      from: from,
      to: to,
    ).get();
  }

  /// Watches transactions based on criteria.
  Stream<List<CashboxTransactionEntry>> watchTransactions({
    String? direction,
    String? type,
    DateTime? from,
    DateTime? to,
  }) {
    return _buildTransactionsQuery(
      direction: direction,
      type: type,
      from: from,
      to: to,
    ).watch();
  }

  /// Gets transactions for a specific day/date range.
  Future<List<CashboxTransactionEntry>> getTransactionsBetween(DateTime from, DateTime to) {
    return (select(cashboxTransactions)
          ..where((t) => t.createdAt.isBiggerOrEqualValue(from) & t.createdAt.isSmallerOrEqualValue(to))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  /// Watches transactions for a specific day/date range.
  Stream<List<CashboxTransactionEntry>> watchTransactionsBetween(DateTime from, DateTime to) {
    return (select(cashboxTransactions)
          ..where((t) => t.createdAt.isBiggerOrEqualValue(from) & t.createdAt.isSmallerOrEqualValue(to))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .watch();
  }
}
