import '../../../../core/result/result.dart';
import '../repositories/backup_repository.dart';

final class ManageBackupSettingsUseCase {
  final BackupRepository _repository;

  const ManageBackupSettingsUseCase(this._repository);

  Future<Result<bool>> isAutoBackupEnabled() => _repository.isAutoBackupEnabled();

  Future<Result<void>> setAutoBackupEnabled(bool enabled) =>
      _repository.setAutoBackupEnabled(enabled);

  Future<Result<int>> getAutoBackupRetentionCount() =>
      _repository.getAutoBackupRetentionCount();

  Future<Result<void>> setAutoBackupRetentionCount(int count) =>
      _repository.setAutoBackupRetentionCount(count);
}
