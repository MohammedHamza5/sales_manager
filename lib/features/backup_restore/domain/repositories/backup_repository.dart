import '../../../../core/result/result.dart';
import '../entities/backup_info.dart';

abstract interface class BackupRepository {
  Future<Result<String>> createManualBackup();
  Future<Result<String>> exportBackupToUsb();
  Future<Result<String>> createAutoBackup({int retentionCount = 7});
  Future<Result<String>> restoreBackup(String backupFilePath);
  Future<Result<List<BackupInfo>>> getBackupHistory();
  Future<Result<bool>> isAutoBackupEnabled();
  Future<Result<void>> setAutoBackupEnabled(bool enabled);
  Future<Result<int>> getAutoBackupRetentionCount();
  Future<Result<void>> setAutoBackupRetentionCount(int count);
}
