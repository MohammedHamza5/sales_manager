import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/purchase.dart';

sealed class PurchasesListState extends Equatable {
  const PurchasesListState();

  @override
  List<Object?> get props => [];
}

final class PurchasesListInitial extends PurchasesListState {
  const PurchasesListInitial();
}

final class PurchasesListLoading extends PurchasesListState {
  const PurchasesListLoading();
}

final class PurchasesListEmpty extends PurchasesListState {
  final String message;

  const PurchasesListEmpty({
    this.message = 'لا توجد فواتير مشتريات مسجلة حتى الآن',
  });

  @override
  List<Object?> get props => [message];
}

final class PurchasesListError extends PurchasesListState {
  final String message;

  const PurchasesListError({required this.message});

  @override
  List<Object?> get props => [message];
}

final class PurchasesListLoaded extends PurchasesListState {
  final List<Purchase> purchases;
  final String searchQuery;
  final PurchaseStatus? statusFilter;
  final int? supplierIdFilter;

  const PurchasesListLoaded({
    required this.purchases,
    this.searchQuery = '',
    this.statusFilter,
    this.supplierIdFilter,
  });

  List<Purchase> get filteredPurchases {
    return purchases.where((p) {
      if (statusFilter != null && p.status != statusFilter) {
        return false;
      }
      if (supplierIdFilter != null && p.supplierId != supplierIdFilter) {
        return false;
      }
      if (searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim();
        final matchesInvoice = p.invoiceNo.toString().contains(q);
        final matchesSupplier = p.supplierName.contains(q);
        final matchesNote = p.note?.contains(q) ?? false;
        if (!matchesInvoice && !matchesSupplier && !matchesNote) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Money get totalPurchasesAmount => filteredPurchases.fold(
        Money.zero,
        (sum, p) => p.isConfirmed ? sum + p.totalAmount : sum,
      );

  Money get totalPaidAmount => filteredPurchases.fold(
        Money.zero,
        (sum, p) => p.isConfirmed ? sum + p.paidAmountAtCreation : sum,
      );

  Money get totalRemainingAmount => filteredPurchases.fold(
        Money.zero,
        (sum, p) => p.isConfirmed ? sum + p.remainingAmount : sum,
      );

  int get confirmedCount =>
      filteredPurchases.where((p) => p.isConfirmed).length;

  int get reversedCount => filteredPurchases.where((p) => p.isReversed).length;

  PurchasesListLoaded copyWith({
    List<Purchase>? purchases,
    String? searchQuery,
    PurchaseStatus? Function()? statusFilter,
    int? Function()? supplierIdFilter,
  }) {
    return PurchasesListLoaded(
      purchases: purchases ?? this.purchases,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter:
          statusFilter != null ? statusFilter() : this.statusFilter,
      supplierIdFilter: supplierIdFilter != null
          ? supplierIdFilter()
          : this.supplierIdFilter,
    );
  }

  @override
  List<Object?> get props => [
        purchases,
        searchQuery,
        statusFilter,
        supplierIdFilter,
      ];
}
