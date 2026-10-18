import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';

/// Pure Dart entity representing an individual item within a customer return.
class CustomerReturnItem extends Equatable {
  final int id;
  final int returnId;
  final int productId;
  final String productName;
  final String productCode;
  final String productUnit;
  final Decimal quantity;
  final Money unitPrice; // بالقرش
  final Money lineTotal; // بالقرش

  const CustomerReturnItem({
    required this.id,
    required this.returnId,
    required this.productId,
    this.productName = '',
    this.productCode = '',
    this.productUnit = '',
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  @override
  List<Object?> get props => [
        id,
        returnId,
        productId,
        productName,
        productCode,
        productUnit,
        quantity,
        unitPrice,
        lineTotal,
      ];
}
