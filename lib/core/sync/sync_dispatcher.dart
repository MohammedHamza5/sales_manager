import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/daos/sync_queue_dao.dart';

class SyncDispatcher {
  final SyncQueueDao _syncQueueDao;
  final AppDatabase? _db;
  static const Uuid _uuid = Uuid();
  static String deviceId = 'pos_main';

  SyncDispatcher({
    required SyncQueueDao syncQueueDao,
    AppDatabase? db,
  })  : _syncQueueDao = syncQueueDao,
        _db = db;

  /// Generates a deterministic UUIDv5 for any local integer ID.
  /// Guarantees 0 collisions across devices while preserving foreign keys.
  static String getEntityUuid(String entityType, int localId) {
    return _uuid.v5(Namespace.url.value, '$deviceId:$entityType:$localId');
  }

  /// Resolves the cloud UUID for an entity.
  /// If mapped in SQLite entity_cloud_mappings, uses the recorded cloud UUID.
  /// Otherwise generates deterministic UUIDv5 and saves the mapping.
  Future<String> resolveUuid(String entityType, int localId) async {
    if (_db != null) {
      try {
        final rows = await _db.customSelect(
          'SELECT cloud_uuid FROM entity_cloud_mappings WHERE entity_type = ? AND local_id = ? LIMIT 1',
          variables: [Variable.withString(entityType), Variable.withInt(localId)],
        ).get();

        if (rows.isNotEmpty) {
          return rows.first.read<String>('cloud_uuid');
        }
      } catch (_) {
        // Fallback to deterministic generation if mapping table not ready
      }
    }

    final generatedUuid = getEntityUuid(entityType, localId);
    if (_db != null) {
      await saveMapping(entityType, localId, generatedUuid);
    }
    return generatedUuid;
  }

  /// Saves a bi-directional mapping between local entity ID and cloud UUID.
  Future<void> saveMapping(String entityType, int localId, String cloudUuid) async {
    if (_db == null) return;
    try {
      await _db.customInsert(
        'INSERT OR REPLACE INTO entity_cloud_mappings (entity_type, local_id, cloud_uuid) VALUES (?, ?, ?)',
        variables: [
          Variable.withString(entityType),
          Variable.withInt(localId),
          Variable.withString(cloudUuid),
        ],
      );
    } catch (_) {
      // Ignored non-fatal mapping error
    }
  }

  /// Finds the local entity ID for a given cloud UUID.
  Future<int?> getLocalId(String entityType, String cloudUuid) async {
    if (_db == null) return null;
    try {
      final rows = await _db.customSelect(
        'SELECT local_id FROM entity_cloud_mappings WHERE entity_type = ? AND cloud_uuid = ? LIMIT 1',
        variables: [Variable.withString(entityType), Variable.withString(cloudUuid)],
      ).get();

      if (rows.isNotEmpty) {
        return rows.first.read<int>('local_id');
      }
    } catch (_) {
      // Ignored
    }
    return null;
  }

  Future<void> dispatchInsert({
    required String entityType,
    required int localId,
    required Map<String, dynamic> data,
  }) async {
    final entityUuid = await resolveUuid(entityType, localId);
    final payload = Map<String, dynamic>.from(data);
    payload['id'] = entityUuid;
    payload['device_id'] = deviceId;

    await _syncQueueDao.enqueue(
      entityType: entityType,
      entityUuid: entityUuid,
      action: 'insert',
      payload: jsonEncode(payload),
    );
  }

  Future<void> dispatchUpdate({
    required String entityType,
    required int localId,
    required Map<String, dynamic> data,
  }) async {
    final entityUuid = await resolveUuid(entityType, localId);
    final payload = Map<String, dynamic>.from(data);
    payload['device_id'] = deviceId;

    await _syncQueueDao.enqueue(
      entityType: entityType,
      entityUuid: entityUuid,
      action: 'update',
      payload: jsonEncode(payload),
    );
  }

  Future<void> dispatchDelete({
    required String entityType,
    required int localId,
  }) async {
    final entityUuid = await resolveUuid(entityType, localId);

    await _syncQueueDao.enqueue(
      entityType: entityType,
      entityUuid: entityUuid,
      action: 'delete',
      payload: jsonEncode({'id': entityUuid}),
    );
  }
}
