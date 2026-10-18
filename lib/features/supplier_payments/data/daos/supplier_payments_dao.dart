import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/payments_cashbox_tables.dart';
import '../../../../core/database/tables/stakeholders_tables.dart';
import '../../../../core/database/tables/trading_tables.dart';

part 'supplier_payments_dao.g.dart';

class SupplierPaymentWithDetails {
  final SupplierPaymentEntry payment;
  final String supplierName;
  final int? purchaseInvoiceNo;

  const SupplierPaymentWithDetails({
    required this.payment,
    required this.supplierName,
    this.purchaseInvoiceNo,
  });
}

@DriftAccessor(tables: [SupplierPayments, Suppliers, Purchases])
class SupplierPaymentsDao extends DatabaseAccessor<AppDatabase>
    with _$SupplierPaymentsDaoMixin {
  SupplierPaymentsDao(super.db);

  Future<int> insertPayment(SupplierPaymentsCompanion companion) {
    return into(supplierPayments).insert(companion);
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildJoinedQuery({
    int? supplierId,
    DateTime? from,
    DateTime? to,
  }) {
    final query = select(supplierPayments).join([
      innerJoin(
        suppliers,
        suppliers.id.equalsExp(supplierPayments.supplierId),
      ),
      leftOuterJoin(
        purchases,
        purchases.id.equalsExp(supplierPayments.linkedPurchaseId),
      ),
    ]);

    Expression<bool> predicate = const Constant(true);

    if (supplierId != null) {
      predicate = predicate & supplierPayments.supplierId.equals(supplierId);
    }
    if (from != null) {
      predicate = predicate & supplierPayments.paymentDate.isBiggerOrEqualValue(from);
    }
    if (to != null) {
      predicate = predicate & supplierPayments.paymentDate.isSmallerOrEqualValue(to);
    }

    query.where(predicate);
    query.orderBy([
      OrderingTerm.desc(supplierPayments.paymentDate),
      OrderingTerm.desc(supplierPayments.id),
    ]);

    return query;
  }

  Future<List<SupplierPaymentWithDetails>> getPayments({
    int? supplierId,
    DateTime? from,
    DateTime? to,
  }) async {
    final query = _buildJoinedQuery(supplierId: supplierId, from: from, to: to);
    final rows = await query.get();

    return rows.map((row) {
      final payment = row.readTable(supplierPayments);
      final supplier = row.readTable(suppliers);
      final purchase = row.readTableOrNull(purchases);

      return SupplierPaymentWithDetails(
        payment: payment,
        supplierName: supplier.name,
        purchaseInvoiceNo: purchase?.invoiceNo,
      );
    }).toList();
  }

  Stream<List<SupplierPaymentWithDetails>> watchPayments({int? supplierId}) {
    final query = _buildJoinedQuery(supplierId: supplierId);
    return query.watch().map((rows) {
      return rows.map((row) {
        final payment = row.readTable(supplierPayments);
        final supplier = row.readTable(suppliers);
        final purchase = row.readTableOrNull(purchases);

        return SupplierPaymentWithDetails(
          payment: payment,
          supplierName: supplier.name,
          purchaseInvoiceNo: purchase?.invoiceNo,
        );
      }).toList();
    });
  }

  /// Returns active purchases for a supplier that have remaining balances.
  Future<List<PurchaseEntry>> getUnpaidPurchasesForSupplier(int supplierId) {
    return (select(purchases)
          ..where((t) =>
              t.supplierId.equals(supplierId) &
              t.status.equals('confirmed') &
              (t.totalAmount - t.paidAmountAtCreation).isBiggerThanValue(0))
          ..orderBy([(t) => OrderingTerm.desc(t.invoiceNo)]))
        .get();
  }
}
