import '../../../../core/result/result.dart';
import '../entities/audit_entry.dart';
import '../repositories/audit_log_repository.dart';

final class GetAuditLogsUseCase {
  final AuditLogRepository _repository;

  const GetAuditLogsUseCase(this._repository);

  Future<Result<List<AuditEntry>>> call({
    String? entityType,
    String? action,
    DateTime? from,
    DateTime? to,
    int limit = 100,
  }) {
    return _repository.getAuditLogs(
      entityType: entityType,
      action: action,
      from: from,
      to: to,
      limit: limit,
    );
  }
}
