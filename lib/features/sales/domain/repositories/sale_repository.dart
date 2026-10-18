import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';
import '../../../../core/result/result.dart';
import '../entities/sale.dart';

class SaleItemParam extends Equatable {
  final int productId;
  final Decimal quantity;
  final Money unitPrice;

  const SaleItemParam({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });

  /// Computes line total: quantity * unitPrice (in piastres)
  Money get lineTotal => Money.fromPiastres(
        (Decimal.fromInt(unitPrice.piastres) * quantity).toBigInt().toInt(),
      );

  @override
  List<Object?> get props => [productId, quantity, unitPrice];
}

class CreateSaleParams extends Equatable {
  final int customerId;
  final DateTime saleDate;
  final List<SaleItemParam> items;
  final Money paidAmountAtCreation;
  final String? note;
  final String createdBy;

  const CreateSaleParams({
    required this.customerId,
    required this.saleDate,
    required this.items,
    required this.paidAmountAtCreation,
    this.note,
    this.createdBy = 'admin',
  });

  /// Sum of all line totals in piastres.
  Money get totalAmount => items.fold(
        Money.zero,
        (acc, item) => acc + item.lineTotal,
      );

  @override
  List<Object?> get props => [
        customerId,
        saleDate,
        items,
        paidAmountAtCreation,
        note,
        createdBy,
      ];
}

abstract class SaleRepository {
  /// Executes complete atomic transaction creating the sale, updating inventory,
  /// posting customer balance/ledger, writing cashbox entry, and recording audit log.
  /// Strictly checks and rejects overselling (negative stock).
  Future<Result<Sale>> createSale(CreateSaleParams params);

  /// Fetches a list of sales with optional filters.
  Future<Result<List<Sale>>> getSales({
    int? customerId,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
    String? query,
  });

  /// Real-time stream of sales with optional filters.
  Stream<List<Sale>> watchSales({
    int? customerId,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
    String? query,
  });

  /// Fetches a single sale by ID including its items.
  Future<Result<Sale>> getSaleById(int id);

  /// Atomically reverses a confirmed sale without hard deletion.
  /// Restores inventory, reverses customer balance, writes reversal cashbox entry,
  /// updates sale status to 'reversed', and writes audit log.
  Future<Result<Sale>> reverseSale(int saleId, {String? reason});
}
