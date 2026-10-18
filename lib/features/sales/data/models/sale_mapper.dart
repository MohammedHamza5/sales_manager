import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/sale_item.dart';
import '../../domain/repositories/sale_repository.dart';

abstract final class SaleMapper {
  static Sale toDomain(
    SaleEntry entry, {
    String customerName = '',
    String? customerPhone,
    List<SaleItem> items = const [],
    Money returnedAmount = Money.zero,
  }) {
    return Sale(
      id: entry.id,
      invoiceNo: entry.invoiceNo,
      customerId: entry.customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      saleDate: entry.saleDate,
      totalAmount: Money.fromPiastres(entry.totalAmount),
      paidAmountAtCreation: Money.fromPiastres(entry.paidAmountAtCreation),
      returnedAmount: returnedAmount,
      status: SaleStatus.fromValue(entry.status),
      note: entry.note,
      items: items,
      createdAt: entry.createdAt,
      createdBy: entry.createdBy,
    );
  }

  static SaleItem itemToDomain(
    SaleItemEntry entry, {
    String productName = '',
    String productCode = '',
    String productUnit = '',
  }) {
    return SaleItem(
      id: entry.id,
      saleId: entry.saleId,
      productId: entry.productId,
      productName: productName,
      productCode: productCode,
      productUnit: productUnit,
      quantity: entry.quantity,
      unitPriceAtSale: Money.fromPiastres(entry.unitPriceAtSale),
      lineTotal: Money.fromPiastres(entry.lineTotal),
      createdAt: entry.createdAt,
    );
  }

  static SalesCompanion toCompanion({
    required int invoiceNo,
    required int customerId,
    required DateTime saleDate,
    required Money totalAmount,
    required Money paidAmountAtCreation,
    String status = 'confirmed',
    String? note,
    DateTime? createdAt,
    String createdBy = 'admin',
  }) {
    return SalesCompanion.insert(
      invoiceNo: invoiceNo,
      customerId: customerId,
      saleDate: saleDate,
      totalAmount: totalAmount.piastres,
      paidAmountAtCreation: paidAmountAtCreation.piastres,
      status: Value(status),
      note: Value(note),
      createdAt: createdAt != null ? Value(createdAt) : const Value.absent(),
      createdBy: Value(createdBy),
    );
  }

  static SaleItemsCompanion itemToCompanion({
    required int saleId,
    required SaleItemParam itemParam,
    DateTime? createdAt,
  }) {
    return SaleItemsCompanion.insert(
      saleId: saleId,
      productId: itemParam.productId,
      quantity: itemParam.quantity,
      unitPriceAtSale: itemParam.unitPrice.piastres,
      lineTotal: itemParam.lineTotal.piastres,
      createdAt: createdAt != null ? Value(createdAt) : const Value.absent(),
    );
  }
}
