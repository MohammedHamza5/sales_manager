import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/backup/backup_service.dart';
import 'package:sales_manager/core/backup/restore_service.dart';
import 'package:sales_manager/core/database/app_database.dart';
import 'package:sales_manager/core/result/result.dart';
import 'package:sales_manager/features/backup_restore/data/repositories/backup_repository_impl.dart';

class MockBackupService extends Mock implements BackupService {}
class MockRestoreService extends Mock implements RestoreService {}

void main() {
  late AppDatabase db;
  late MockBackupService mockBackupService;
  late MockRestoreService mockRestoreService;
  late BackupRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.memory();
    mockBackupService = MockBackupService();
    mockRestoreService = MockRestoreService();
    repository = BackupRepositoryImpl(
      db: db,
      backupService: mockBackupService,
      restoreService: mockRestoreService,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('BackupRepositoryImpl Integration & Settings Tests', () {
    test('isAutoBackupEnabled defaults to true and updates correctly in db', () async {
      // Default
      final defaultResult = await repository.isAutoBackupEnabled();
      expect(defaultResult, isA<Success<bool>>());
      expect((defaultResult as Success<bool>).data, isTrue);

      // Disable
      final disableResult = await repository.setAutoBackupEnabled(false);
      expect(disableResult, isA<Success<void>>());

      // Check updated
      final updatedResult = await repository.isAutoBackupEnabled();
      expect((updatedResult as Success<bool>).data, isFalse);

      // Re-enable
      await repository.setAutoBackupEnabled(true);
      final reenabledResult = await repository.isAutoBackupEnabled();
      expect((reenabledResult as Success<bool>).data, isTrue);
    });

    test('getAutoBackupRetentionCount defaults to 7 and updates correctly in db', () async {
      // Default
      final defaultRetention = await repository.getAutoBackupRetentionCount();
      expect(defaultRetention, isA<Success<int>>());
      expect((defaultRetention as Success<int>).data, 7);

      // Update to 14
      final updateResult = await repository.setAutoBackupRetentionCount(14);
      expect(updateResult, isA<Success<void>>());

      // Check updated
      final updatedRetention = await repository.getAutoBackupRetentionCount();
      expect((updatedRetention as Success<int>).data, 14);
    });

    test('createManualBackup delegates to BackupService', () async {
      when(() => mockBackupService.createManualBackup())
          .thenAnswer((_) async => const Success('C:/backups/backup.sqlite'));

      final result = await repository.createManualBackup();
      expect(result, isA<Success<String>>());
      expect((result as Success<String>).data, 'C:/backups/backup.sqlite');
      verify(() => mockBackupService.createManualBackup()).called(1);
    });

    test('restoreBackup delegates to RestoreService', () async {
      when(() => mockRestoreService.restoreBackup('C:/backups/backup.sqlite'))
          .thenAnswer((_) async => const Success('تمت الاستعادة بنجاح'));

      final result = await repository.restoreBackup('C:/backups/backup.sqlite');
      expect(result, isA<Success<String>>());
      verify(() => mockRestoreService.restoreBackup('C:/backups/backup.sqlite')).called(1);
    });
  });
}
