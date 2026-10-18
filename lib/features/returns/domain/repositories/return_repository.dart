import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';
import '../../../../core/result/result.dart';
import '../entities/customer_return.dart';
import '../entities/supplier_return.dart';

class ReturnItemParam extends Equatable {
  final int productId;
  final Decimal quantity;
  final Money unitPrice;

  const ReturnItemParam({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });

  Money get lineTotal => Money.fromPiastres(
        (Decimal.fromInt(unitPrice.piastres) * quantity).toBigInt().toInt(),
      );

  @override
  List<Object?> get props => [productId, quantity, unitPrice];
}

class CreateCustomerReturnParams extends Equatable {
  final int? originalSaleId;
  final int customerId;
  final DateTime returnDate;
  final List<ReturnItemParam> items;
  final String? note;
  final String createdBy;
  final Money refundCashAmount;

  const CreateCustomerReturnParams({
    this.originalSaleId,
    required this.customerId,
    required this.returnDate,
    required this.items,
    this.note,
    this.createdBy = 'admin',
    this.refundCashAmount = Money.zero,
  });

  Money get totalAmount => items.fold(
        Money.zero,
        (acc, item) => acc + item.lineTotal,
      );

  @override
  List<Object?> get props => [
        originalSaleId,
        customerId,
        returnDate,
        items,
        note,
        createdBy,
        refundCashAmount,
      ];
}

class CreateSupplierReturnParams extends Equatable {
  final int? originalPurchaseId;
  final int supplierId;
  final DateTime returnDate;
  final List<ReturnItemParam> items;
  final String? note;
  final String createdBy;
  final Money refundCashAmount;

  const CreateSupplierReturnParams({
    this.originalPurchaseId,
    required this.supplierId,
    required this.returnDate,
    required this.items,
    this.note,
    this.createdBy = 'admin',
    this.refundCashAmount = Money.zero,
  });

  Money get totalAmount => items.fold(
        Money.zero,
        (acc, item) => acc + item.lineTotal,
      );

  @override
  List<Object?> get props => [
        originalPurchaseId,
        supplierId,
        returnDate,
        items,
        note,
        createdBy,
        refundCashAmount,
      ];
}

abstract class ReturnRepository {
  /// Atomically processes a customer return:
  /// - Restores product quantities with positive movement ('customer_return')
  /// - Reduces customer debt with ledger entry ('return', 'decrease')
  /// - Records audit log inside the same transaction.
  Future<Result<CustomerReturn>> createCustomerReturn(
    CreateCustomerReturnParams params,
  );

  Future<Result<List<CustomerReturn>>> getCustomerReturns({
    int? customerId,
    DateTime? fromDate,
    DateTime? toDate,
    String? query,
  });

  Stream<List<CustomerReturn>> watchCustomerReturns({
    int? customerId,
    DateTime? fromDate,
    DateTime? toDate,
    String? query,
  });

  /// Atomically processes a supplier return:
  /// - Strictly validates that available stock is sufficient (no negative stock)
  /// - Deducts product quantities with negative movement ('supplier_return')
  /// - Reduces supplier dues with ledger entry ('return', 'decrease')
  /// - Records audit log inside the same transaction.
  Future<Result<SupplierReturn>> createSupplierReturn(
    CreateSupplierReturnParams params,
  );

  Future<Result<List<SupplierReturn>>> getSupplierReturns({
    int? supplierId,
    DateTime? fromDate,
    DateTime? toDate,
    String? query,
  });

  Stream<List<SupplierReturn>> watchSupplierReturns({
    int? supplierId,
    DateTime? fromDate,
    DateTime? toDate,
    String? query,
  });
}
