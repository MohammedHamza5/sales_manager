import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_manager/core/database/app_database.dart';
import 'package:sales_manager/core/result/result.dart';
import 'package:sales_manager/features/audit_log/data/repositories/audit_log_repository_impl.dart';
import 'package:sales_manager/features/audit_log/domain/entities/audit_entry.dart';

void main() {
  late AppDatabase db;
  late AuditLogRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.memory();
    repository = AuditLogRepositoryImpl(db.auditLogDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('AuditLogRepositoryImpl Integration Tests', () {
    test('getAuditLogs retrieves entries with entityType and action filters', () async {
      final now = DateTime.now();

      // Insert audit entries
      await db.auditLogDao.insertEntry(
        AuditLogCompanion.insert(
          entityType: 'sale',
          entityId: 101,
          action: 'create',
          payloadAfter: const Value('{"invoiceNo": 1}'),
          performedAt: Value(now.subtract(const Duration(minutes: 5))),
        ),
      );

      await db.auditLogDao.insertEntry(
        AuditLogCompanion.insert(
          entityType: 'sale',
          entityId: 101,
          action: 'reverse',
          payloadBefore: const Value('{"invoiceNo": 1}'),
          payloadAfter: const Value('{"status": "reversed"}'),
          performedAt: Value(now.subtract(const Duration(minutes: 2))),
        ),
      );

      await db.auditLogDao.insertEntry(
        AuditLogCompanion.insert(
          entityType: 'customer',
          entityId: 5,
          action: 'create',
          payloadAfter: const Value('{"name": "عميل"}'),
          performedAt: Value(now),
        ),
      );

      // 1. Fetch all
      final allResult = await repository.getAuditLogs();
      expect(allResult, isA<Success<List<AuditEntry>>>());
      final allEntries = (allResult as Success<List<AuditEntry>>).data;
      expect(allEntries.length, 3);

      // 2. Filter by entityType 'sale'
      final salesResult = await repository.getAuditLogs(entityType: 'sale');
      final salesEntries = (salesResult as Success<List<AuditEntry>>).data;
      expect(salesEntries.length, 2);
      expect(salesEntries.every((e) => e.entityType == 'sale'), isTrue);

      // 3. Filter by action 'reverse'
      final reverseResult = await repository.getAuditLogs(action: 'reverse');
      final reverseEntries = (reverseResult as Success<List<AuditEntry>>).data;
      expect(reverseEntries.length, 1);
      expect(reverseEntries.first.action, 'reverse');
      expect(reverseEntries.first.entityId, 101);
    });

    test('watchRecentAuditLogs streams audit log entries ordered descending', () async {
      await db.auditLogDao.insertEntry(
        AuditLogCompanion.insert(
          entityType: 'expense',
          entityId: 20,
          action: 'create',
          payloadAfter: const Value('{"amount": 5000}'),
        ),
      );

      final list = await repository.watchRecentAuditLogs(limit: 10).first;
      expect(list.length, 1);
      expect(list.first.entityType, 'expense');
      expect(list.first.entityId, 20);
    });
  });
}
