import '../../../../core/result/result.dart';
import '../repositories/backup_repository.dart';

final class RestoreBackupUseCase {
  final BackupRepository _repository;

  const RestoreBackupUseCase(this._repository);

  Future<Result<String>> call(String backupFilePath) {
    return _repository.restoreBackup(backupFilePath);
  }
}
