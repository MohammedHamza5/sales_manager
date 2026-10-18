import 'dart:convert';
import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/money/money.dart';
import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../../../../core/sync/sync_dispatcher.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/entities/supplier_ledger_entry.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../daos/suppliers_dao.dart';
import '../models/supplier_mapper.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  final AppDatabase _db;
  final SuppliersDao _dao;
  final SyncDispatcher? _syncDispatcher;

  SupplierRepositoryImpl({
    required AppDatabase db,
    required SuppliersDao dao,
    SyncDispatcher? syncDispatcher,
  })  : _db = db,
        _dao = dao,
        _syncDispatcher = syncDispatcher;

  @override
  Future<Result<List<Supplier>>> getSuppliers({
    String? query,
    bool? isActiveOnly,
  }) async {
    try {
      final entries = await _dao.getSuppliersList(
        query: query,
        isActiveOnly: isActiveOnly,
      );
      final suppliers = entries.map(SupplierMapper.toDomain).toList();
      return Success(suppliers);
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في جلب قائمة الموردين',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Stream<List<Supplier>> watchSuppliers({
    String? query,
    bool? isActiveOnly,
  }) {
    return _dao
        .watchSuppliersList(query: query, isActiveOnly: isActiveOnly)
        .map((entries) => entries.map(SupplierMapper.toDomain).toList());
  }

  @override
  Future<Result<Supplier>> getSupplierById(int id) async {
    try {
      final entry = await _dao.getSupplierById(id);
      if (entry == null) {
        return const FailureResult(NotFoundFailure(message: 'المورد غير موجود'));
      }
      return Success(SupplierMapper.toDomain(entry));
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في جلب بيانات المورد',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Future<Result<Supplier>> addSupplier({
    required String name,
    String? phone,
    String? address,
    String? notes,
    Money initialBalance = Money.zero,
    String createdBy = 'admin',
  }) async {
    try {
      return await _db.transaction(() async {
        final now = DateTime.now();

        // 1. Insert supplier
        final supplierId = await _dao.insertSupplier(
          SupplierMapper.toCompanion(
            name: name,
            phone: phone,
            address: address,
            notes: notes,
            initialBalance: initialBalance,
            createdBy: createdBy,
          ),
        );

        // 2. If initial balance != 0, write Opening Balance Ledger Entry
        if (initialBalance.piastres != 0) {
          final isDue = initialBalance.piastres > 0;
          await _dao.insertLedgerEntry(
            SupplierLedgerEntriesCompanion.insert(
              supplierId: supplierId,
              entryType: 'opening_balance',
              amount: initialBalance.abs().piastres,
              effect: isDue ? 'increase' : 'decrease',
              balanceAfter: initialBalance.piastres,
              referenceType: const Value('opening_balance'),
              note: const Value('رصيد افتتاحي عند تسجيل المورد'),
              createdAt: Value(now),
              createdBy: Value(createdBy),
            ),
          );
        }

        // 3. Write Audit Log
        await _db.into(_db.auditLog).insert(
              AuditLogCompanion.insert(
                entityType: 'supplier',
                entityId: supplierId,
                action: 'create',
                payloadAfter: Value(
                  jsonEncode({
                    'id': supplierId,
                    'name': name,
                    'phone': phone,
                    'address': address,
                    'notes': notes,
                    'initial_balance_piastres': initialBalance.piastres,
                  }),
                ),
                userId: Value(createdBy),
              ),
            );

        // 4. Dispatch to Sync Queue
        await _syncDispatcher?.dispatchInsert(
          entityType: 'supplier',
          localId: supplierId,
          data: {
            'name': name,
            'phone': phone,
            'address': address,
            'notes': notes,
            'current_balance': initialBalance.piastres,
            'is_active': true,
            'created_at': now.toIso8601String(),
            'created_by': createdBy,
          },
        );

        final newSupplier = Supplier(
          id: supplierId,
          name: name,
          phone: phone,
          address: address,
          notes: notes,
          currentBalance: initialBalance,
          isActive: true,
          createdAt: now,
          createdBy: createdBy,
        );

        return Success(newSupplier);
      });
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في إضافة المورد',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Future<Result<Supplier>> updateSupplier(Supplier supplier) async {
    try {
      return await _db.transaction(() async {
        final existing = await _dao.getSupplierById(supplier.id);
        if (existing == null) {
          return const FailureResult(NotFoundFailure(message: 'المورد المراد تعديله غير موجود'));
        }

        final companion = SuppliersCompanion(
          id: Value(supplier.id),
          name: Value(supplier.name),
          phone: Value(supplier.phone),
          address: Value(supplier.address),
          notes: Value(supplier.notes),
          currentBalance: Value(existing.currentBalance), // balance strictly preserved
          isActive: Value(existing.isActive),
        );

        await _dao.updateSupplierEntry(companion);

        // Audit Log
        await _db.into(_db.auditLog).insert(
              AuditLogCompanion.insert(
                entityType: 'supplier',
                entityId: supplier.id,
                action: 'update',
                payloadBefore: Value(
                  jsonEncode({
                    'name': existing.name,
                    'phone': existing.phone,
                    'address': existing.address,
                    'notes': existing.notes,
                  }),
                ),
                payloadAfter: Value(
                  jsonEncode({
                    'name': supplier.name,
                    'phone': supplier.phone,
                    'address': supplier.address,
                    'notes': supplier.notes,
                  }),
                ),
                userId: Value(supplier.createdBy),
              ),
            );

        // Dispatch to Sync Queue
        await _syncDispatcher?.dispatchUpdate(
          entityType: 'supplier',
          localId: supplier.id,
          data: {
            'name': supplier.name,
            'phone': supplier.phone,
            'address': supplier.address,
            'notes': supplier.notes,
          },
        );

        return Success(
          SupplierMapper.toDomain(existing).copyWith(
            name: supplier.name,
            phone: supplier.phone,
            address: supplier.address,
            notes: supplier.notes,
          ),
        );
      });
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في تعديل بيانات المورد',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Future<Result<void>> toggleSupplierStatus(int id, bool isActive) async {
    try {
      return await _db.transaction(() async {
        final existing = await _dao.getSupplierById(id);
        if (existing == null) {
          return const FailureResult(NotFoundFailure(message: 'المورد غير موجود'));
        }

        await _dao.updateSupplierStatus(id, isActive);

        await _db.into(_db.auditLog).insert(
              AuditLogCompanion.insert(
                entityType: 'supplier',
                entityId: id,
                action: isActive ? 'activate' : 'deactivate',
                payloadBefore: Value(jsonEncode({'is_active': existing.isActive})),
                payloadAfter: Value(jsonEncode({'is_active': isActive})),
              ),
            );

        // Dispatch status update to Sync Queue
        await _syncDispatcher?.dispatchUpdate(
          entityType: 'supplier',
          localId: id,
          data: {
            'is_active': isActive,
          },
        );

        return const Success(null);
      });
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في تغيير حالة المورد',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Future<Result<List<SupplierLedgerEntry>>> getSupplierLedger(int supplierId) async {
    try {
      final entries = await _dao.getSupplierLedgerEntries(supplierId);
      final ledger = entries.map(SupplierMapper.toLedgerDomain).toList();
      return Success(ledger);
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في جلب كشف حساب المورد',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Stream<List<SupplierLedgerEntry>> watchSupplierLedger(int supplierId) {
    return _dao
        .watchSupplierLedgerEntries(supplierId)
        .map((entries) => entries.map(SupplierMapper.toLedgerDomain).toList());
  }
}
