import '../../../../core/result/result.dart';
import '../entities/backup_info.dart';
import '../repositories/backup_repository.dart';

final class GetBackupHistoryUseCase {
  final BackupRepository _repository;

  const GetBackupHistoryUseCase(this._repository);

  Future<Result<List<BackupInfo>>> call() {
    return _repository.getBackupHistory();
  }
}
