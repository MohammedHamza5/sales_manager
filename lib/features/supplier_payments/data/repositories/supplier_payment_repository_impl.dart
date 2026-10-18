import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/money/money.dart';
import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../../../../core/sync/sync_dispatcher.dart';
import '../../domain/entities/supplier_payment.dart';
import '../../domain/repositories/supplier_payment_repository.dart';
import '../daos/supplier_payments_dao.dart';
import '../models/supplier_payment_mapper.dart';

class SupplierPaymentRepositoryImpl implements SupplierPaymentRepository {
  final AppDatabase _db;
  final SupplierPaymentsDao _dao;
  final SyncDispatcher? _syncDispatcher;

  SupplierPaymentRepositoryImpl({
    required AppDatabase db,
    required SupplierPaymentsDao dao,
    SyncDispatcher? syncDispatcher,
  })  : _db = db,
        _dao = dao,
        _syncDispatcher = syncDispatcher;

  @override
  Future<Result<SupplierPayment>> recordPayment({
    required int supplierId,
    required Money amount,
    required DateTime paymentDate,
    int? linkedPurchaseId,
    String? note,
    String createdBy = 'admin',
  }) async {
    try {
      final supplier = await (_db.select(_db.suppliers)
            ..where((t) => t.id.equals(supplierId)))
          .getSingleOrNull();

      if (supplier == null) {
        return const FailureResult(
          NotFoundFailure(message: 'المورد المحدد غير موجود في النظام'),
        );
      }

      if (!supplier.isActive) {
        return const FailureResult(
          ConflictFailure(message: 'لا يمكن تسجيل سداد لمورد موقوف'),
        );
      }

      return await _db.transaction(() async {
        final now = DateTime.now();

        // 1. Insert into supplier_payments
        final paymentCompanion = SupplierPaymentsCompanion.insert(
          supplierId: supplierId,
          amount: amount.piastres,
          paymentDate: paymentDate,
          linkedPurchaseId: Value(linkedPurchaseId),
          note: Value(note),
          createdAt: Value(now),
          createdBy: Value(createdBy),
        );
        final paymentId = await _dao.insertPayment(paymentCompanion);

        // Dispatch payment to Sync Queue
        await _syncDispatcher?.dispatchInsert(
          entityType: 'supplier_payment',
          localId: paymentId,
          data: {
            'supplier_id':
                SyncDispatcher.getEntityUuid('supplier', supplierId),
            'amount': amount.piastres,
            'payment_date': paymentDate.toIso8601String(),
            'linked_purchase_id': linkedPurchaseId != null
                ? SyncDispatcher.getEntityUuid('purchase', linkedPurchaseId)
                : null,
            'note': note,
            'created_at': now.toIso8601String(),
            'created_by': createdBy,
          },
        );

        // 2. Update supplier balance and insert ledger entry
        final newSupplierBalance = supplier.currentBalance - amount.piastres;

        await _db.into(_db.supplierLedgerEntries).insert(
              SupplierLedgerEntriesCompanion.insert(
                supplierId: supplierId,
                entryType: 'payment',
                amount: amount.piastres,
                effect: 'decrease',
                balanceAfter: newSupplierBalance,
                referenceType: const Value('supplier_payment'),
                referenceId: Value(paymentId),
                note: Value(note ?? 'سند سداد لمورد'),
                createdAt: Value(paymentDate),
                createdBy: Value(createdBy),
              ),
            );

        await (_db.update(_db.suppliers)..where((t) => t.id.equals(supplierId)))
            .write(SuppliersCompanion(currentBalance: Value(newSupplierBalance)));

        // Dispatch updated supplier balance to Sync Queue
        await _syncDispatcher?.dispatchUpdate(
          entityType: 'supplier',
          localId: supplierId,
          data: {
            'current_balance': newSupplierBalance,
          },
        );

        // 3. Update cashbox balance and insert cashbox transaction (direction: out)
        final lastCashboxTx = await (_db.select(_db.cashboxTransactions)
              ..orderBy([(t) => OrderingTerm.desc(t.id)])
              ..limit(1))
            .getSingleOrNull();

        final currentCashboxBalance = lastCashboxTx?.balanceAfter ?? 0;
        final newCashboxBalance = currentCashboxBalance - amount.piastres;

        await _db.into(_db.cashboxTransactions).insert(
              CashboxTransactionsCompanion.insert(
                transactionType: 'supplier_payment_out',
                amount: amount.piastres,
                direction: 'out',
                balanceAfter: newCashboxBalance,
                referenceType: const Value('supplier_payment'),
                referenceId: Value(paymentId),
                note: Value(
                  'سداد نقدي للمورد ${supplier.name}${note != null ? ' - $note' : ''}',
                ),
                createdAt: Value(paymentDate),
                createdBy: Value(createdBy),
              ),
            );

        // 4. Update linked purchase if provided
        int? linkedInvoiceNo;
        if (linkedPurchaseId != null) {
          final purchase = await (_db.select(_db.purchases)
                ..where((t) => t.id.equals(linkedPurchaseId)))
              .getSingleOrNull();

          if (purchase != null) {
            linkedInvoiceNo = purchase.invoiceNo;
          }
        }

        // 5. Audit Log
        await _db.into(_db.auditLog).insert(
              AuditLogCompanion.insert(
                entityType: 'supplier_payment',
                entityId: paymentId,
                action: 'create',
                userId: Value(createdBy),
                payloadAfter: Value(
                  jsonEncode({
                    'supplierId': supplierId,
                    'supplierName': supplier.name,
                    'amount': amount.piastres,
                    'paymentDate': paymentDate.toIso8601String(),
                    'linkedPurchaseId': linkedPurchaseId,
                    'newSupplierBalance': newSupplierBalance,
                    'newCashboxBalance': newCashboxBalance,
                    'note': note,
                  }),
                ),
                performedAt: Value(now),
              ),
            );

        return Success(
          SupplierPayment(
            id: paymentId,
            supplierId: supplierId,
            supplierName: supplier.name,
            amount: amount,
            paymentDate: paymentDate,
            linkedPurchaseId: linkedPurchaseId,
            linkedPurchaseInvoiceNo: linkedInvoiceNo,
            note: note,
            createdAt: now,
            createdBy: createdBy,
          ),
        );
      });
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في تسجيل سداد المورد',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Future<Result<List<SupplierPayment>>> getSupplierPayments({int? supplierId}) async {
    try {
      final details = await _dao.getPayments(supplierId: supplierId);
      return Success(details.map(SupplierPaymentMapper.fromDetails).toList());
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في جلب سندات سداد الموردين',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Stream<List<SupplierPayment>> watchSupplierPayments({int? supplierId}) {
    return _dao.watchPayments(supplierId: supplierId).map(
          (list) => list.map(SupplierPaymentMapper.fromDetails).toList(),
        );
  }

  @override
  Future<Result<List<SupplierPayment>>> getAllPayments({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final details = await _dao.getPayments(from: from, to: to);
      return Success(details.map(SupplierPaymentMapper.fromDetails).toList());
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في جلب سندات السداد',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }
}
