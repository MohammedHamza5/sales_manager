import '../../../../core/database/app_database.dart';
import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/audit_entry.dart';
import '../../domain/repositories/audit_log_repository.dart';
import '../daos/audit_log_dao.dart';

final class AuditLogRepositoryImpl implements AuditLogRepository {
  final AuditLogDao _dao;

  const AuditLogRepositoryImpl(this._dao);

  @override
  Future<Result<List<AuditEntry>>> getAuditLogs({
    String? entityType,
    String? action,
    DateTime? from,
    DateTime? to,
    int limit = 100,
  }) async {
    try {
      final rows = await _dao.getAuditLogs(
        entityType: entityType,
        action: action,
        from: from,
        to: to,
        limit: limit,
      );
      final entries = rows.map(_toDomain).toList();
      return Success(entries);
    } catch (e) {
      return FailureResult(
        DatabaseFailure(message: 'فشل في جلب سجل العمليات: ${e.toString()}'),
      );
    }
  }

  @override
  Stream<List<AuditEntry>> watchRecentAuditLogs({int limit = 50}) {
    return _dao
        .watchRecentAuditLogs(limit: limit)
        .map((rows) => rows.map(_toDomain).toList());
  }

  AuditEntry _toDomain(AuditLogEntry row) {
    return AuditEntry(
      id: row.id,
      entityType: row.entityType,
      entityId: row.entityId,
      action: row.action,
      payloadBefore: row.payloadBefore,
      payloadAfter: row.payloadAfter,
      performedAt: row.performedAt,
      note: row.note,
      userId: row.userId,
    );
  }
}
