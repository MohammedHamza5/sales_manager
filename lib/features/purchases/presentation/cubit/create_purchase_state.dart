import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/purchase.dart';

class InvoiceItemDraft extends Equatable {
  final int productId;
  final String productName;
  final String? productCode;
  final String productUnit;
  final Decimal quantity;
  final Money unitCost;
  final Decimal currentStock;

  const InvoiceItemDraft({
    required this.productId,
    required this.productName,
    this.productCode,
    required this.productUnit,
    required this.quantity,
    required this.unitCost,
    required this.currentStock,
  });

  Money get lineTotal => Money(
        (Decimal.fromInt(unitCost.piastres) * quantity).toBigInt().toInt(),
      );

  InvoiceItemDraft copyWith({
    int? productId,
    String? productName,
    String? productCode,
    String? productUnit,
    Decimal? quantity,
    Money? unitCost,
    Decimal? currentStock,
  }) {
    return InvoiceItemDraft(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      productUnit: productUnit ?? this.productUnit,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      currentStock: currentStock ?? this.currentStock,
    );
  }

  @override
  List<Object?> get props => [
        productId,
        productName,
        productCode,
        productUnit,
        quantity,
        unitCost,
        currentStock,
      ];
}

sealed class CreatePurchaseState extends Equatable {
  const CreatePurchaseState();

  @override
  List<Object?> get props => [];
}

final class CreatePurchaseInitial extends CreatePurchaseState {
  const CreatePurchaseInitial();
}

final class CreatePurchaseEditing extends CreatePurchaseState {
  final int? supplierId;
  final String? supplierName;
  final DateTime purchaseDate;
  final List<InvoiceItemDraft> items;
  final Money paidAmount;
  final String? note;
  final bool isSubmitting;
  final String? errorMessage;

  const CreatePurchaseEditing({
    this.supplierId,
    this.supplierName,
    required this.purchaseDate,
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

  bool get isCredit => paidAmount.piastres == 0 && items.isNotEmpty;

  bool get isPartial =>
      paidAmount.piastres > 0 && remainingAmount.piastres > 0;

  bool get canSubmit =>
      supplierId != null &&
      items.isNotEmpty &&
      !isSubmitting &&
      items.every((it) => it.quantity > Decimal.zero);

  CreatePurchaseEditing copyWith({
    int? supplierId,
    String? supplierName,
    DateTime? purchaseDate,
    List<InvoiceItemDraft>? items,
    Money? paidAmount,
    String? note,
    bool? isSubmitting,
    String? errorMessage,
    bool clearSupplier = false,
    bool clearError = false,
  }) {
    return CreatePurchaseEditing(
      supplierId: clearSupplier ? null : (supplierId ?? this.supplierId),
      supplierName:
          clearSupplier ? null : (supplierName ?? this.supplierName),
      purchaseDate: purchaseDate ?? this.purchaseDate,
      items: items ?? this.items,
      paidAmount: paidAmount ?? this.paidAmount,
      note: note ?? this.note,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        supplierId,
        supplierName,
        purchaseDate,
        items,
        paidAmount,
        note,
        isSubmitting,
        errorMessage,
      ];
}

final class CreatePurchaseSuccess extends CreatePurchaseState {
  final Purchase purchase;

  const CreatePurchaseSuccess(this.purchase);

  @override
  List<Object?> get props => [purchase];
}
