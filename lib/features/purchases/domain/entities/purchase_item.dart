import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';

/// Pure Dart entity representing an individual item within a purchase invoice.
class PurchaseItem extends Equatable {
  final int id;
  final int purchaseId;
  final int productId;
  final String productName;
  final String productUnit;
  final Decimal quantity;
  final Money unitCostAtPurchase; // Snapshot بالقرش
  final Money lineTotal; // بالقرش
  final DateTime createdAt;

  const PurchaseItem({
    required this.id,
    required this.purchaseId,
    required this.productId,
    this.productName = '',
    this.productUnit = '',
    required this.quantity,
    required this.unitCostAtPurchase,
    required this.lineTotal,
    required this.createdAt,
  });

  PurchaseItem copyWith({
    int? id,
    int? purchaseId,
    int? productId,
    String? productName,
    String? productUnit,
    Decimal? quantity,
    Money? unitCostAtPurchase,
    Money? lineTotal,
    DateTime? createdAt,
  }) {
    return PurchaseItem(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productUnit: productUnit ?? this.productUnit,
      quantity: quantity ?? this.quantity,
      unitCostAtPurchase: unitCostAtPurchase ?? this.unitCostAtPurchase,
      lineTotal: lineTotal ?? this.lineTotal,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        purchaseId,
        productId,
        productName,
        productUnit,
        quantity,
        unitCostAtPurchase,
        lineTotal,
        createdAt,
      ];
}
