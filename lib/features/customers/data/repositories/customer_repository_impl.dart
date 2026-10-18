import 'dart:convert';
import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/money/money.dart';
import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../../../../core/sync/sync_dispatcher.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_ledger_entry.dart';
import '../../domain/repositories/customer_repository.dart';
import '../daos/customers_dao.dart';
import '../models/customer_mapper.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final AppDatabase _db;
  final CustomersDao _dao;
  final SyncDispatcher? _syncDispatcher;

  CustomerRepositoryImpl({
    required AppDatabase db,
    required CustomersDao dao,
    SyncDispatcher? syncDispatcher,
  })  : _db = db,
        _dao = dao,
        _syncDispatcher = syncDispatcher;

  @override
  Future<Result<List<Customer>>> getCustomers({
    String? query,
    bool? isActiveOnly,
  }) async {
    try {
      final entries = await _dao.getCustomersList(
        query: query,
        isActiveOnly: isActiveOnly,
      );
      final customers = entries.map(CustomerMapper.toDomain).toList();
      return Success(customers);
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في جلب قائمة العملاء',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Stream<List<Customer>> watchCustomers({
    String? query,
    bool? isActiveOnly,
  }) {
    return _dao
        .watchCustomersList(query: query, isActiveOnly: isActiveOnly)
        .map((entries) => entries.map(CustomerMapper.toDomain).toList());
  }

  @override
  Future<Result<Customer>> getCustomerById(int id) async {
    try {
      final entry = await _dao.getCustomerById(id);
      if (entry == null) {
        return const FailureResult(NotFoundFailure(message: 'العميل غير موجود'));
      }
      return Success(CustomerMapper.toDomain(entry));
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في جلب بيانات العميل',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Future<Result<Customer>> addCustomer({
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

        // 1. Insert customer
        final customerId = await _dao.insertCustomer(
          CustomerMapper.toCompanion(
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
          final isDebt = initialBalance.piastres > 0;
          await _dao.insertLedgerEntry(
            CustomerLedgerEntriesCompanion.insert(
              customerId: customerId,
              entryType: 'opening_balance',
              amount: initialBalance.abs().piastres,
              effect: isDebt ? 'increase' : 'decrease',
              balanceAfter: initialBalance.piastres,
              referenceType: const Value('opening_balance'),
              note: const Value('رصيد افتتاحي عند إنشاء العميل'),
              createdAt: Value(now),
              createdBy: Value(createdBy),
            ),
          );
        }

        // 3. Write Audit Log
        await _db.into(_db.auditLog).insert(
              AuditLogCompanion.insert(
                entityType: 'customer',
                entityId: customerId,
                action: 'create',
                payloadAfter: Value(
                  jsonEncode({
                    'id': customerId,
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
          entityType: 'customer',
          localId: customerId,
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

        final newCustomer = Customer(
          id: customerId,
          name: name,
          phone: phone,
          address: address,
          notes: notes,
          currentBalance: initialBalance,
          isActive: true,
          createdAt: now,
          createdBy: createdBy,
        );

        return Success(newCustomer);
      });
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في إضافة العميل',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Future<Result<Customer>> updateCustomer(Customer customer) async {
    try {
      return await _db.transaction(() async {
        final existing = await _dao.getCustomerById(customer.id);
        if (existing == null) {
          return const FailureResult(NotFoundFailure(message: 'العميل المراد تعديله غير موجود'));
        }

        final companion = CustomersCompanion(
          id: Value(customer.id),
          name: Value(customer.name),
          phone: Value(customer.phone),
          address: Value(customer.address),
          notes: Value(customer.notes),
          currentBalance: Value(existing.currentBalance), // balance strictly preserved
          isActive: Value(existing.isActive),
        );

        await _dao.updateCustomerEntry(companion);

        // Audit Log
        await _db.into(_db.auditLog).insert(
              AuditLogCompanion.insert(
                entityType: 'customer',
                entityId: customer.id,
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
                    'name': customer.name,
                    'phone': customer.phone,
                    'address': customer.address,
                    'notes': customer.notes,
                  }),
                ),
                userId: Value(customer.createdBy),
              ),
            );

        // Dispatch to Sync Queue
        await _syncDispatcher?.dispatchUpdate(
          entityType: 'customer',
          localId: customer.id,
          data: {
            'name': customer.name,
            'phone': customer.phone,
            'address': customer.address,
            'notes': customer.notes,
          },
        );

        return Success(
          CustomerMapper.toDomain(existing).copyWith(
            name: customer.name,
            phone: customer.phone,
            address: customer.address,
            notes: customer.notes,
          ),
        );
      });
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في تعديل بيانات العميل',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Future<Result<void>> toggleCustomerStatus(int id, bool isActive) async {
    try {
      return await _db.transaction(() async {
        final existing = await _dao.getCustomerById(id);
        if (existing == null) {
          return const FailureResult(NotFoundFailure(message: 'العميل غير موجود'));
        }

        await _dao.updateCustomerStatus(id, isActive);

        await _db.into(_db.auditLog).insert(
              AuditLogCompanion.insert(
                entityType: 'customer',
                entityId: id,
                action: isActive ? 'activate' : 'deactivate',
                payloadBefore: Value(jsonEncode({'is_active': existing.isActive})),
                payloadAfter: Value(jsonEncode({'is_active': isActive})),
              ),
            );

        // Dispatch status update to Sync Queue
        await _syncDispatcher?.dispatchUpdate(
          entityType: 'customer',
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
          message: 'فشل في تغيير حالة العميل',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Future<Result<List<CustomerLedgerEntry>>> getCustomerLedger(int customerId) async {
    try {
      final entries = await _dao.getCustomerLedgerEntries(customerId);
      final ledger = entries.map(CustomerMapper.toLedgerDomain).toList();
      return Success(ledger);
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في جلب كشف حساب العميل',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Stream<List<CustomerLedgerEntry>> watchCustomerLedger(int customerId) {
    return _dao
        .watchCustomerLedgerEntries(customerId)
        .map((entries) => entries.map(CustomerMapper.toLedgerDomain).toList());
  }
}
