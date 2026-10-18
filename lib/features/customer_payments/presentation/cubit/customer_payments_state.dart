import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/customer_payment.dart';

sealed class CustomerPaymentsState extends Equatable {
  const CustomerPaymentsState();

  @override
  List<Object?> get props => [];
}

final class CustomerPaymentsInitial extends CustomerPaymentsState {
  const CustomerPaymentsInitial();
}

final class CustomerPaymentsLoading extends CustomerPaymentsState {
  const CustomerPaymentsLoading();
}

final class CustomerPaymentsEmpty extends CustomerPaymentsState {
  final int? filteredCustomerId;
  const CustomerPaymentsEmpty({this.filteredCustomerId});

  @override
  List<Object?> get props => [filteredCustomerId];
}

final class CustomerPaymentsError extends CustomerPaymentsState {
  final String message;
  const CustomerPaymentsError(this.message);

  @override
  List<Object?> get props => [message];
}

final class CustomerPaymentsLoaded extends CustomerPaymentsState {
  final List<CustomerPayment> allPayments;
  final List<CustomerPayment> filteredPayments;
  final String searchQuery;
  final int? selectedCustomerId;
  final Money totalCollected;

  const CustomerPaymentsLoaded({
    required this.allPayments,
    required this.filteredPayments,
    this.searchQuery = '',
    this.selectedCustomerId,
    required this.totalCollected,
  });

  CustomerPaymentsLoaded copyWith({
    List<CustomerPayment>? allPayments,
    List<CustomerPayment>? filteredPayments,
    String? searchQuery,
    int? selectedCustomerId,
    Money? totalCollected,
  }) {
    return CustomerPaymentsLoaded(
      allPayments: allPayments ?? this.allPayments,
      filteredPayments: filteredPayments ?? this.filteredPayments,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCustomerId: selectedCustomerId ?? this.selectedCustomerId,
      totalCollected: totalCollected ?? this.totalCollected,
    );
  }

  @override
  List<Object?> get props => [
        allPayments,
        filteredPayments,
        searchQuery,
        selectedCustomerId,
        totalCollected,
      ];
}
