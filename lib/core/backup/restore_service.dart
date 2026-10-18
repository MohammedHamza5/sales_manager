import 'dart:io';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart';
import '../result/failures.dart';
import '../result/result.dart';

class RestoreService {
  final AppDatabase _db;

  RestoreService(this._db);

  /// Validates that a file is a genuine SQLite database
  Future<Result<void>> validateBackupFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return const FailureResult(ValidationFailure(field: 'backupFilePath', message: 'ملف النسخة الاحتياطية غير موجود.'));
    }

    final length = await file.length();
    if (length < 100) {
      return const FailureResult(
        ValidationFailure(field: 'backupFilePath', message: 'ملف النسخة الاحتياطية فارغ أو تالف.'),
      );
    }

    // Verify SQLite header (First 16 bytes = "SQLite format 3\000")
    try {
      final raf = await file.open(mode: FileMode.read);
      final headerBytes = await raf.read(16);
      await raf.close();

      final headerString = String.fromCharCodes(headerBytes);
      if (!headerString.startsWith('SQLite format 3')) {
        return const FailureResult(
          ValidationFailure(field: 'backupFilePath', message: 'الملف المختار ليس قاعدة بيانات SQLite صالحة.'),
        );
      }
    } catch (e) {
      return FailureResult(
        ValidationFailure(field: 'backupFilePath', message: 'تعذر قراءة ملف النسخة الاحتياطية: ${e.toString()}'),
      );
    }

    return const Success(null);
  }

  /// Restores a backup file with a mandatory safety backup taken first
  Future<Result<String>> restoreBackup(String backupFilePath) async {
    try {
      // 1. Validate file
      final validationResult = await validateBackupFile(backupFilePath);
      if (validationResult is FailureResult) {
        return FailureResult(validationResult.failureOrNull!);
      }

      final supportDir = await getApplicationSupportDirectory();
      final activeDbFile = File(p.join(supportDir.path, 'sales_manager.sqlite'));

      // 2. Take precautionary safety backup of active database if it exists
      String? safetyPath;
      if (await activeDbFile.exists()) {
        final backupsDir = Directory(p.join(supportDir.path, 'backups'));
        if (!await backupsDir.exists()) {
          await backupsDir.create(recursive: true);
        }

        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        safetyPath = p.join(backupsDir.path, 'safety_pre_restore_$timestamp.sqlite');
        final safetyFile = await activeDbFile.copy(safetyPath);
        final size = await safetyFile.length();

        // Record safety backup
        try {
          await _db.into(_db.backupsMeta).insert(
                BackupsMetaCompanion(
                  filePath: Value(safetyPath),
                  createdAt: Value(DateTime.now()),
                  sizeBytes: Value(size),
                  type: const Value('safety'),
                  schemaVersion: Value(_db.schemaVersion),
                ),
              );
        } catch (_) {}
      }

      // 3. Close the active database connection
      await _db.close();

      // Small pause to allow file locks to release
      await Future<void>.delayed(const Duration(milliseconds: 250));

      // 4. Overwrite active database file with backup file
      final backupSource = File(backupFilePath);
      await backupSource.copy(activeDbFile.path);

      return Success(
        safetyPath != null
            ? 'تمت الاستعادة بنجاح. تم حفظ نسخة أمان احترازية في:\n$safetyPath'
            : 'تمت استعادة النسخة الاحتياطية بنجاح.',
      );
    } catch (e) {
      return FailureResult(
        DatabaseFailure(message: 'فشل استعادة النسخة الاحتياطية: ${e.toString()}'),
      );
    }
  }
}
