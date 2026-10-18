import '../../../../core/result/result.dart';
import '../repositories/backup_repository.dart';

final class ExportBackupUseCase {
  final BackupRepository _repository;

  const ExportBackupUseCase(this._repository);

  Future<Result<String>> call() {
    return _repository.exportBackupToUsb();
  }
}
