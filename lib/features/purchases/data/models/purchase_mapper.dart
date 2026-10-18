import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/entities/purchase_item.dart';
import '../../domain/repositories/purchase_repository.dart';

abstract final class PurchaseMapper {
  static Purchase toDomain(
    PurchaseEntry entry, {
    String supplierName = '',
    List<PurchaseItem> items = const [],
  }) {
    return Purchase(
      id: entry.id,
      invoiceNo: entry.invoiceNo,
      supplierId: entry.supplierId,
      supplierName: supplierName,
      purchaseDate: entry.purchaseDate,
      totalAmount: Money.fromPiastres(entry.totalAmount),
      paidAmountAtCreation: Money.fromPiastres(entry.paidAmountAtCreation),
      status: PurchaseStatus.fromValue(entry.status),
      note: entry.note,
      items: items,
      createdAt: entry.createdAt,
      createdBy: entry.createdBy,
    );
  }

  static PurchaseItem itemToDomain(
    PurchaseItemEntry entry, {
    String productName = '',
    String productUnit = '',
  }) {
    return PurchaseItem(
      id: entry.id,
      purchaseId: entry.purchaseId,
      productId: entry.productId,
      productName: productName,
      productUnit: productUnit,
      quantity: entry.quantity,
      unitCostAtPurchase: Money.fromPiastres(entry.unitCostAtPurchase),
      lineTotal: Money.fromPiastres(entry.lineTotal),
      createdAt: entry.createdAt,
    );
  }

  static PurchasesCompanion toCompanion({
    required int invoiceNo,
    required int supplierId,
    required DateTime purchaseDate,
    required Money totalAmount,
    required Money paidAmountAtCreation,
    String status = 'confirmed',
    String? note,
    DateTime? createdAt,
    String createdBy = 'admin',
  }) {
    return PurchasesCompanion.insert(
      invoiceNo: invoiceNo,
      supplierId: supplierId,
      purchaseDate: purchaseDate,
      totalAmount: totalAmount.piastres,
      paidAmountAtCreation: paidAmountAtCreation.piastres,
      status: Value(status),
      note: Value(note),
      createdAt: createdAt != null ? Value(createdAt) : const Value.absent(),
      createdBy: Value(createdBy),
    );
  }

  static PurchaseItemsCompanion itemToCompanion({
    required int purchaseId,
    required PurchaseItemParam itemParam,
    DateTime? createdAt,
  }) {
    return PurchaseItemsCompanion.insert(
      purchaseId: purchaseId,
      productId: itemParam.productId,
      quantity: itemParam.quantity,
      unitCostAtPurchase: itemParam.unitCost.piastres,
      lineTotal: itemParam.lineTotal.piastres,
      createdAt: createdAt != null ? Value(createdAt) : const Value.absent(),
    );
  }
}
