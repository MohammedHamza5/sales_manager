import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/product.dart';

abstract final class ProductMapper {
  static Product toDomain(ProductEntry entry) {
    return Product(
      id: entry.id,
      name: entry.name,
      code: entry.code,
      unit: entry.unit,
      currentSalePrice: Money.fromPiastres(entry.currentSalePrice),
      currentPurchasePrice: Money.fromPiastres(entry.currentPurchasePrice),
      currentQuantity: entry.currentQuantity,
      lowStockThreshold: entry.lowStockThreshold,
      isActive: entry.isActive,
      createdAt: entry.createdAt,
      createdBy: entry.createdBy,
    );
  }

  static ProductsCompanion toInsertCompanion({
    required String name,
    String? code,
    required String unit,
    required Money salePrice,
    required Money purchasePrice,
    required Decimal initialQuantity,
    Decimal? lowStockThreshold,
    required String createdBy,
  }) {
    return ProductsCompanion.insert(
      name: name,
      code: code == null ? const Value.absent() : Value(code),
      unit: unit,
      currentSalePrice: salePrice.piastres,
      currentPurchasePrice: purchasePrice.piastres,
      currentQuantity: Value(initialQuantity),
      lowStockThreshold: lowStockThreshold == null ? const Value.absent() : Value(lowStockThreshold),
      isActive: const Value(true),
      createdBy: Value(createdBy),
    );
  }
}
