import '../entities/audit_entry.dart';
import '../repositories/audit_log_repository.dart';

final class WatchAuditLogsUseCase {
  final AuditLogRepository _repository;

  const WatchAuditLogsUseCase(this._repository);

  Stream<List<AuditEntry>> call({int limit = 50}) {
    return _repository.watchRecentAuditLogs(limit: limit);
  }
}
