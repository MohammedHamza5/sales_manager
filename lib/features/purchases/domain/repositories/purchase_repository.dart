import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';
import '../../../../core/result/result.dart';
import '../entities/purchase.dart';

class PurchaseItemParam extends Equatable {
  final int productId;
  final Decimal quantity;
  final Money unitCost;

  const PurchaseItemParam({
    required this.productId,
    required this.quantity,
    required this.unitCost,
  });

  /// Computes line total: quantity * unitCost (in piastres)
  Money get lineTotal => Money.fromPiastres(
        (Decimal.fromInt(unitCost.piastres) * quantity).toBigInt().toInt(),
      );

  @override
  List<Object?> get props => [productId, quantity, unitCost];
}

class CreatePurchaseParams extends Equatable {
  final int supplierId;
  final DateTime purchaseDate;
  final List<PurchaseItemParam> items;
  final Money paidAmountAtCreation;
  final String? note;
  final String createdBy;

  const CreatePurchaseParams({
    required this.supplierId,
    required this.purchaseDate,
    required this.items,
    required this.paidAmountAtCreation,
    this.note,
    this.createdBy = 'admin',
  });

  /// Sum of all line totals.
  Money get totalAmount => items.fold(
        Money.zero,
        (sum, item) => sum + item.lineTotal,
      );

  @override
  List<Object?> get props => [
        supplierId,
        purchaseDate,
        items,
        paidAmountAtCreation,
        note,
        createdBy,
      ];
}

abstract interface class PurchaseRepository {
  Future<Result<Purchase>> createPurchase(CreatePurchaseParams params);

  Future<Result<List<Purchase>>> getPurchases({
    int? supplierId,
    DateTime? fromDate,
    DateTime? toDate,
    PurchaseStatus? status,
    String? query,
  });

  Stream<List<Purchase>> watchPurchases({
    int? supplierId,
    DateTime? fromDate,
    DateTime? toDate,
    PurchaseStatus? status,
    String? query,
  });

  Future<Result<Purchase>> getPurchaseById(int id);

  Future<Result<Purchase>> reversePurchase({
    required int purchaseId,
    String createdBy = 'admin',
  });
}
