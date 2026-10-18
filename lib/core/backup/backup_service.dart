import 'dart:io';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart';
import '../result/failures.dart';
import '../result/result.dart';

class BackupService {
  final AppDatabase _db;

  BackupService(this._db);

  /// Returns the current active database file
  Future<File> getDatabaseFile() async {
    final supportDir = await getApplicationSupportDirectory();
    return File(p.join(supportDir.path, 'sales_manager.sqlite'));
  }

  /// Creates a manual backup in a directory selected by the user (or provided path)
  Future<Result<String>> createManualBackup({String? targetDirectory}) async {
    try {
      final dbFile = await getDatabaseFile();
      if (!await dbFile.exists()) {
        return const FailureResult(
          DatabaseFailure(message: 'ملف قاعدة البيانات الحالي غير موجود.'),
        );
      }

      String? destinationDir = targetDirectory;
      destinationDir ??= await FilePicker.getDirectoryPath(
        dialogTitle: 'اختر مجلد حفظ النسخة الاحتياطية',
      );

      if (destinationDir == null) {
        return const FailureResult(
          ValidationFailure(field: 'targetDirectory', message: 'تم إلغاء العملية'),
        );
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final backupFileName = 'backup_$timestamp.sqlite';
      final backupFilePath = p.join(destinationDir, backupFileName);

      final backupFile = await dbFile.copy(backupFilePath);
      final size = await backupFile.length();

      // Record in backups_meta
      await _db.into(_db.backupsMeta).insert(
            BackupsMetaCompanion(
              filePath: Value(backupFilePath),
              createdAt: Value(DateTime.now()),
              sizeBytes: Value(size),
              type: const Value('manual'),
              schemaVersion: Value(_db.schemaVersion),
            ),
          );

      return Success(backupFilePath);
    } catch (e) {
      return FailureResult(
        DatabaseFailure(message: 'فشل إنشاء النسخة الاحتياطية: ${e.toString()}'),
      );
    }
  }

  /// Exports backup to an external storage or USB path
  Future<Result<String>> exportBackupToUsb() async {
    try {
      final dbFile = await getDatabaseFile();
      if (!await dbFile.exists()) {
        return const FailureResult(
          DatabaseFailure(message: 'ملف قاعدة البيانات الحالي غير موجود.'),
        );
      }

      final destinationDir = await FilePicker.getDirectoryPath(
        dialogTitle: 'اختر مسار وحدة التخزين الخارجية (USB)',
      );

      if (destinationDir == null) {
        return const FailureResult(
          ValidationFailure(field: 'destinationDir', message: 'تم إلغاء عملية التصدير'),
        );
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final exportFileName = 'sales_manager_export_$timestamp.sqlite';
      final exportFilePath = p.join(destinationDir, exportFileName);

      final exportedFile = await dbFile.copy(exportFilePath);
      final size = await exportedFile.length();

      await _db.into(_db.backupsMeta).insert(
            BackupsMetaCompanion(
              filePath: Value(exportFilePath),
              createdAt: Value(DateTime.now()),
              sizeBytes: Value(size),
              type: const Value('export'),
              schemaVersion: Value(_db.schemaVersion),
            ),
          );

      return Success(exportFilePath);
    } catch (e) {
      return FailureResult(
        DatabaseFailure(message: 'فشل تصدير النسخة الاحتياطية: ${e.toString()}'),
      );
    }
  }

  /// Creates an automatic backup and enforces the retention policy (e.g. keep last N backups)
  Future<Result<String>> createAutoBackup({int retentionCount = 7}) async {
    try {
      final dbFile = await getDatabaseFile();
      if (!await dbFile.exists()) {
        return const FailureResult(
          DatabaseFailure(message: 'ملف قاعدة البيانات الحالي غير موجود.'),
        );
      }

      final supportDir = await getApplicationSupportDirectory();
      final autoBackupsDir = Directory(p.join(supportDir.path, 'backups'));
      if (!await autoBackupsDir.exists()) {
        await autoBackupsDir.create(recursive: true);
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final backupFileName = 'auto_backup_$timestamp.sqlite';
      final backupFilePath = p.join(autoBackupsDir.path, backupFileName);

      final backupFile = await dbFile.copy(backupFilePath);
      final size = await backupFile.length();

      // Record in backups_meta
      await _db.into(_db.backupsMeta).insert(
            BackupsMetaCompanion(
              filePath: Value(backupFilePath),
              createdAt: Value(DateTime.now()),
              sizeBytes: Value(size),
              type: const Value('auto'),
              schemaVersion: Value(_db.schemaVersion),
            ),
          );

      // Enforce retention policy: delete auto backups older than retentionCount
      await _enforceRetentionPolicy(autoBackupsDir, retentionCount);

      return Success(backupFilePath);
    } catch (e) {
      return FailureResult(
        DatabaseFailure(message: 'فشل النسخ الاحتياطي التلقائي: ${e.toString()}'),
      );
    }
  }

  /// Retains only the most recent [retentionCount] auto-backup files
  Future<void> _enforceRetentionPolicy(Directory dir, int retentionCount) async {
    try {
      final entities = dir.listSync();
      final backupFiles = <File>[];

      for (final entity in entities) {
        if (entity is File && p.basename(entity.path).startsWith('auto_backup_')) {
          backupFiles.add(entity);
        }
      }

      // Sort newest first
      backupFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      // If more than retentionCount, delete the excess older ones
      if (backupFiles.length > retentionCount) {
        for (var i = retentionCount; i < backupFiles.length; i++) {
          try {
            await backupFiles[i].delete();
          } catch (_) {}
        }
      }
    } catch (_) {
      // Non-critical cleanup error
    }
  }

  /// Get backup history from the database
  Future<List<BackupMetaEntry>> getBackupHistory() async {
    final query = _db.select(_db.backupsMeta)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])
      ..limit(100);
    return query.get();
  }
}
