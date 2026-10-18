import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/customer.dart';

sealed class CustomersState extends Equatable {
  const CustomersState();

  @override
  List<Object?> get props => [];
}

class CustomersInitial extends CustomersState {
  const CustomersInitial();
}

class CustomersLoading extends CustomersState {
  const CustomersLoading();
}

class CustomersEmpty extends CustomersState {
  final String message;
  final bool hasActiveFilters;

  const CustomersEmpty({
    required this.message,
    this.hasActiveFilters = false,
  });

  @override
  List<Object?> get props => [message, hasActiveFilters];
}

class CustomersError extends CustomersState {
  final String message;

  const CustomersError({required this.message});

  @override
  List<Object?> get props => [message];
}

class CustomersLoaded extends CustomersState {
  final List<Customer> customers;
  final String searchQuery;
  final bool showDebtorsOnly;
  final bool showCreditorsOnly;
  final bool? activeFilter; // null = all, true = active, false = deactivated
  final Money totalDebtAmount; // إجمالي الديون المستحقة على العملاء
  final int totalDebtorsCount; // عدد العملاء المدينين
  final Money totalCreditAmount; // إجمالي الأرصدة الدائنة للعملاء (مستحقات للعملاء طرفنا)
  final int totalCreditorsCount; // عدد العملاء الدائنين

  const CustomersLoaded({
    required this.customers,
    this.searchQuery = '',
    this.showDebtorsOnly = false,
    this.showCreditorsOnly = false,
    this.activeFilter = true, // Default: show active
    required this.totalDebtAmount,
    required this.totalDebtorsCount,
    this.totalCreditAmount = Money.zero,
    this.totalCreditorsCount = 0,
  });

  bool get hasActiveFilters =>
      searchQuery.trim().isNotEmpty ||
      showDebtorsOnly ||
      showCreditorsOnly ||
      activeFilter != true;

  List<Customer> get filteredCustomers {
    return customers.where((c) {
      // 1. Active status filter
      if (activeFilter != null && c.isActive != activeFilter) {
        return false;
      }

      // 2. Debtors filter
      if (showDebtorsOnly && !c.hasDebt) {
        return false;
      }

      // 3. Creditors filter (customers with credit balance)
      if (showCreditorsOnly && !c.isCreditor) {
        return false;
      }

      // 4. Search query
      if (searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        final matchName = c.name.toLowerCase().contains(query);
        final matchPhone = c.phone?.toLowerCase().contains(query) ?? false;
        final matchAddress = c.address?.toLowerCase().contains(query) ?? false;
        if (!matchName && !matchPhone && !matchAddress) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  CustomersLoaded copyWith({
    List<Customer>? customers,
    String? searchQuery,
    bool? showDebtorsOnly,
    bool? showCreditorsOnly,
    bool? Function()? activeFilter,
    Money? totalDebtAmount,
    int? totalDebtorsCount,
    Money? totalCreditAmount,
    int? totalCreditorsCount,
  }) {
    return CustomersLoaded(
      customers: customers ?? this.customers,
      searchQuery: searchQuery ?? this.searchQuery,
      showDebtorsOnly: showDebtorsOnly ?? this.showDebtorsOnly,
      showCreditorsOnly: showCreditorsOnly ?? this.showCreditorsOnly,
      activeFilter:
          activeFilter != null ? activeFilter() : this.activeFilter,
      totalDebtAmount: totalDebtAmount ?? this.totalDebtAmount,
      totalDebtorsCount: totalDebtorsCount ?? this.totalDebtorsCount,
      totalCreditAmount: totalCreditAmount ?? this.totalCreditAmount,
      totalCreditorsCount: totalCreditorsCount ?? this.totalCreditorsCount,
    );
  }

  @override
  List<Object?> get props => [
        customers,
        searchQuery,
        showDebtorsOnly,
        showCreditorsOnly,
        activeFilter,
        totalDebtAmount,
        totalDebtorsCount,
        totalCreditAmount,
        totalCreditorsCount,
      ];
}
