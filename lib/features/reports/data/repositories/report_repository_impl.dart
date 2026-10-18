import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/money/money.dart';
import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/cashbox_report.dart';
import '../../domain/entities/collections_report.dart';
import '../../domain/entities/customer_account_report.dart';
import '../../domain/entities/inventory_report.dart';
import '../../domain/entities/profit_report.dart';
import '../../domain/entities/sales_report.dart';
import '../../domain/entities/supplier_account_report.dart';
import '../../domain/repositories/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  final AppDatabase _db;

  const ReportRepositoryImpl(this._db);

  @override
  Future<Result<SalesReport>> getSalesReport({
    required DateTime from,
    required DateTime to,
    int? customerId,
    String? status,
  }) async {
    try {
      final startOfDay = DateTime(from.year, from.month, from.day, 0, 0, 0);
      final endOfDay = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);

      final query = _db.select(_db.sales).join([
        innerJoin(
          _db.customers,
          _db.customers.id.equalsExp(_db.sales.customerId),
        ),
      ]);

      query.where(_db.sales.saleDate.isBiggerOrEqualValue(startOfDay) &
          _db.sales.saleDate.isSmallerOrEqualValue(endOfDay));

      if (customerId != null) {
        query.where(_db.sales.customerId.equals(customerId));
      }

      if (status != null && status.isNotEmpty) {
        query.where(_db.sales.status.equals(status));
      }

      query.orderBy([OrderingTerm.desc(_db.sales.invoiceNo)]);

      final rows = await query.get();
      final saleReturns = await _db.select(_db.returnsCustomer).get();
      final retMap = <int, int>{};
      for (final r in saleReturns) {
        if (r.originalSaleId != null) {
          retMap[r.originalSaleId!] =
              (retMap[r.originalSaleId!] ?? 0) + r.totalAmount;
        }
      }

      var totalSalesPiastres = 0;
      var totalPaidPiastres = 0;
      var totalRemainingPiastres = 0;

      final items = rows.map((row) {
        final sale = row.readTable(_db.sales);
        final customer = row.readTable(_db.customers);
        final returned = retMap[sale.id] ?? 0;
        final remCalc = sale.totalAmount - returned - sale.paidAmountAtCreation;
        final remaining = remCalc > 0 ? remCalc : 0;

        if (sale.status == 'confirmed') {
          totalSalesPiastres += (sale.totalAmount - returned).clamp(0, double.maxFinite.toInt());
          totalPaidPiastres += sale.paidAmountAtCreation;
          totalRemainingPiastres += remaining;
        }

        return SalesReportItem(
          invoiceNo: sale.invoiceNo,
          saleDate: sale.saleDate,
          customerName: customer.name,
          totalAmount: Money.fromPiastres(sale.totalAmount),
          paidAmount: Money.fromPiastres(sale.paidAmountAtCreation),
          remainingAmount: Money.fromPiastres(remaining),
          status: sale.status,
        );
      }).toList();

      return Success(
        SalesReport(
          from: from,
          to: to,
          totalSales: Money.fromPiastres(totalSalesPiastres),
          totalPaid: Money.fromPiastres(totalPaidPiastres),
          totalRemaining: Money.fromPiastres(totalRemainingPiastres),
          salesCount: items.length,
          items: items,
        ),
      );
    } catch (e) {
      return FailureResult(
        DatabaseFailure(message: 'فشل إنشاء تقرير المبيعات: $e'),
      );
    }
  }

  @override
  Future<Result<CollectionsReport>> getCollectionsReport({
    required DateTime from,
    required DateTime to,
    int? customerId,
  }) async {
    try {
      final startOfDay = DateTime(from.year, from.month, from.day, 0, 0, 0);
      final endOfDay = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);

      final query = _db.select(_db.customerPayments).join([
        innerJoin(
          _db.customers,
          _db.customers.id.equalsExp(_db.customerPayments.customerId),
        ),
        leftOuterJoin(
          _db.sales,
          _db.sales.id.equalsExp(_db.customerPayments.linkedSaleId),
        ),
      ]);

      query.where(_db.customerPayments.paymentDate.isBiggerOrEqualValue(startOfDay) &
          _db.customerPayments.paymentDate.isSmallerOrEqualValue(endOfDay));

      if (customerId != null) {
        query.where(_db.customerPayments.customerId.equals(customerId));
      }

      query.orderBy([OrderingTerm.desc(_db.customerPayments.id)]);

      final rows = await query.get();

      var totalCollectedPiastres = 0;

      final items = rows.map((row) {
        final payment = row.readTable(_db.customerPayments);
        final customer = row.readTable(_db.customers);
        final sale = row.readTableOrNull(_db.sales);

        totalCollectedPiastres += payment.amount;

        return CollectionReportItem(
          paymentId: payment.id,
          paymentDate: payment.paymentDate,
          customerName: customer.name,
          amount: Money.fromPiastres(payment.amount),
          linkedSaleInvoiceNo: sale?.invoiceNo,
          note: payment.note,
        );
      }).toList();

      return Success(
        CollectionsReport(
          from: from,
          to: to,
          totalCollected: Money.fromPiastres(totalCollectedPiastres),
          paymentsCount: items.length,
          items: items,
        ),
      );
    } catch (e) {
      return FailureResult(
        DatabaseFailure(message: 'فشل إنشاء تقرير التحصيلات: $e'),
      );
    }
  }

  @override
  Future<Result<CustomerAccountReport>> getCustomerReport({
    required int customerId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final customer = await (_db.select(_db.customers)
            ..where((c) => c.id.equals(customerId)))
          .getSingleOrNull();

      if (customer == null) {
        return const FailureResult(NotFoundFailure(message: 'العميل غير موجود'));
      }

      final startOfDay = DateTime(from.year, from.month, from.day, 0, 0, 0);
      final endOfDay = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);

      // Prior balance calculation
      final priorEntry = await (_db.select(_db.customerLedgerEntries)
            ..where((e) =>
                e.customerId.equals(customerId) &
                e.createdAt.isSmallerThanValue(startOfDay))
            ..orderBy([(e) => OrderingTerm.desc(e.id)])
            ..limit(1))
          .getSingleOrNull();

      final openingBalancePiastres = priorEntry?.balanceAfter ?? 0;

      // Entries in range
      final rangeEntries = await (_db.select(_db.customerLedgerEntries)
            ..where((e) =>
                e.customerId.equals(customerId) &
                e.createdAt.isBiggerOrEqualValue(startOfDay) &
                e.createdAt.isSmallerOrEqualValue(endOfDay))
            ..orderBy([(e) => OrderingTerm.asc(e.id)]))
          .get();

      var totalDebitPiastres = 0;
      var totalCreditPiastres = 0;

      final items = rangeEntries.map((e) {
        // Customer: debt increase = debit, debt decrease = credit
        final isDebit = e.effect == 'increase';
        final debitPiastres = isDebit ? e.amount : 0;
        final creditPiastres = isDebit ? 0 : e.amount;

        totalDebitPiastres += debitPiastres;
        totalCreditPiastres += creditPiastres;

        String description;
        switch (e.entryType) {
          case 'sale':
            description = 'فاتورة بيع';
            break;
          case 'payment':
            description = 'سداد نقدي / تحصيل';
            break;
          case 'return':
          case 'customer_return':
            description = 'مرتجع مبيعات';
            break;
          case 'opening_balance':
            description = 'رصيد افتتاحي';
            break;
          case 'reversal':
            description = 'إلغاء / عكس عملية';
            break;
          default:
            description = e.entryType;
        }

        if (e.note != null && e.note!.isNotEmpty) {
          description += ' (${e.note})';
        }

        return CustomerLedgerReportItem(
          id: e.id,
          date: e.createdAt,
          entryType: e.entryType,
          description: description,
          debit: Money.fromPiastres(debitPiastres),
          credit: Money.fromPiastres(creditPiastres),
          balanceAfter: Money.fromPiastres(e.balanceAfter),
        );
      }).toList();

      final closingBalancePiastres = rangeEntries.isNotEmpty
          ? rangeEntries.last.balanceAfter
          : openingBalancePiastres;

      return Success(
        CustomerAccountReport(
          customerId: customer.id,
          customerName: customer.name,
          from: from,
          to: to,
          openingBalance: Money.fromPiastres(openingBalancePiastres),
          closingBalance: Money.fromPiastres(closingBalancePiastres),
          totalDebit: Money.fromPiastres(totalDebitPiastres),
          totalCredit: Money.fromPiastres(totalCreditPiastres),
          entries: items,
        ),
      );
    } catch (e) {
      return FailureResult(
        DatabaseFailure(message: 'فشل إنشاء كشف حساب العميل: $e'),
      );
    }
  }

  @override
  Future<Result<List<CustomerBalanceSummary>>> getAllCustomerBalances() async {
    try {
      final rows = await (_db.select(_db.customers)
            ..where((c) => c.isActive.equals(true))
            ..orderBy([(c) => OrderingTerm.desc(c.currentBalance)]))
          .get();

      final result = rows
          .map((c) => CustomerBalanceSummary(
                customerId: c.id,
                customerName: c.name,
                phone: c.phone,
                balance: Money.fromPiastres(c.currentBalance),
              ))
          .toList();

      return Success(result);
    } catch (e) {
      return FailureResult(
        DatabaseFailure(message: 'فشل جلب أرصدة العملاء: $e'),
      );
    }
  }

  @override
  Future<Result<SupplierAccountReport>> getSupplierReport({
    required int supplierId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final supplier = await (_db.select(_db.suppliers)
            ..where((s) => s.id.equals(supplierId)))
          .getSingleOrNull();

      if (supplier == null) {
        return const FailureResult(NotFoundFailure(message: 'المورد غير موجود'));
      }

      final startOfDay = DateTime(from.year, from.month, from.day, 0, 0, 0);
      final endOfDay = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);

      final priorEntry = await (_db.select(_db.supplierLedgerEntries)
            ..where((e) =>
                e.supplierId.equals(supplierId) &
                e.createdAt.isSmallerThanValue(startOfDay))
            ..orderBy([(e) => OrderingTerm.desc(e.id)])
            ..limit(1))
          .getSingleOrNull();

      final openingBalancePiastres = priorEntry?.balanceAfter ?? 0;

      final rangeEntries = await (_db.select(_db.supplierLedgerEntries)
            ..where((e) =>
                e.supplierId.equals(supplierId) &
                e.createdAt.isBiggerOrEqualValue(startOfDay) &
                e.createdAt.isSmallerOrEqualValue(endOfDay))
            ..orderBy([(e) => OrderingTerm.asc(e.id)]))
          .get();

      var totalDebitPiastres = 0;
      var totalCreditPiastres = 0;

      final items = rangeEntries.map((e) {
        // Supplier: debt to supplier increase = credit (له), decrease = debit (عليه/مسدد)
        final isCredit = e.effect == 'increase';
        final debitPiastres = isCredit ? 0 : e.amount;
        final creditPiastres = isCredit ? e.amount : 0;

        totalDebitPiastres += debitPiastres;
        totalCreditPiastres += creditPiastres;

        String description;
        switch (e.entryType) {
          case 'purchase':
            description = 'فاتورة شراء';
            break;
          case 'payment':
            description = 'سداد لمورد';
            break;
          case 'supplier_return':
            description = 'مرتجع مشتريات لمورد';
            break;
          case 'opening_balance':
            description = 'رصيد افتتاحي';
            break;
          case 'reversal':
            description = 'إلغاء / عكس عملية';
            break;
          default:
            description = e.entryType;
        }

        if (e.note != null && e.note!.isNotEmpty) {
          description += ' (${e.note})';
        }

        return SupplierLedgerReportItem(
          id: e.id,
          date: e.createdAt,
          entryType: e.entryType,
          description: description,
          debit: Money.fromPiastres(debitPiastres),
          credit: Money.fromPiastres(creditPiastres),
          balanceAfter: Money.fromPiastres(e.balanceAfter),
        );
      }).toList();

      final closingBalancePiastres = rangeEntries.isNotEmpty
          ? rangeEntries.last.balanceAfter
          : openingBalancePiastres;

      return Success(
        SupplierAccountReport(
          supplierId: supplier.id,
          supplierName: supplier.name,
          from: from,
          to: to,
          openingBalance: Money.fromPiastres(openingBalancePiastres),
          closingBalance: Money.fromPiastres(closingBalancePiastres),
          totalDebit: Money.fromPiastres(totalDebitPiastres),
          totalCredit: Money.fromPiastres(totalCreditPiastres),
          entries: items,
        ),
      );
    } catch (e) {
      return FailureResult(
        DatabaseFailure(message: 'فشل إنشاء كشف حساب المورد: $e'),
      );
    }
  }

  @override
  Future<Result<List<SupplierBalanceSummary>>> getAllSupplierBalances() async {
    try {
      final rows = await (_db.select(_db.suppliers)
            ..where((s) => s.isActive.equals(true))
            ..orderBy([(s) => OrderingTerm.desc(s.currentBalance)]))
          .get();

      final result = rows
          .map((s) => SupplierBalanceSummary(
                supplierId: s.id,
                supplierName: s.name,
                phone: s.phone,
                balance: Money.fromPiastres(s.currentBalance),
              ))
          .toList();

      return Success(result);
    } catch (e) {
      return FailureResult(
        DatabaseFailure(message: 'فشل جلب مستحقات الموردين: $e'),
      );
    }
  }

  @override
  Future<Result<InventoryReport>> getInventoryReport({
    int? productId,
    String? movementType,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      // 1. Fetch Products
      final productsQuery = _db.select(_db.products)
        ..where((p) => p.isActive.equals(true));

      if (productId != null) {
        productsQuery.where((p) => p.id.equals(productId));
      }
      productsQuery.orderBy([(p) => OrderingTerm.asc(p.name)]);

      final products = await productsQuery.get();

      var totalValuationPiastres = 0;
      var lowStockCount = 0;

      final productItems = products.map((p) {
        final qty = p.currentQuantity;
        final cost = p.currentPurchasePrice;
        // valuation = cost * qty
        final valuationPiastres = (qty * Decimal.fromInt(cost)).toBigInt().toInt();
        totalValuationPiastres += valuationPiastres;

        final isLow = p.lowStockThreshold != null && qty <= p.lowStockThreshold!;
        if (isLow) lowStockCount++;

        return InventoryReportItem(
          productId: p.id,
          productName: p.name,
          code: p.code,
          unit: p.unit,
          currentQuantity: qty,
          currentPurchasePrice: Money.fromPiastres(p.currentPurchasePrice),
          currentSalePrice: Money.fromPiastres(p.currentSalePrice),
          totalValuationAtCost: Money.fromPiastres(valuationPiastres),
          isLowStock: isLow,
        );
      }).toList();

      // 2. Fetch Movements
      final movementsQuery = _db.select(_db.inventoryMovements).join([
        innerJoin(
          _db.products,
          _db.products.id.equalsExp(_db.inventoryMovements.productId),
        ),
      ]);

      if (productId != null) {
        movementsQuery.where(_db.inventoryMovements.productId.equals(productId));
      }

      if (movementType != null && movementType.isNotEmpty) {
        movementsQuery.where(_db.inventoryMovements.movementType.equals(movementType));
      }

      if (from != null) {
        final start = DateTime(from.year, from.month, from.day, 0, 0, 0);
        movementsQuery.where(_db.inventoryMovements.createdAt.isBiggerOrEqualValue(start));
      }

      if (to != null) {
        final end = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
        movementsQuery.where(_db.inventoryMovements.createdAt.isSmallerOrEqualValue(end));
      }

      movementsQuery.orderBy([OrderingTerm.desc(_db.inventoryMovements.id)]);
      movementsQuery.limit(250);

      final movementRows = await movementsQuery.get();

      final movementItems = movementRows.map((row) {
        final m = row.readTable(_db.inventoryMovements);
        final p = row.readTable(_db.products);

        String typeArabic;
        switch (m.movementType) {
          case 'sale':
            typeArabic = 'صرف مبيعات (-)';
            break;
          case 'purchase':
            typeArabic = 'وارد مشتريات (+)';
            break;
          case 'customer_return':
            typeArabic = 'مرتجع مبيعات (+)';
            break;
          case 'supplier_return':
            typeArabic = 'مرتجع لمورد (-)';
            break;
          case 'adjustment':
            typeArabic = 'تسوية مخزنية';
            break;
          case 'opening_balance':
            typeArabic = 'رصيد افتتاحي';
            break;
          case 'reversal':
            typeArabic = 'عكس حركة';
            break;
          default:
            typeArabic = m.movementType;
        }

        return InventoryMovementReportItem(
          id: m.id,
          date: m.createdAt,
          productName: p.name,
          movementType: typeArabic,
          quantityDelta: m.quantityDelta,
          balanceAfter: m.balanceAfter,
          note: m.note,
        );
      }).toList();

      return Success(
        InventoryReport(
          totalValuationAtCost: Money.fromPiastres(totalValuationPiastres),
          totalProductsCount: productItems.length,
          lowStockProductsCount: lowStockCount,
          products: productItems,
          movements: movementItems,
        ),
      );
    } catch (e) {
      return FailureResult(
        DatabaseFailure(message: 'فشل إنشاء تقرير المخزون: $e'),
      );
    }
  }

  @override
  Future<Result<CashboxReport>> getCashboxReport({
    required DateTime from,
    required DateTime to,
    String? transactionType,
  }) async {
    try {
      final startOfDay = DateTime(from.year, from.month, from.day, 0, 0, 0);
      final endOfDay = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);

      // Prior balance
      final priorTx = await (_db.select(_db.cashboxTransactions)
            ..where((t) => t.createdAt.isSmallerThanValue(startOfDay))
            ..orderBy([(t) => OrderingTerm.desc(t.id)])
            ..limit(1))
          .getSingleOrNull();

      final openingBalancePiastres = priorTx?.balanceAfter ?? 0;

      // Range transactions
      final query = _db.select(_db.cashboxTransactions)
        ..where((t) =>
            t.createdAt.isBiggerOrEqualValue(startOfDay) &
            t.createdAt.isSmallerOrEqualValue(endOfDay));

      if (transactionType != null && transactionType.isNotEmpty) {
        query.where((t) => t.transactionType.equals(transactionType));
      }

      query.orderBy([(t) => OrderingTerm.asc(t.id)]);

      final rangeTxs = await query.get();

      var totalInPiastres = 0;
      var totalOutPiastres = 0;

      final items = rangeTxs.map((t) {
        if (t.direction == 'in') {
          totalInPiastres += t.amount;
        } else {
          totalOutPiastres += t.amount;
        }

        String typeArabic;
        switch (t.transactionType) {
          case 'sale_cash_in':
            typeArabic = 'مبيعات نقدية';
            break;
          case 'customer_payment_in':
            typeArabic = 'تحصيل من عميل';
            break;
          case 'purchase_cash_out':
            typeArabic = 'مشتريات نقدية';
            break;
          case 'supplier_payment_out':
            typeArabic = 'سداد لمورد';
            break;
          case 'expense_out':
            typeArabic = 'مصروفات تشغيلية';
            break;
          case 'opening_balance':
            typeArabic = 'رصيد افتتاحي';
            break;
          case 'reversal':
            typeArabic = 'عكس حركة';
            break;
          default:
            typeArabic = t.transactionType;
        }

        return CashboxReportItem(
          id: t.id,
          date: t.createdAt,
          transactionType: typeArabic,
          direction: t.direction,
          amount: Money.fromPiastres(t.amount),
          balanceAfter: Money.fromPiastres(t.balanceAfter),
          note: t.note,
        );
      }).toList();

      final netPiastres = totalInPiastres - totalOutPiastres;
      final closingBalancePiastres = rangeTxs.isNotEmpty
          ? rangeTxs.last.balanceAfter
          : openingBalancePiastres;

      return Success(
        CashboxReport(
          from: from,
          to: to,
          openingBalance: Money.fromPiastres(openingBalancePiastres),
          closingBalance: Money.fromPiastres(closingBalancePiastres),
          totalIn: Money.fromPiastres(totalInPiastres),
          totalOut: Money.fromPiastres(totalOutPiastres),
          netCashflow: Money.fromPiastres(netPiastres),
          transactions: items,
        ),
      );
    } catch (e) {
      return FailureResult(
        DatabaseFailure(message: 'فشل إنشاء تقرير الخزينة: $e'),
      );
    }
  }

  @override
  Future<Result<ProfitReport>> getProfitReport({
    required DateTime from,
    required DateTime to,
    int? productId,
  }) async {
    try {
      final startOfDay = DateTime(from.year, from.month, from.day, 0, 0, 0);
      final endOfDay = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);

      final query = _db.select(_db.saleItems).join([
        innerJoin(
          _db.sales,
          _db.sales.id.equalsExp(_db.saleItems.saleId),
        ),
        innerJoin(
          _db.products,
          _db.products.id.equalsExp(_db.saleItems.productId),
        ),
      ]);

      query.where(
        _db.sales.saleDate.isBiggerOrEqualValue(startOfDay) &
            _db.sales.saleDate.isSmallerOrEqualValue(endOfDay) &
            _db.sales.status.equals('confirmed'),
      );

      if (productId != null) {
        query.where(_db.saleItems.productId.equals(productId));
      }

      final rows = await query.get();

      final Map<int, _ProductProfitAccumulator> map = {};

      for (final row in rows) {
        final item = row.readTable(_db.saleItems);
        final product = row.readTable(_db.products);

        final pId = product.id;
        final revenue = item.lineTotal;
        final cost = (item.quantity * Decimal.fromInt(product.currentPurchasePrice)).toBigInt().toInt();

        final acc = map.putIfAbsent(
          pId,
          () => _ProductProfitAccumulator(
            productId: pId,
            productName: product.name,
            unit: product.unit,
          ),
        );

        acc.soldQuantity += item.quantity;
        acc.totalRevenuePiastres += revenue;
        acc.totalCostPiastres += cost;
      }

      var overallRevenuePiastres = 0;
      var overallCostPiastres = 0;

      final List<ProfitReportItem> items = [];

      for (final acc in map.values) {
        final grossProfit = acc.totalRevenuePiastres - acc.totalCostPiastres;
        final margin = acc.totalRevenuePiastres > 0
            ? (grossProfit / acc.totalRevenuePiastres) * 100
            : 0.0;

        overallRevenuePiastres += acc.totalRevenuePiastres;
        overallCostPiastres += acc.totalCostPiastres;

        items.add(
          ProfitReportItem(
            productId: acc.productId,
            productName: acc.productName,
            unit: acc.unit,
            soldQuantity: acc.soldQuantity,
            totalRevenue: Money.fromPiastres(acc.totalRevenuePiastres),
            totalCost: Money.fromPiastres(acc.totalCostPiastres),
            grossProfit: Money.fromPiastres(grossProfit),
            marginPercentage: double.parse(margin.toStringAsFixed(1)),
          ),
        );
      }

      items.sort((a, b) => b.grossProfit.piastres.compareTo(a.grossProfit.piastres));

      final overallProfitPiastres = overallRevenuePiastres - overallCostPiastres;
      final overallMargin = overallRevenuePiastres > 0
          ? (overallProfitPiastres / overallRevenuePiastres) * 100
          : 0.0;

      return Success(
        ProfitReport(
          from: from,
          to: to,
          totalRevenue: Money.fromPiastres(overallRevenuePiastres),
          totalCost: Money.fromPiastres(overallCostPiastres),
          totalGrossProfit: Money.fromPiastres(overallProfitPiastres),
          overallMarginPercentage: double.parse(overallMargin.toStringAsFixed(1)),
          items: items,
        ),
      );
    } catch (e) {
      return FailureResult(
        DatabaseFailure(message: 'فشل إنشاء تقرير الأرباح: $e'),
      );
    }
  }
}

class _ProductProfitAccumulator {
  final int productId;
  final String productName;
  final String unit;
  Decimal soldQuantity = Decimal.zero;
  int totalRevenuePiastres = 0;
  int totalCostPiastres = 0;

  _ProductProfitAccumulator({
    required this.productId,
    required this.productName,
    required this.unit,
  });
}
