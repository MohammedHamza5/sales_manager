import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/payments_cashbox_tables.dart';
import '../../../../core/database/tables/stakeholders_tables.dart';
import '../../../../core/database/tables/trading_tables.dart';

part 'customer_payments_dao.g.dart';

class CustomerPaymentWithDetails {
  final CustomerPaymentEntry payment;
  final String customerName;
  final int? saleInvoiceNo;

  const CustomerPaymentWithDetails({
    required this.payment,
    required this.customerName,
    this.saleInvoiceNo,
  });
}

@DriftAccessor(tables: [CustomerPayments, Customers, Sales])
class CustomerPaymentsDao extends DatabaseAccessor<AppDatabase>
    with _$CustomerPaymentsDaoMixin {
  CustomerPaymentsDao(super.db);

  Future<int> insertPayment(CustomerPaymentsCompanion companion) {
    return into(customerPayments).insert(companion);
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildJoinedQuery({
    int? customerId,
    DateTime? from,
    DateTime? to,
  }) {
    final query = select(customerPayments).join([
      innerJoin(
        customers,
        customers.id.equalsExp(customerPayments.customerId),
      ),
      leftOuterJoin(
        sales,
        sales.id.equalsExp(customerPayments.linkedSaleId),
      ),
    ]);

    Expression<bool> predicate = const Constant(true);

    if (customerId != null) {
      predicate = predicate & customerPayments.customerId.equals(customerId);
    }
    if (from != null) {
      predicate = predicate & customerPayments.paymentDate.isBiggerOrEqualValue(from);
    }
    if (to != null) {
      predicate = predicate & customerPayments.paymentDate.isSmallerOrEqualValue(to);
    }

    query.where(predicate);
    query.orderBy([
      OrderingTerm.desc(customerPayments.paymentDate),
      OrderingTerm.desc(customerPayments.id),
    ]);

    return query;
  }

  Future<List<CustomerPaymentWithDetails>> getPayments({
    int? customerId,
    DateTime? from,
    DateTime? to,
  }) async {
    final query = _buildJoinedQuery(customerId: customerId, from: from, to: to);
    final rows = await query.get();

    return rows.map((row) {
      final payment = row.readTable(customerPayments);
      final customer = row.readTable(customers);
      final sale = row.readTableOrNull(sales);

      return CustomerPaymentWithDetails(
        payment: payment,
        customerName: customer.name,
        saleInvoiceNo: sale?.invoiceNo,
      );
    }).toList();
  }

  Stream<List<CustomerPaymentWithDetails>> watchPayments({int? customerId}) {
    final query = _buildJoinedQuery(customerId: customerId);
    return query.watch().map((rows) {
      return rows.map((row) {
        final payment = row.readTable(customerPayments);
        final customer = row.readTable(customers);
        final sale = row.readTableOrNull(sales);

        return CustomerPaymentWithDetails(
          payment: payment,
          customerName: customer.name,
          saleInvoiceNo: sale?.invoiceNo,
        );
      }).toList();
    });
  }

  /// Returns active sales for a customer that have remaining balances.
  Future<List<SaleEntry>> getUnpaidSalesForCustomer(int customerId) {
    return (select(sales)
          ..where((t) =>
              t.customerId.equals(customerId) &
              t.status.equals('confirmed') &
              (t.totalAmount - t.paidAmountAtCreation).isBiggerThanValue(0))
          ..orderBy([(t) => OrderingTerm.desc(t.invoiceNo)]))
        .get();
  }
}
