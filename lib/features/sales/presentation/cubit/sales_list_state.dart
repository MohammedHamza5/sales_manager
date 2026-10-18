import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/sale.dart';

sealed class SalesListState extends Equatable {
  const SalesListState();

  @override
  List<Object?> get props => [];
}

final class SalesListInitial extends SalesListState {
  const SalesListInitial();
}

final class SalesListLoading extends SalesListState {
  const SalesListLoading();
}

final class SalesListEmpty extends SalesListState {
  final String message;

  const SalesListEmpty({
    this.message = 'لا توجد فواتير مبيعات مسجلة حتى الآن',
  });

  @override
  List<Object?> get props => [message];
}

final class SalesListError extends SalesListState {
  final String message;

  const SalesListError({required this.message});

  @override
  List<Object?> get props => [message];
}

final class SalesListLoaded extends SalesListState {
  final List<Sale> sales;
  final String searchQuery;
  final SaleStatus? statusFilter;
  final int? customerIdFilter;

  const SalesListLoaded({
    required this.sales,
    this.searchQuery = '',
    this.statusFilter,
    this.customerIdFilter,
  });

  List<Sale> get filteredSales {
    return sales.where((s) {
      if (statusFilter != null && s.status != statusFilter) {
        return false;
      }
      if (customerIdFilter != null && s.customerId != customerIdFilter) {
        return false;
      }
      if (searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim();
        final matchesInvoice = s.invoiceNo.toString().contains(q);
        final matchesCustomer = s.customerName.contains(q);
        final matchesPhone = s.customerPhone?.contains(q) ?? false;
        final matchesNote = s.note?.contains(q) ?? false;
        if (!matchesInvoice && !matchesCustomer && !matchesPhone && !matchesNote) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Money get totalSalesAmount => filteredSales.fold(
        Money.zero,
        (sum, s) => s.isConfirmed ? sum + s.totalAmount : sum,
      );

  Money get totalPaidAmount => filteredSales.fold(
        Money.zero,
        (sum, s) => s.isConfirmed ? sum + s.paidAmountAtCreation : sum,
      );

  Money get totalRemainingAmount => filteredSales.fold(
        Money.zero,
        (sum, s) => s.isConfirmed ? sum + s.remainingAmount : sum,
      );

  int get confirmedCount =>
      filteredSales.where((s) => s.isConfirmed).length;

  int get reversedCount => filteredSales.where((s) => s.isReversed).length;

  SalesListLoaded copyWith({
    List<Sale>? sales,
    String? searchQuery,
    SaleStatus? Function()? statusFilter,
    int? Function()? customerIdFilter,
  }) {
    return SalesListLoaded(
      sales: sales ?? this.sales,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter:
          statusFilter != null ? statusFilter() : this.statusFilter,
      customerIdFilter: customerIdFilter != null
          ? customerIdFilter()
          : this.customerIdFilter,
    );
  }

  @override
  List<Object?> get props => [
        sales,
        searchQuery,
        statusFilter,
        customerIdFilter,
      ];
}
