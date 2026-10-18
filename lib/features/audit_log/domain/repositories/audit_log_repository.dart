import '../../../../core/result/result.dart';
import '../entities/audit_entry.dart';

abstract interface class AuditLogRepository {
  Future<Result<List<AuditEntry>>> getAuditLogs({
    String? entityType,
    String? action,
    DateTime? from,
    DateTime? to,
    int limit = 100,
  });

  Stream<List<AuditEntry>> watchRecentAuditLogs({int limit = 50});
}
