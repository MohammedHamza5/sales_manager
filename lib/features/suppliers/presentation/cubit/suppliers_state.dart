import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/supplier.dart';

sealed class SuppliersState extends Equatable {
  const SuppliersState();

  @override
  List<Object?> get props => [];
}

class SuppliersInitial extends SuppliersState {
  const SuppliersInitial();
}

class SuppliersLoading extends SuppliersState {
  const SuppliersLoading();
}

class SuppliersEmpty extends SuppliersState {
  final String message;
  final bool hasActiveFilters;

  const SuppliersEmpty({
    required this.message,
    this.hasActiveFilters = false,
  });

  @override
  List<Object?> get props => [message, hasActiveFilters];
}

class SuppliersError extends SuppliersState {
  final String message;

  const SuppliersError({required this.message});

  @override
  List<Object?> get props => [message];
}

class SuppliersLoaded extends SuppliersState {
  final List<Supplier> suppliers;
  final String searchQuery;
  final bool showDueOnly; // مستحق لهم ديون فقط (currentBalance > 0)
  final bool? activeFilter; // null = all, true = active, false = deactivated
  final Money totalDueAmount; // إجمالي المبالغ المستحقة لجميع الموردين
  final int totalDueSuppliersCount; // عدد الموردين المستحق لهم مبالغ

  const SuppliersLoaded({
    required this.suppliers,
    this.searchQuery = '',
    this.showDueOnly = false,
    this.activeFilter = true, // Default: show active
    required this.totalDueAmount,
    required this.totalDueSuppliersCount,
  });

  bool get hasActiveFilters =>
      searchQuery.trim().isNotEmpty || showDueOnly || activeFilter != true;

  List<Supplier> get filteredSuppliers {
    return suppliers.where((s) {
      // 1. Active status filter
      if (activeFilter != null && s.isActive != activeFilter) {
        return false;
      }

      // 2. Due balance filter (مستحق له دين)
      if (showDueOnly && !s.hasBalanceDue) {
        return false;
      }

      // 3. Search query
      if (searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        final matchName = s.name.toLowerCase().contains(query);
        final matchPhone = s.phone?.toLowerCase().contains(query) ?? false;
        final matchAddress = s.address?.toLowerCase().contains(query) ?? false;
        if (!matchName && !matchPhone && !matchAddress) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  SuppliersLoaded copyWith({
    List<Supplier>? suppliers,
    String? searchQuery,
    bool? showDueOnly,
    bool? Function()? activeFilter,
    Money? totalDueAmount,
    int? totalDueSuppliersCount,
  }) {
    return SuppliersLoaded(
      suppliers: suppliers ?? this.suppliers,
      searchQuery: searchQuery ?? this.searchQuery,
      showDueOnly: showDueOnly ?? this.showDueOnly,
      activeFilter:
          activeFilter != null ? activeFilter() : this.activeFilter,
      totalDueAmount: totalDueAmount ?? this.totalDueAmount,
      totalDueSuppliersCount:
          totalDueSuppliersCount ?? this.totalDueSuppliersCount,
    );
  }

  @override
  List<Object?> get props => [
        suppliers,
        searchQuery,
        showDueOnly,
        activeFilter,
        totalDueAmount,
        totalDueSuppliersCount,
      ];
}
