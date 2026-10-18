import '../../../../core/result/result.dart';
import '../repositories/backup_repository.dart';

final class CreateManualBackupUseCase {
  final BackupRepository _repository;

  const CreateManualBackupUseCase(this._repository);

  Future<Result<String>> call() {
    return _repository.createManualBackup();
  }
}
