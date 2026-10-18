import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';

class InventoryReportItem extends Equatable {
  final int productId;
  final String productName;
  final String? code;
  final String unit;
  final Decimal currentQuantity;
  final Money currentPurchasePrice;
  final Money currentSalePrice;
  final Money totalValuationAtCost;
  final bool isLowStock;

  const InventoryReportItem({
    required this.productId,
    required this.productName,
    this.code,
    required this.unit,
    required this.currentQuantity,
    required this.currentPurchasePrice,
    required this.currentSalePrice,
    required this.totalValuationAtCost,
    required this.isLowStock,
  });

  @override
  List<Object?> get props => [
        productId,
        productName,
        code,
        unit,
        currentQuantity,
        currentPurchasePrice,
        currentSalePrice,
        totalValuationAtCost,
        isLowStock,
      ];
}

class InventoryMovementReportItem extends Equatable {
  final int id;
  final DateTime date;
  final String productName;
  final String movementType;
  final Decimal quantityDelta;
  final Decimal balanceAfter;
  final String? note;

  const InventoryMovementReportItem({
    required this.id,
    required this.date,
    required this.productName,
    required this.movementType,
    required this.quantityDelta,
    required this.balanceAfter,
    this.note,
  });

  @override
  List<Object?> get props => [
        id,
        date,
        productName,
        movementType,
        quantityDelta,
        balanceAfter,
        note,
      ];
}

class InventoryReport extends Equatable {
  final Money totalValuationAtCost;
  final int totalProductsCount;
  final int lowStockProductsCount;
  final List<InventoryReportItem> products;
  final List<InventoryMovementReportItem> movements;

  const InventoryReport({
    required this.totalValuationAtCost,
    required this.totalProductsCount,
    required this.lowStockProductsCount,
    required this.products,
    required this.movements,
  });

  @override
  List<Object?> get props => [
        totalValuationAtCost,
        totalProductsCount,
        lowStockProductsCount,
        products,
        movements,
      ];
}
