import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import '../config/supabase_config.dart';
import '../database/app_database.dart';
import '../database/daos/sync_queue_dao.dart';
import '../network/network_info.dart';
import 'sync_dispatcher.dart';

enum SyncStatus { idle, syncing, success, error, offline }

class SyncState {
  final SyncStatus status;
  final int pendingCount;
  final DateTime? lastSyncedAt;
  final String? errorMessage;

  const SyncState({
    required this.status,
    required this.pendingCount,
    this.lastSyncedAt,
    this.errorMessage,
  });

  SyncState copyWith({
    SyncStatus? status,
    int? pendingCount,
    DateTime? lastSyncedAt,
    String? errorMessage,
  }) {
    return SyncState(
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SyncService {
  final AppDatabase _db;
  final SyncQueueDao _syncQueueDao;
  final NetworkInfo _networkInfo;
  final SyncDispatcher _syncDispatcher;

  final _syncStateController = StreamController<SyncState>.broadcast();
  Stream<SyncState> get syncStateStream => _syncStateController.stream;

  SyncState _currentState = const SyncState(
    status: SyncStatus.idle,
    pendingCount: 0,
  );
  SyncState get currentState => _currentState;

  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<int>? _pendingQueueSubscription;
  bool _isSyncing = false;

  SyncService({
    required AppDatabase db,
    required SyncQueueDao syncQueueDao,
    required NetworkInfo networkInfo,
    SyncDispatcher? syncDispatcher,
  })  : _db = db,
        _syncQueueDao = syncQueueDao,
        _networkInfo = networkInfo,
        _syncDispatcher = syncDispatcher ??
            SyncDispatcher(syncQueueDao: syncQueueDao, db: db);

  Future<void> initialize() async {
    // 0. Recover any interrupted entries from previous app crashes
    try {
      await _syncQueueDao.resetSyncingEntries();
    } catch (_) {}

    // 1. Watch pending queue count in real-time
    _pendingQueueSubscription = _syncQueueDao.watchPendingCount().listen((count) {
      _updateState(_currentState.copyWith(pendingCount: count));
      
      // Auto-trigger sync when there are pending items and we're not already syncing
      if (count > 0 && !_isSyncing) {
        unawaited(syncNow());
      }
    });

    // 2. Listen to network changes (Offline -> Online)
    _connectivitySubscription = _networkInfo.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        unawaited(syncNow());
      } else {
        _updateState(_currentState.copyWith(status: SyncStatus.offline));
      }
    });

    // Initial sync check
    unawaited(syncNow());
  }

  void _updateState(SyncState newState) {
    _currentState = newState;
    _syncStateController.add(newState);
  }

  bool _isNetworkError(Object error) {
    if (error is SocketException ||
        error is TimeoutException ||
        error is HttpException) {
      return true;
    }
    final str = error.toString().toLowerCase();
    return str.contains('socketexception') ||
        str.contains('connection refused') ||
        str.contains('failed host lookup') ||
        str.contains('network is unreachable') ||
        str.contains('handshakeexception') ||
        str.contains('clientexception') ||
        str.contains('connection closed') ||
        str.contains('connection reset') ||
        str.contains('timed out');
  }

  /// Triggers full sync (Push local mutations -> Pull cloud updates)
  Future<void> syncNow() async {
    if (_isSyncing) return;

    final isOnline = await _networkInfo.isConnected;
    if (!isOnline) {
      _updateState(_currentState.copyWith(status: SyncStatus.offline));
      return;
    }

    _isSyncing = true;
    _updateState(_currentState.copyWith(status: SyncStatus.syncing));

    try {
      // Step 1: Push pending mutations from Outbox
      await _pushPendingMutations();

      // Step 2: Pull latest changes from Supabase
      await _pullLatestChanges();

      final now = DateTime.now();
      _updateState(_currentState.copyWith(
        status: SyncStatus.success,
        lastSyncedAt: now,
        errorMessage: null,
      ));
    } catch (e) {
      _updateState(_currentState.copyWith(
        status: _isNetworkError(e) ? SyncStatus.offline : SyncStatus.error,
        errorMessage: e.toString(),
      ));
    } finally {
      _isSyncing = false;
    }
  }

