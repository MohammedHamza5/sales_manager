import '../../../../core/result/result.dart';
import '../repositories/backup_repository.dart';

final class CreateAutoBackupUseCase {
  final BackupRepository _repository;

  const CreateAutoBackupUseCase(this._repository);

  Future<Result<String>> call({int retentionCount = 7}) {
    return _repository.createAutoBackup(retentionCount: retentionCount);
  }
}
