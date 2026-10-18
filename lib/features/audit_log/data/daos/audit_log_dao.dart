import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/system_tables.dart';

part 'audit_log_dao.g.dart';

@DriftAccessor(tables: [AuditLog])
class AuditLogDao extends DatabaseAccessor<AppDatabase> with _$AuditLogDaoMixin {
  AuditLogDao(super.db);

  Future<List<AuditLogEntry>> getAuditLogs({
    String? entityType,
    String? action,
    DateTime? from,
    DateTime? to,
    int limit = 100,
  }) {
    final query = select(auditLog);
    if (entityType != null && entityType.isNotEmpty && entityType != 'all') {
      query.where((tbl) => tbl.entityType.equals(entityType));
    }
    if (action != null && action.isNotEmpty && action != 'all') {
      query.where((tbl) => tbl.action.equals(action));
    }
    if (from != null) {
      query.where((tbl) => tbl.performedAt.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      query.where((tbl) => tbl.performedAt.isSmallerOrEqualValue(to));
    }
    query.orderBy([(tbl) => OrderingTerm.desc(tbl.performedAt)]);
    query.limit(limit);
    return query.get();
  }

  Stream<List<AuditLogEntry>> watchRecentAuditLogs({int limit = 50}) {
    final query = select(auditLog)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.performedAt)])
      ..limit(limit);
    return query.watch();
  }

  Future<int> insertEntry(AuditLogCompanion entry) {
    return into(auditLog).insert(entry);
  }
}