  /// Pushes records from Drift sync_queue to Supabase in topological dependency order
  Future<void> _pushPendingMutations() async {
    final client = SupabaseConfig.client;

    while (true) {
      final entries = await _syncQueueDao.getPendingEntries(limit: 50);
      if (entries.isEmpty) break;

      var processedInBatch = 0;

      for (final entry in entries) {
        if (entry.retryCount >= 5) {
          continue;
        }

        processedInBatch++;
        await _syncQueueDao.markAsSyncing(entry.id);

        try {
          final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
          final tableName = _resolveTableName(entry.entityType);

          switch (entry.action.toLowerCase()) {
            case 'insert':
            case 'upsert':
              await client.from(tableName).upsert(payload);
              break;
            case 'update':
              await client
                  .from(tableName)
                  .update(payload)
                  .eq('id', entry.entityUuid);
              break;
            case 'delete':
              await client
                  .from(tableName)
                  .delete()
                  .eq('id', entry.entityUuid);
              break;
          }

          await _syncQueueDao.markAsSynced(entry.id, DateTime.now());
        } catch (e) {
          if (_isNetworkError(e)) {
            // Revert back to pending so transient network errors don't poison entries
            await _syncQueueDao.markAsPending(entry.id);
            rethrow;
          } else {
            await _syncQueueDao.markAsFailed(
              entry.id,
              e.toString(),
              entry.retryCount,
            );
          }
        }
      }

      if (processedInBatch == 0) {
        break;
      }
    }

    // Clean up successfully synced queue entries to keep local SQLite lightweight
    await _syncQueueDao.clearSyncedEntries();
  }

