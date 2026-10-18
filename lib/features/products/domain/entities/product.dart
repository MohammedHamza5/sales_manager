import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';

/// Pure Dart Product Entity (100% free of Flutter/Drift dependencies).
class Product extends Equatable {
  final int id;
  final String name;
  final String? code;
  final String unit;
  final Money currentSalePrice;
  final Money currentPurchasePrice;
  final Decimal currentQuantity;
  final Decimal? lowStockThreshold;
  final bool isActive;
  final DateTime createdAt;
  final String createdBy;

  const Product({
    required this.id,
    required this.name,
    this.code,
    required this.unit,
    required this.currentSalePrice,
    required this.currentPurchasePrice,
    required this.currentQuantity,
    this.lowStockThreshold,
    this.isActive = true,
    required this.createdAt,
    this.createdBy = 'admin',
  });

  /// Check if stock is at or below the low stock alert threshold.
  bool get isLowStock {
    if (lowStockThreshold == null) return false;
    return currentQuantity <= lowStockThreshold!;
  }

  /// Check if stock is completely depleted.
  bool get isOutOfStock => currentQuantity <= Decimal.zero;

  /// Theoretical margin per unit based on current prices.
  Money get currentUnitMargin => currentSalePrice - currentPurchasePrice;

  Product copyWith({
    int? id,
    String? name,
    String? code,
    String? unit,
    Money? currentSalePrice,
    Money? currentPurchasePrice,
    Decimal? currentQuantity,
    Decimal? lowStockThreshold,
    bool? isActive,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      unit: unit ?? this.unit,
      currentSalePrice: currentSalePrice ?? this.currentSalePrice,
      currentPurchasePrice: currentPurchasePrice ?? this.currentPurchasePrice,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        code,
        unit,
        currentSalePrice,
        currentPurchasePrice,
        currentQuantity,
        lowStockThreshold,
        isActive,
        createdAt,
        createdBy,
      ];
}
