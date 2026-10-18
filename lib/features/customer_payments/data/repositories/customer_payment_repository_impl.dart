import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/money/money.dart';
import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../../../../core/sync/sync_dispatcher.dart';
import '../../domain/entities/customer_payment.dart';
import '../../domain/repositories/customer_payment_repository.dart';
import '../daos/customer_payments_dao.dart';
import '../models/customer_payment_mapper.dart';

class CustomerPaymentRepositoryImpl implements CustomerPaymentRepository {
  final AppDatabase _db;
  final CustomerPaymentsDao _dao;
  final SyncDispatcher? _syncDispatcher;

  CustomerPaymentRepositoryImpl({
    required AppDatabase db,
    required CustomerPaymentsDao dao,
    SyncDispatcher? syncDispatcher,
  })  : _db = db,
        _dao = dao,
        _syncDispatcher = syncDispatcher;

  @override
  Future<Result<CustomerPayment>> recordPayment({
    required int customerId,
    required Money amount,
    required DateTime paymentDate,
    int? linkedSaleId,
    String? note,
    String createdBy = 'admin',
  }) async {
    try {
      final customer = await (_db.select(_db.customers)
            ..where((t) => t.id.equals(customerId)))
          .getSingleOrNull();

      if (customer == null) {
        return const FailureResult(
          NotFoundFailure(message: 'العميل المحدد غير موجود في النظام'),
        );
      }

      if (!customer.isActive) {
        return const FailureResult(
          ConflictFailure(message: 'لا يمكن تسجيل تحصيل نقدية لعميل موقوف'),
        );
      }

      return await _db.transaction(() async {
        final now = DateTime.now();

        // 1. Insert into customer_payments
        final paymentCompanion = CustomerPaymentsCompanion.insert(
          customerId: customerId,
          amount: amount.piastres,
          paymentDate: paymentDate,
          linkedSaleId: Value(linkedSaleId),
          note: Value(note),
          createdAt: Value(now),
          createdBy: Value(createdBy),
        );
        final paymentId = await _dao.insertPayment(paymentCompanion);

        // Dispatch payment to Sync Queue
        await _syncDispatcher?.dispatchInsert(
          entityType: 'customer_payment',
          localId: paymentId,
          data: {
            'customer_id':
                SyncDispatcher.getEntityUuid('customer', customerId),
            'amount': amount.piastres,
            'payment_date': paymentDate.toIso8601String(),
            'linked_sale_id': linkedSaleId != null
                ? SyncDispatcher.getEntityUuid('sale', linkedSaleId)
                : null,
            'note': note,
            'created_at': now.toIso8601String(),
            'created_by': createdBy,
          },
        );

        // 2. Update customer balance and insert ledger entry
        final newCustomerBalance = customer.currentBalance - amount.piastres;

        await _db.into(_db.customerLedgerEntries).insert(
              CustomerLedgerEntriesCompanion.insert(
                customerId: customerId,
                entryType: 'payment',
                amount: amount.piastres,
                effect: 'decrease',
                balanceAfter: newCustomerBalance,
                referenceType: const Value('customer_payment'),
                referenceId: Value(paymentId),
                note: Value(note ?? 'سند تحصيل نقدية'),
                createdAt: Value(paymentDate),
                createdBy: Value(createdBy),
              ),
            );

        await (_db.update(_db.customers)..where((t) => t.id.equals(customerId)))
            .write(CustomersCompanion(currentBalance: Value(newCustomerBalance)));

        // Dispatch updated customer balance to Sync Queue
        await _syncDispatcher?.dispatchUpdate(
          entityType: 'customer',
          localId: customerId,
          data: {
            'current_balance': newCustomerBalance,
          },
        );

        // 3. Update cashbox balance and insert cashbox transaction
        final lastCashboxTx = await (_db.select(_db.cashboxTransactions)
              ..orderBy([(t) => OrderingTerm.desc(t.id)])
              ..limit(1))
            .getSingleOrNull();

        final currentCashboxBalance = lastCashboxTx?.balanceAfter ?? 0;
        final newCashboxBalance = currentCashboxBalance + amount.piastres;

        await _db.into(_db.cashboxTransactions).insert(
              CashboxTransactionsCompanion.insert(
                transactionType: 'customer_payment_in',
                amount: amount.piastres,
                direction: 'in',
                balanceAfter: newCashboxBalance,
                referenceType: const Value('customer_payment'),
                referenceId: Value(paymentId),
                note: Value(
                  'تحصيل نقدي من العميل ${customer.name}${note != null ? ' - $note' : ''}',
                ),
                createdAt: Value(paymentDate),
                createdBy: Value(createdBy),
              ),
            );

        // 4. Update linked sale if provided
        int? linkedInvoiceNo;
        if (linkedSaleId != null) {
          final sale = await (_db.select(_db.sales)
                ..where((t) => t.id.equals(linkedSaleId)))
              .getSingleOrNull();

          if (sale != null) {
            linkedInvoiceNo = sale.invoiceNo;
          }
        }

        // 5. Audit Log
        await _db.into(_db.auditLog).insert(
              AuditLogCompanion.insert(
                entityType: 'customer_payment',
                entityId: paymentId,
                action: 'create',
                userId: Value(createdBy),
                payloadAfter: Value(
                  jsonEncode({
                    'customerId': customerId,
                    'customerName': customer.name,
                    'amount': amount.piastres,
                    'paymentDate': paymentDate.toIso8601String(),
                    'linkedSaleId': linkedSaleId,
                    'newCustomerBalance': newCustomerBalance,
                    'newCashboxBalance': newCashboxBalance,
                    'note': note,
                  }),
                ),
                performedAt: Value(now),
              ),
            );

        return Success(
          CustomerPayment(
            id: paymentId,
            customerId: customerId,
            customerName: customer.name,
            amount: amount,
            paymentDate: paymentDate,
            linkedSaleId: linkedSaleId,
            linkedSaleInvoiceNo: linkedInvoiceNo,
            note: note,
            createdAt: now,
            createdBy: createdBy,
          ),
        );
      });
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في تسجيل التحصيل النقدي',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Future<Result<List<CustomerPayment>>> getCustomerPayments({int? customerId}) async {
    try {
      final details = await _dao.getPayments(customerId: customerId);
      return Success(details.map(CustomerPaymentMapper.fromDetails).toList());
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في جلب سندات التحصيل',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Stream<List<CustomerPayment>> watchCustomerPayments({int? customerId}) {
    return _dao.watchPayments(customerId: customerId).map(
          (list) => list.map(CustomerPaymentMapper.fromDetails).toList(),
        );
  }

  @override
  Future<Result<List<CustomerPayment>>> getAllPayments({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final details = await _dao.getPayments(from: from, to: to);
      return Success(details.map(CustomerPaymentMapper.fromDetails).toList());
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في جلب التحصيلات',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }
}
