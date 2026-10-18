import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sync_tables.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [SyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  Future<int> enqueue({
    required String entityType,
    required String entityUuid,
    required String action,
    required String payload,
  }) {
    return into(syncQueue).insert(
      SyncQueueCompanion.insert(
        entityType: entityType,
        entityUuid: entityUuid,
        action: action,
        payload: payload,
      ),
    );
  }

  Future<List<SyncQueueEntry>> getPendingEntries({int limit = 50}) {
    return (select(syncQueue)
          ..where((tbl) =>
              (tbl.status.equals('pending') | tbl.status.equals('failed')) &
              tbl.retryCount.isSmallerThan(const Constant(5)))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)])
          ..limit(limit))
        .get();
  }

  Stream<int> watchPendingCount() {
    final count = syncQueue.id.count();
    final query = selectOnly(syncQueue)
      ..addColumns([count])
      ..where((syncQueue.status.equals('pending') |
              syncQueue.status.equals('failed')) &
          syncQueue.retryCount.isSmallerThan(const Constant(5)));
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }

  Future<void> markAsSyncing(int id) {
    return (update(syncQueue)..where((tbl) => tbl.id.equals(id))).write(
      const SyncQueueCompanion(status: Value('syncing')),
    );
  }

  Future<void> markAsPending(int id) {
    return (update(syncQueue)..where((tbl) => tbl.id.equals(id))).write(
      const SyncQueueCompanion(status: Value('pending')),
    );
  }

  Future<void> resetSyncingEntries() {
    return (update(syncQueue)..where((tbl) => tbl.status.equals('syncing'))).write(
      const SyncQueueCompanion(status: Value('pending')),
    );
  }

  Future<void> markAsSynced(int id, DateTime syncedAt) {
    return (update(syncQueue)..where((tbl) => tbl.id.equals(id))).write(
      SyncQueueCompanion(
        status: const Value('synced'),
        syncedAt: Value(syncedAt),
        errorMessage: const Value(null),
      ),
    );
  }

  Future<void> markAsFailed(int id, String error, int currentRetry) {
    return (update(syncQueue)..where((tbl) => tbl.id.equals(id))).write(
      SyncQueueCompanion(
        status: const Value('failed'),
        retryCount: Value(currentRetry + 1),
        errorMessage: Value(error),
      ),
    );
  }

  Future<int> clearSyncedEntries() {
    return (delete(syncQueue)..where((tbl) => tbl.status.equals('synced'))).go();
  }
}
