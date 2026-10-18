import 'package:drift/drift.dart';
import '../../../../core/backup/backup_service.dart';
import '../../../../core/backup/restore_service.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/backup_info.dart';
import '../../domain/repositories/backup_repository.dart';

final class BackupRepositoryImpl implements BackupRepository {
  final AppDatabase _db;
  final BackupService _backupService;
  final RestoreService _restoreService;

  const BackupRepositoryImpl({
    required AppDatabase db,
    required BackupService backupService,
    required RestoreService restoreService,
  })  : _db = db,
        _backupService = backupService,
        _restoreService = restoreService;

  @override
  Future<Result<String>> createManualBackup() {
    return _backupService.createManualBackup();
  }

  @override
  Future<Result<String>> exportBackupToUsb() {
    return _backupService.exportBackupToUsb();
  }

  @override
  Future<Result<String>> createAutoBackup({int retentionCount = 7}) {
    return _backupService.createAutoBackup(retentionCount: retentionCount);
  }

  @override
  Future<Result<String>> restoreBackup(String backupFilePath) {
    return _restoreService.restoreBackup(backupFilePath);
  }

  @override
  Future<Result<List<BackupInfo>>> getBackupHistory() async {
    try {
      final rows = await _backupService.getBackupHistory();
      final list = rows
          .map(
            (r) => BackupInfo(
              id: r.id,
              filePath: r.filePath,
              createdAt: r.createdAt,
              sizeBytes: r.sizeBytes,
              type: r.type,
              schemaVersion: r.schemaVersion,
            ),
          )
          .toList();
      return Success(list);
    } catch (e) {
      return FailureResult(
        DatabaseFailure(message: 'فشل في جلب سجل النسخ الاحتياطية: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<bool>> isAutoBackupEnabled() async {
    try {
      final entry = await (_db.select(_db.settings)
            ..where((tbl) => tbl.key.equals('auto_backup_enabled')))
          .getSingleOrNull();
      if (entry == null) {
        return const Success(true); // default true
      }
      return Success(entry.value.toLowerCase() == 'true');
    } catch (e) {
      return FailureResult(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> setAutoBackupEnabled(bool enabled) async {
    try {
      await _db.into(_db.settings).insertOnConflictUpdate(
            SettingsCompanion(
              key: const Value('auto_backup_enabled'),
              value: Value(enabled.toString()),
              updatedAt: Value(DateTime.now()),
            ),
          );
      return const Success(null);
    } catch (e) {
      return FailureResult(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<int>> getAutoBackupRetentionCount() async {
    try {
      final entry = await (_db.select(_db.settings)
            ..where((tbl) => tbl.key.equals('auto_backup_retention')))
          .getSingleOrNull();
      if (entry == null) {
        return const Success(7); // default 7
      }
      return Success(int.tryParse(entry.value) ?? 7);
    } catch (e) {
      return FailureResult(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> setAutoBackupRetentionCount(int count) async {
    try {
      await _db.into(_db.settings).insertOnConflictUpdate(
            SettingsCompanion(
              key: const Value('auto_backup_retention'),
              value: Value(count.toString()),
              updatedAt: Value(DateTime.now()),
            ),
          );
      return const Success(null);
    } catch (e) {
      return FailureResult(DatabaseFailure(message: e.toString()));
    }
  }
}
