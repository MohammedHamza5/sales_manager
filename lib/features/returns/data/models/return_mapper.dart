import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/customer_return.dart';
import '../../domain/entities/customer_return_item.dart';
import '../../domain/entities/supplier_return.dart';
import '../../domain/entities/supplier_return_item.dart';
import '../../domain/repositories/return_repository.dart';

abstract final class ReturnMapper {
  // -------------------------------------------------------------
  // CUSTOMER RETURNS
  // -------------------------------------------------------------

  static CustomerReturn customerReturnToDomain(
    ReturnCustomerEntry entry, {
    String customerName = '',
    int? originalInvoiceNo,
    List<CustomerReturnItem> items = const [],
  }) {
    return CustomerReturn(
      id: entry.id,
      originalSaleId: entry.originalSaleId,
      originalInvoiceNo: originalInvoiceNo,
      customerId: entry.customerId,
      customerName: customerName,
      returnDate: entry.returnDate,
      totalAmount: Money.fromPiastres(entry.totalAmount),
      note: entry.note,
      items: items,
      createdAt: entry.createdAt,
      createdBy: entry.createdBy,
    );
  }

  static CustomerReturnItem customerReturnItemToDomain(
    ReturnCustomerItemEntry entry, {
    String productName = '',
    String productCode = '',
    String productUnit = '',
  }) {
    return CustomerReturnItem(
      id: entry.id,
      returnId: entry.returnId,
      productId: entry.productId,
      productName: productName,
      productCode: productCode,
      productUnit: productUnit,
      quantity: entry.quantity,
      unitPrice: Money.fromPiastres(entry.unitPrice),
      lineTotal: Money.fromPiastres(entry.lineTotal),
    );
  }

  static ReturnsCustomerCompanion customerReturnToCompanion({
    int? originalSaleId,
    required int customerId,
    required DateTime returnDate,
    required Money totalAmount,
    String? note,
    DateTime? createdAt,
    String createdBy = 'admin',
  }) {
    return ReturnsCustomerCompanion.insert(
      originalSaleId: Value(originalSaleId),
      customerId: customerId,
      returnDate: returnDate,
      totalAmount: totalAmount.piastres,
      note: Value(note),
      createdAt: createdAt != null ? Value(createdAt) : const Value.absent(),
      createdBy: Value(createdBy),
    );
  }

  static ReturnCustomerItemsCompanion customerReturnItemToCompanion({
    required int returnId,
    required ReturnItemParam itemParam,
  }) {
    return ReturnCustomerItemsCompanion.insert(
      returnId: returnId,
      productId: itemParam.productId,
      quantity: itemParam.quantity,
      unitPrice: itemParam.unitPrice.piastres,
      lineTotal: itemParam.lineTotal.piastres,
    );
  }

  // -------------------------------------------------------------
  // SUPPLIER RETURNS
  // -------------------------------------------------------------

  static SupplierReturn supplierReturnToDomain(
    ReturnSupplierEntry entry, {
    String supplierName = '',
    int? originalInvoiceNo,
    List<SupplierReturnItem> items = const [],
  }) {
    return SupplierReturn(
      id: entry.id,
      originalPurchaseId: entry.originalPurchaseId,
      originalInvoiceNo: originalInvoiceNo,
      supplierId: entry.supplierId,
      supplierName: supplierName,
      returnDate: entry.returnDate,
      totalAmount: Money.fromPiastres(entry.totalAmount),
      note: entry.note,
      items: items,
      createdAt: entry.createdAt,
      createdBy: entry.createdBy,
    );
  }

  static SupplierReturnItem supplierReturnItemToDomain(
    ReturnSupplierItemEntry entry, {
    String productName = '',
    String productCode = '',
    String productUnit = '',
  }) {
    return SupplierReturnItem(
      id: entry.id,
      returnId: entry.returnId,
      productId: entry.productId,
      productName: productName,
      productCode: productCode,
      productUnit: productUnit,
      quantity: entry.quantity,
      unitPrice: Money.fromPiastres(entry.unitPrice),
      lineTotal: Money.fromPiastres(entry.lineTotal),
    );
  }

  static ReturnsSupplierCompanion supplierReturnToCompanion({
    int? originalPurchaseId,
    required int supplierId,
    required DateTime returnDate,
    required Money totalAmount,
    String? note,
    DateTime? createdAt,
    String createdBy = 'admin',
  }) {
    return ReturnsSupplierCompanion.insert(
      originalPurchaseId: Value(originalPurchaseId),
      supplierId: supplierId,
      returnDate: returnDate,
      totalAmount: totalAmount.piastres,
      note: Value(note),
      createdAt: createdAt != null ? Value(createdAt) : const Value.absent(),
      createdBy: Value(createdBy),
    );
  }

  static ReturnSupplierItemsCompanion supplierReturnItemToCompanion({
    required int returnId,
    required ReturnItemParam itemParam,
  }) {
    return ReturnSupplierItemsCompanion.insert(
      returnId: returnId,
      productId: itemParam.productId,
      quantity: itemParam.quantity,
      unitPrice: itemParam.unitPrice.piastres,
      lineTotal: itemParam.lineTotal.piastres,
    );
  }
}
