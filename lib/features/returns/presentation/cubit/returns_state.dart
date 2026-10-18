import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/customer_return.dart';
import '../../domain/entities/supplier_return.dart';

sealed class ReturnsState extends Equatable {
  const ReturnsState();

  @override
  List<Object?> get props => [];
}

final class ReturnsInitial extends ReturnsState {
  const ReturnsInitial();
}

final class ReturnsLoading extends ReturnsState {
  const ReturnsLoading();
}

final class ReturnsError extends ReturnsState {
  final String message;

  const ReturnsError({required this.message});

  @override
  List<Object?> get props => [message];
}

final class ReturnsLoaded extends ReturnsState {
  final List<CustomerReturn> customerReturns;
  final List<SupplierReturn> supplierReturns;
  final int selectedTabIndex; // 0: customer, 1: supplier
  final String searchQuery;

  const ReturnsLoaded({
    required this.customerReturns,
    required this.supplierReturns,
    this.selectedTabIndex = 0,
    this.searchQuery = '',
  });

  List<CustomerReturn> get filteredCustomerReturns {
    if (searchQuery.trim().isEmpty) return customerReturns;
    final q = searchQuery.trim();
    return customerReturns.where((r) {
      return r.customerName.contains(q) ||
          r.id.toString().contains(q) ||
          (r.originalInvoiceNo?.toString().contains(q) ?? false);
    }).toList();
  }

  List<SupplierReturn> get filteredSupplierReturns {
    if (searchQuery.trim().isEmpty) return supplierReturns;
    final q = searchQuery.trim();
    return supplierReturns.where((r) {
      return r.supplierName.contains(q) ||
          r.id.toString().contains(q) ||
          (r.originalInvoiceNo?.toString().contains(q) ?? false);
    }).toList();
  }

  Money get totalCustomerReturnsAmount => filteredCustomerReturns.fold(
        Money.zero,
        (sum, r) => sum + r.totalAmount,
      );

  Money get totalSupplierReturnsAmount => filteredSupplierReturns.fold(
        Money.zero,
        (sum, r) => sum + r.totalAmount,
      );

  ReturnsLoaded copyWith({
    List<CustomerReturn>? customerReturns,
    List<SupplierReturn>? supplierReturns,
    int? selectedTabIndex,
    String? searchQuery,
  }) {
    return ReturnsLoaded(
      customerReturns: customerReturns ?? this.customerReturns,
      supplierReturns: supplierReturns ?? this.supplierReturns,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        customerReturns,
        supplierReturns,
        selectedTabIndex,
        searchQuery,
      ];
}
