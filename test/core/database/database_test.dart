import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_manager/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  group('Drift AppDatabase tests', () {
    test('Can insert and retrieve product with exact Decimal quantity', () async {
      final productId = await db.into(db.products).insert(
            ProductsCompanion.insert(
              name: 'سكر أبيض 1 كجم',
              code: const Value('SUGAR-01'),
              unit: 'كيلو',
              currentSalePrice: 3500, // 35.00 ج.م
              currentPurchasePrice: 2800, // 28.00 ج.م
              currentQuantity: Value(Decimal.parse('150.5')),
            ),
          );

      final product = await (db.select(db.products)..where((tbl) => tbl.id.equals(productId))).getSingle();

      expect(product.name, 'سكر أبيض 1 كجم');
      expect(product.currentSalePrice, 3500);
      expect(product.currentQuantity, Decimal.parse('150.5'));
      expect(product.isActive, isTrue);
      expect(product.createdBy, 'admin');
    });

    test('Atomic transaction successfully commits all affected entities', () async {
      await db.transaction(() async {
        // 1. Insert Customer
        final customerId = await db.into(db.customers).insert(
              CustomersCompanion.insert(
                name: 'أحمد محمود',
                phone: const Value('01012345678'),
              ),
            );

        // 2. Insert Product
        final productId = await db.into(db.products).insert(
              ProductsCompanion.insert(
                name: 'شاي العروسة 250 جم',
                unit: 'علبة',
                currentSalePrice: 5000,
                currentPurchasePrice: 4200,
                currentQuantity: Value(Decimal.parse('100')),
              ),
            );

        // 3. Insert Sale
        final saleId = await db.into(db.sales).insert(
              SalesCompanion.insert(
                invoiceNo: 1001,
                customerId: customerId,
                saleDate: DateTime.now(),
                totalAmount: 10000, // 100.00 ج.م
                paidAmountAtCreation: 10000,
              ),
            );

        // 4. Insert Sale Item
        await db.into(db.saleItems).insert(
              SaleItemsCompanion.insert(
                saleId: saleId,
                productId: productId,
                quantity: Decimal.parse('2'),
                unitPriceAtSale: 5000,
                lineTotal: 10000,
              ),
            );

        // 5. Insert Cashbox Transaction
        await db.into(db.cashboxTransactions).insert(
              CashboxTransactionsCompanion.insert(
                transactionType: 'sale_cash_in',
                amount: 10000,
                direction: 'in',
                balanceAfter: 10000,
                referenceType: const Value('sale'),
                referenceId: Value(saleId),
              ),
            );

        // 6. Insert Audit Log
        await db.into(db.auditLog).insert(
              AuditLogCompanion.insert(
                entityType: 'sale',
                entityId: saleId,
                action: 'create',
                payloadAfter: const Value('{"invoice_no": 1001}'),
              ),
            );
      });

      // Verify all tables received data
      final salesCount = await db.select(db.sales).get();
      final cashboxCount = await db.select(db.cashboxTransactions).get();
      final auditCount = await db.select(db.auditLog).get();

      expect(salesCount.length, 1);
      expect(cashboxCount.length, 1);
      expect(auditCount.length, 1);
    });

    test('Transaction rolls back completely on any step failure', () async {
      try {
        await db.transaction(() async {
          await db.into(db.customers).insert(
                CustomersCompanion.insert(name: 'عميل تجريبي'),
              );

          // Force failure by inserting a sale item pointing to non-existent sale ID
          throw Exception('Simulated business logic failure');
        });
      } catch (_) {
        // Expected failure
      }

      // Verify rollback: customer must NOT exist
      final customers = await db.select(db.customers).get();
      expect(customers, isEmpty);
    });

    test('Can insert and retrieve expense record', () async {
      final expenseId = await db.into(db.expenses).insert(
            ExpensesCompanion.insert(
              category: 'كهرباء ومياه',
              amount: 75000, // 750.00 ج.م
              expenseDate: DateTime.now(),
              note: const Value('فاتورة كهرباء المحل لشهر سبتمبر'),
            ),
          );

      final expense = await (db.select(db.expenses)..where((tbl) => tbl.id.equals(expenseId))).getSingle();
      expect(expense.category, 'كهرباء ومياه');
      expect(expense.amount, 75000);
      expect(expense.createdBy, 'admin');
    });
  });
}
