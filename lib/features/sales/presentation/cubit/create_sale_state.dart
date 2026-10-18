import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/sale.dart';

class SaleItemDraft extends Equatable {
  final int productId;
  final String productName;
  final String? productCode;
  final String productUnit;
  final Decimal quantity;
  final Money unitPrice;
  final Decimal availableStock;

  const SaleItemDraft({
    required this.productId,
    required this.productName,
    this.productCode,
    required this.productUnit,
    required this.quantity,
    required this.unitPrice,
    required this.availableStock,
  });

  Money get lineTotal => Money.fromPiastres(
        (Decimal.fromInt(unitPrice.piastres) * quantity).toBigInt().toInt(),
      );

  /// Locked decision #6: strict prevention of negative stock.
  bool get isOverselling => quantity > availableStock;

  bool get isValid =>
      quantity > Decimal.zero && unitPrice.piastres >= 0 && !isOverselling;

  Decimal get remainingStockAfterSale => availableStock - quantity;

  SaleItemDraft copyWith({
    int? productId,
    String? productName,
    String? productCode,
    String? productUnit,
    Decimal? quantity,
    Money? unitPrice,
    Decimal? availableStock,
  }) {
    return SaleItemDraft(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      productUnit: productUnit ?? this.productUnit,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      availableStock: availableStock ?? this.availableStock,
    );
  }

  @override
  List<Object?> get props => [
        productId,
        productName,
        productCode,
        productUnit,
        quantity,
        unitPrice,
        availableStock,
      ];
}

sealed class CreateSaleState extends Equatable {
  const CreateSaleState();

  @override
  List<Object?> get props => [];
}

final class CreateSaleInitial extends CreateSaleState {
  const CreateSaleInitial();
}

final class CreateSaleEditing extends CreateSaleState {
  final int? customerId;
  final String? customerName;
  final DateTime saleDate;
  final List<SaleItemDraft> items;
  final Money paidAmount;
  final String? note;
  final bool isSubmitting;
  final String? errorMessage;

  const CreateSaleEditing({
    this.customerId,
    this.customerName,
    required this.saleDate,
    this.items = const [],
    this.paidAmount = Money.zero,
    this.note,
    this.isSubmitting = false,
    this.errorMessage,
  });

  Money get totalAmount => items.fold(
        Money.zero,
        (sum, item) => sum + item.lineTotal,
      );

  Money get remainingAmount => totalAmount - paidAmount;

  bool get isFullyPaid => remainingAmount.piastres <= 0 && items.isNotEmpty;
  bool get isPartial =>
      paidAmount.piastres > 0 && remainingAmount.piastres > 0;
  bool get isCredit => paidAmount.piastres == 0 && items.isNotEmpty;

  bool get hasOverselling => items.any((item) => item.isOverselling);

  bool get canSubmit =>
      customerId != null &&
      items.isNotEmpty &&
      !hasOverselling &&
      !isSubmitting &&
      paidAmount.piastres >= 0 &&
      paidAmount <= totalAmount &&
      items.every((i) => i.isValid);

  CreateSaleEditing copyWith({
    int? customerId,
    String? customerName,
    DateTime? saleDate,
    List<SaleItemDraft>? items,
    Money? paidAmount,
    String? note,
    bool? isSubmitting,
    String? Function()? errorMessage,
  }) {
    return CreateSaleEditing(
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      saleDate: saleDate ?? this.saleDate,
      items: items ?? this.items,
      paidAmount: paidAmount ?? this.paidAmount,
      note: note ?? this.note,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage:
          errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        customerId,
        customerName,
        saleDate,
        items,
        paidAmount,
        note,
        isSubmitting,
        errorMessage,
      ];
}

final class CreateSaleSuccess extends CreateSaleState {
  final Sale sale;

  const CreateSaleSuccess(this.sale);

  @override
  List<Object?> get props => [sale];
}