  /// Pulls newly modified records from Supabase since last sync timestamp
  Future<void> _pullLatestChanges() async {
    final client = SupabaseConfig.client;

    // Fetch server time for clock-skew immunity
    DateTime serverNow;
    try {
      final dynamic res = await client.rpc<dynamic>('get_server_time');
      serverNow = DateTime.parse(res.toString());
    } catch (_) {
      serverNow = DateTime.now().toUtc();
    }

    final setting = await (_db.select(_db.settings)
          ..where((tbl) => tbl.key.equals('last_cloud_sync_at')))
        .getSingleOrNull();

    final lastSyncTime = setting != null ? DateTime.tryParse(setting.value) : null;
    
    // Safety 5-minute overlap window to prevent missing any in-flight commits
    final effectiveSince = lastSyncTime?.subtract(const Duration(minutes: 5));

    // 1. Pull products updates
    await _pullTableChanges(
      tableName: 'products',
      sinceTime: effectiveSince,
      onRecordReceived: _mergeProduct,
    );

    // 2. Pull customers updates
    await _pullTableChanges(
      tableName: 'customers',
      sinceTime: effectiveSince,
      onRecordReceived: _mergeCustomer,
    );

    // 3. Pull suppliers updates
    await _pullTableChanges(
      tableName: 'suppliers',
      sinceTime: effectiveSince,
      onRecordReceived: _mergeSupplier,
    );

    // 4. Pull expenses updates
    await _pullTableChanges(
      tableName: 'expenses',
      sinceTime: effectiveSince,
      onRecordReceived: _mergeExpense,
    );

    // Save latest sync timestamp based on server time
    await _db.into(_db.settings).insertOnConflictUpdate(
          SettingsCompanion.insert(
            key: 'last_cloud_sync_at',
            value: serverNow.toIso8601String(),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> _pullTableChanges({
    required String tableName,
    required DateTime? sinceTime,
    required Future<void> Function(Map<String, dynamic> row) onRecordReceived,
  }) async {
    try {
      final client = SupabaseConfig.client;
      var query = client.from(tableName).select();

      if (sinceTime != null) {
        query = query.gt('updated_at', sinceTime.toIso8601String());
      }

      final records = await query;
      for (final record in records) {
        await onRecordReceived(record);
      }
    } catch (e) {
      if (_isNetworkError(e)) {
        rethrow;
      }
      // Non-blocking pull error for individual table data mismatch
    }
  }

  /// Safely merges a product pulled from the cloud into Drift DB
  Future<void> _mergeProduct(Map<String, dynamic> row) async {
    // Skip if change originated from this device to prevent circular overwrite
    if (row['device_id'] == SyncDispatcher.deviceId) return;

    final cloudId = row['id'] as String?;
    final code = row['code'] as String?;
    final name = (row['name'] as String?) ?? '';
    final unit = (row['unit'] as String?) ?? 'قطعة';
    final currentSalePrice = (row['current_sale_price'] as num?)?.toInt() ?? 0;
    final currentPurchasePrice = (row['current_purchase_price'] as num?)?.toInt() ?? 0;
    final currentQuantity = Decimal.parse((row['current_quantity'] ?? 0).toString());
    final lowStockThreshold = row['low_stock_threshold'] != null
        ? Decimal.parse(row['low_stock_threshold'].toString())
        : null;
    final isActive = (row['is_active'] as bool?) ?? true;

    ProductEntry? existing;
    if (cloudId != null) {
      final localId = await _syncDispatcher.getLocalId('product', cloudId);
      if (localId != null) {
        existing = await (_db.select(_db.products)
              ..where((tbl) => tbl.id.equals(localId)))
            .getSingleOrNull();
      }
    }

    if (existing == null && code != null && code.isNotEmpty) {
      existing = await (_db.select(_db.products)
            ..where((tbl) => tbl.code.equals(code)))
          .getSingleOrNull();
    }
    existing ??= await (_db.select(_db.products)
          ..where((tbl) => tbl.name.equals(name)))
        .getSingleOrNull();

    if (existing != null) {
      await (_db.update(_db.products)..where((tbl) => tbl.id.equals(existing!.id))).write(
        ProductsCompanion(
          name: Value(name),
          code: Value(code),
          unit: Value(unit),
          currentSalePrice: Value(currentSalePrice),
          currentPurchasePrice: Value(currentPurchasePrice),
          currentQuantity: Value(currentQuantity),
          lowStockThreshold: Value(lowStockThreshold),
          isActive: Value(isActive),
        ),
      );
      if (cloudId != null) {
        await _syncDispatcher.saveMapping('product', existing.id, cloudId);
      }
    } else {
      final newId = await _db.into(_db.products).insert(
        ProductsCompanion.insert(
          name: name,
          code: Value(code),
          unit: unit,
          currentSalePrice: currentSalePrice,
          currentPurchasePrice: currentPurchasePrice,
          currentQuantity: Value(currentQuantity),
          lowStockThreshold: Value(lowStockThreshold),
          isActive: Value(isActive),
        ),
      );
      if (cloudId != null) {
        await _syncDispatcher.saveMapping('product', newId, cloudId);
      }
    }
  }

  /// Safely merges a customer pulled from the cloud into Drift DB
  Future<void> _mergeCustomer(Map<String, dynamic> row) async {
    if (row['device_id'] == SyncDispatcher.deviceId) return;

    final cloudId = row['id'] as String?;
    final name = (row['name'] as String?) ?? '';
    final phone = row['phone'] as String?;
    final address = row['address'] as String?;
    final notes = row['notes'] as String?;
    final currentBalance = (row['current_balance'] as num?)?.toInt() ?? 0;
    final isActive = (row['is_active'] as bool?) ?? true;

    CustomerEntry? existing;
    if (cloudId != null) {
      final localId = await _syncDispatcher.getLocalId('customer', cloudId);
      if (localId != null) {
        existing = await (_db.select(_db.customers)
              ..where((tbl) => tbl.id.equals(localId)))
            .getSingleOrNull();
      }
    }

    if (existing == null && phone != null && phone.isNotEmpty) {
      existing = await (_db.select(_db.customers)
            ..where((tbl) => tbl.phone.equals(phone)))
          .getSingleOrNull();
    }
    existing ??= await (_db.select(_db.customers)
          ..where((tbl) => tbl.name.equals(name)))
        .getSingleOrNull();

    if (existing != null) {
      await (_db.update(_db.customers)..where((tbl) => tbl.id.equals(existing!.id))).write(
        CustomersCompanion(
          name: Value(name),
          phone: Value(phone),
          address: Value(address),
          notes: Value(notes),
          currentBalance: Value(currentBalance),
          isActive: Value(isActive),
        ),
      );
      if (cloudId != null) {
        await _syncDispatcher.saveMapping('customer', existing.id, cloudId);
      }
    } else {
      final newId = await _db.into(_db.customers).insert(
        CustomersCompanion.insert(
          name: name,
          phone: Value(phone),
          address: Value(address),
          notes: Value(notes),
          currentBalance: Value(currentBalance),
          isActive: Value(isActive),
        ),
      );
      if (cloudId != null) {
        await _syncDispatcher.saveMapping('customer', newId, cloudId);
      }
    }
  }

  /// Safely merges a supplier pulled from the cloud into Drift DB
  Future<void> _mergeSupplier(Map<String, dynamic> row) async {
    if (row['device_id'] == SyncDispatcher.deviceId) return;

    final cloudId = row['id'] as String?;
    final name = (row['name'] as String?) ?? '';
    final phone = row['phone'] as String?;
    final address = row['address'] as String?;
    final notes = row['notes'] as String?;
    final currentBalance = (row['current_balance'] as num?)?.toInt() ?? 0;
    final isActive = (row['is_active'] as bool?) ?? true;

    SupplierEntry? existing;
    if (cloudId != null) {
      final localId = await _syncDispatcher.getLocalId('supplier', cloudId);
      if (localId != null) {
        existing = await (_db.select(_db.suppliers)
              ..where((tbl) => tbl.id.equals(localId)))
            .getSingleOrNull();
      }
    }

    if (existing == null && phone != null && phone.isNotEmpty) {
      existing = await (_db.select(_db.suppliers)
            ..where((tbl) => tbl.phone.equals(phone)))
          .getSingleOrNull();
    }
    existing ??= await (_db.select(_db.suppliers)
          ..where((tbl) => tbl.name.equals(name)))
        .getSingleOrNull();

    if (existing != null) {
      await (_db.update(_db.suppliers)..where((tbl) => tbl.id.equals(existing!.id))).write(
        SuppliersCompanion(
          name: Value(name),
          phone: Value(phone),
          address: Value(address),
          notes: Value(notes),
          currentBalance: Value(currentBalance),
          isActive: Value(isActive),
        ),
      );
      if (cloudId != null) {
        await _syncDispatcher.saveMapping('supplier', existing.id, cloudId);
      }
    } else {
      final newId = await _db.into(_db.suppliers).insert(
        SuppliersCompanion.insert(
          name: name,
          phone: Value(phone),
          address: Value(address),
          notes: Value(notes),
          currentBalance: Value(currentBalance),
          isActive: Value(isActive),
        ),
      );
      if (cloudId != null) {
        await _syncDispatcher.saveMapping('supplier', newId, cloudId);
      }
    }
  }

  /// Safely merges an expense pulled from the cloud into Drift DB
  Future<void> _mergeExpense(Map<String, dynamic> row) async {
    if (row['device_id'] == SyncDispatcher.deviceId) return;

    final cloudId = row['id'] as String?;
    final category = (row['category'] as String?) ?? '';
    final amount = (row['amount'] as num?)?.toInt() ?? 0;
    final expenseDate = row['expense_date'] != null
        ? DateTime.tryParse(row['expense_date'].toString()) ?? DateTime.now()
        : DateTime.now();
    final note = row['note'] as String?;
    final createdBy = (row['created_by'] as String?) ?? 'cloud';

    // Prevent duplicate insertion
    if (cloudId != null) {
      final localId = await _syncDispatcher.getLocalId('expense', cloudId);
      if (localId != null) {
        return; // Already merged
      }
    }

    final newId = await _db.into(_db.expenses).insert(
      ExpensesCompanion.insert(
        category: category,
        amount: amount,
        expenseDate: expenseDate,
        note: Value(note),
        createdBy: Value(createdBy),
      ),
    );

    if (cloudId != null) {
      await _syncDispatcher.saveMapping('expense', newId, cloudId);
    }
  }

  String _resolveTableName(String entityType) {
    switch (entityType) {
      case 'product':
        return 'products';
      case 'customer':
        return 'customers';
      case 'supplier':
        return 'suppliers';
      case 'sale':
        return 'sales';
      case 'sale_item':
        return 'sale_items';
      case 'purchase':
        return 'purchases';
      case 'purchase_item':
        return 'purchase_items';
      case 'customer_payment':
        return 'customer_payments';
      case 'supplier_payment':
        return 'supplier_payments';
      case 'cashbox':
        return 'cashbox_transactions';
      case 'expense':
        return 'expenses';
      case 'inventory_movement':
        return 'inventory_movements';
      case 'stock_adjustment':
        return 'stock_adjustments';
      case 'customer_ledger':
        return 'customer_ledger_entries';
      case 'supplier_ledger':
        return 'supplier_ledger_entries';
      case 'returns_customer':
      case 'return_customer':
        return 'returns_customer';
      case 'return_customer_item':
        return 'return_customer_items';
      case 'returns_supplier':
      case 'return_supplier':
        return 'returns_supplier';
      case 'return_supplier_item':
        return 'return_supplier_items';
      case 'audit_log':
        return 'audit_log';
      default:
        return entityType;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _pendingQueueSubscription?.cancel();
    _syncStateController.close();
  }
}
