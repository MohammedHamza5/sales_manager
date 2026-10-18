import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';

/// Pure Dart entity representing an individual item within a sales invoice.
class SaleItem extends Equatable {
  final int id;
  final int saleId;
  final int productId;
  final String productName;
  final String productCode;
  final String productUnit;
  final Decimal quantity;
  final Money unitPriceAtSale; // Snapshot بالقرش
  final Money lineTotal; // بالقرش
  final DateTime createdAt;

  const SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    this.productName = '',
    this.productCode = '',
    this.productUnit = '',
    required this.quantity,
    required this.unitPriceAtSale,
    required this.lineTotal,
    required this.createdAt,
  });

  SaleItem copyWith({
    int? id,
    int? saleId,
    int? productId,
    String? productName,
    String? productCode,
    String? productUnit,
    Decimal? quantity,
    Money? unitPriceAtSale,
    Money? lineTotal,
    DateTime? createdAt,
  }) {
    return SaleItem(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      productUnit: productUnit ?? this.productUnit,
      quantity: quantity ?? this.quantity,
      unitPriceAtSale: unitPriceAtSale ?? this.unitPriceAtSale,
      lineTotal: lineTotal ?? this.lineTotal,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        saleId,
        productId,
        productName,
        productCode,
        productUnit,
        quantity,
        unitPriceAtSale,
        lineTotal,
        createdAt,
      ];
}
