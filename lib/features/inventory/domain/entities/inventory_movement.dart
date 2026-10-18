import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

enum MovementType {
  openingBalance('opening_balance', 'رصيد افتتاحي'),
  purchase('purchase', 'فاتورة شراء'),
  sale('sale', 'فاتورة بيع'),
  customerReturn('customer_return', 'مرتجع من عميل'),
  supplierReturn('supplier_return', 'مرتجع إلى مورد'),
  adjustment('adjustment', 'تسوية مخزنية'),
  reversal('reversal', 'إلغاء / عكس عملية');

  final String value;
  final String arabicTitle;

  const MovementType(this.value, this.arabicTitle);

  static MovementType fromString(String val) {
    return MovementType.values.firstWhere(
      (e) => e.value == val,
      orElse: () => MovementType.adjustment,
    );
  }
}

/// Pure Dart Entity representing a single inventory ledger movement.
class InventoryMovement extends Equatable {
  final int id;
  final int productId;
  final String? productName;
  final String? productUnit;
  final MovementType type;
  final Decimal quantityDelta;
  final Decimal balanceAfter;
  final String? referenceType;
  final int? referenceId;
  final String? note;
  final DateTime createdAt;
  final String createdBy;

  const InventoryMovement({
    required this.id,
    required this.productId,
    this.productName,
    this.productUnit,
    required this.type,
    required this.quantityDelta,
    required this.balanceAfter,
    this.referenceType,
    this.referenceId,
    this.note,
    required this.createdAt,
    this.createdBy = 'admin',
  });

  bool get isInflow => quantityDelta > Decimal.zero;
  bool get isOutflow => quantityDelta < Decimal.zero;

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        productUnit,
        type,
        quantityDelta,
        balanceAfter,
        referenceType,
        referenceId,
        note,
        createdAt,
        createdBy,
      ];
}
