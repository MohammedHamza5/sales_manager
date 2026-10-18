import 'dart:convert';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../../../../core/sync/sync_dispatcher.dart';
import '../../domain/entities/opening_balance_input.dart';
import '../../domain/repositories/opening_balance_repository.dart';

class OpeningBalanceRepositoryImpl implements OpeningBalanceRepository {
  final AppDatabase _db;
  final SyncDispatcher? _syncDispatcher;

  const OpeningBalanceRepositoryImpl(
    this._db, [
    this._syncDispatcher,
  ]);

  @override
  Future<Result<bool>> isOpeningBalanceSaved() async {
    try {
      final entry = await (_db.select(_db.settings)
            ..where((s) => s.key.equals('opening_balance_saved')))
          .getSingleOrNull();

      return Success(entry?.value == 'true');
    } catch (e) {
      return FailureResult(
        DatabaseFailure(message: 'فشل التحقق من حالة الأرصدة الافتتاحية: $e'),
      );
    }
  }

  @override
  Future<Result<void>> saveOpeningBalances(
    OpeningBalanceInput input, {
    String createdBy = 'admin',
  }) async {
    try {
      final savedEntry = await (_db.select(_db.settings)
            ..where((s) => s.key.equals('opening_balance_saved')))
          .getSingleOrNull();
      if (savedEntry?.value == 'true') {
        return const FailureResult(
          ConflictFailure(
            message: 'تم حفظ الأرصدة الافتتاحية للنظام بالفعل سابقاً، ولا يمكن إعادة إدخالها.',
          ),
        );
      }

      await _db.transaction(() async {
        // 1. Cashbox Opening Balance
        if (input.cashboxBalance.piastres > 0) {
          final txId = await _db.into(_db.cashboxTransactions).insert(
            CashboxTransactionsCompanion.insert(
              transactionType: 'opening_balance',
              amount: input.cashboxBalance.piastres,
              direction: 'in',
              balanceAfter: input.cashboxBalance.piastres,
              referenceType: const Value('opening_balance'),
              note: const Value('رصيد خزينة افتتاحي'),
              createdBy: Value(createdBy),
            ),
          );

          await _syncDispatcher?.dispatchInsert(
            entityType: 'cashbox',
            localId: txId,
            data: {
              'transaction_type': 'opening_balance',
              'amount': input.cashboxBalance.piastres,
              'direction': 'in',
              'balance_after': input.cashboxBalance.piastres,
              'reference_type': 'opening_balance',
              'note': 'رصيد خزينة افتتاحي',
              'created_by': createdBy,
            },
          );
        }

        // 2. Products Opening Stock
        for (final p in input.products) {
          if (p.initialQuantity > Decimal.zero) {
            await _db.into(_db.inventoryMovements).insert(
              InventoryMovementsCompanion.insert(
                productId: p.productId,
                movementType: 'opening_balance',
                quantityDelta: p.initialQuantity,
                balanceAfter: p.initialQuantity,
                referenceType: const Value('opening_balance'),
                note: const Value('رصيد افتتاحي للمخزون'),
                createdBy: Value(createdBy),
              ),
            );

            await (_db.update(_db.products)
                  ..where((prod) => prod.id.equals(p.productId)))
                .write(
              ProductsCompanion(
                currentQuantity: Value(p.initialQuantity),
              ),
            );

            await _syncDispatcher?.dispatchUpdate(
              entityType: 'product',
              localId: p.productId,
              data: {
                'current_quantity': p.initialQuantity.toDouble(),
              },
            );
          }
        }

        // 3. Customers Opening Receivables (Debt)
        for (final c in input.customers) {
          if (c.balance.piastres > 0) {
            await _db.into(_db.customerLedgerEntries).insert(
              CustomerLedgerEntriesCompanion.insert(
                customerId: c.stakeholderId,
                entryType: 'opening_balance',
                amount: c.balance.piastres,
                effect: 'increase',
                balanceAfter: c.balance.piastres,
                referenceType: const Value('opening_balance'),
                note: const Value('رصيد افتتاحي للعميل'),
                createdBy: Value(createdBy),
              ),
            );

            await (_db.update(_db.customers)
                  ..where((cust) => cust.id.equals(c.stakeholderId)))
                .write(
              CustomersCompanion(
                currentBalance: Value(c.balance.piastres),
              ),
            );

            await _syncDispatcher?.dispatchUpdate(
              entityType: 'customer',
              localId: c.stakeholderId,
              data: {
                'current_balance': c.balance.piastres,
              },
            );
          }
        }

        // 4. Suppliers Opening Payables (Due)
        for (final s in input.suppliers) {
          if (s.balance.piastres > 0) {
            await _db.into(_db.supplierLedgerEntries).insert(
              SupplierLedgerEntriesCompanion.insert(
                supplierId: s.stakeholderId,
                entryType: 'opening_balance',
                amount: s.balance.piastres,
                effect: 'increase',
                balanceAfter: s.balance.piastres,
                referenceType: const Value('opening_balance'),
                note: const Value('رصيد افتتاحي للمورد'),
                createdBy: Value(createdBy),
              ),
            );

            await (_db.update(_db.suppliers)
                  ..where((sup) => sup.id.equals(s.stakeholderId)))
                .write(
              SuppliersCompanion(
                currentBalance: Value(s.balance.piastres),
              ),
            );

            await _syncDispatcher?.dispatchUpdate(
              entityType: 'supplier',
              localId: s.stakeholderId,
              data: {
                'current_balance': s.balance.piastres,
              },
            );
          }
        }

        // 5. Mark Settings as saved
        await _db.into(_db.settings).insertOnConflictUpdate(
          SettingsCompanion.insert(
            key: 'opening_balance_saved',
            value: 'true',
          ),
        );

        // 6. Record Audit Log
        final productsCount = input.products
            .where((p) => p.initialQuantity > Decimal.zero)
            .length;
        final customersCount =
            input.customers.where((c) => c.balance.piastres > 0).length;
        final suppliersCount =
            input.suppliers.where((s) => s.balance.piastres > 0).length;

        await _db.into(_db.auditLog).insert(
          AuditLogCompanion.insert(
            entityType: 'system',
            entityId: 0,
            action: 'opening_balance',
            payloadAfter: Value(
              jsonEncode({
                'products_with_stock_count': productsCount,
                'customers_with_debt_count': customersCount,
                'suppliers_with_due_count': suppliersCount,
                'cashbox_balance_piastres': input.cashboxBalance.piastres,
              }),
            ),
            note: const Value('تسجيل الأرصدة الافتتاحية للنظام بالكامل'),
            userId: Value(createdBy),
          ),
        );
      });

      return const Success(null);
    } catch (e) {
      return FailureResult(DatabaseFailure(message: 'فشل حفظ الأرصدة الافتتاحية: $e'));
    }
  }
}
