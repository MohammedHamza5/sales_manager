import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/supplier_payment.dart';

sealed class SupplierPaymentsState extends Equatable {
  const SupplierPaymentsState();

  @override
  List<Object?> get props => [];
}

final class SupplierPaymentsInitial extends SupplierPaymentsState {
  const SupplierPaymentsInitial();
}

final class SupplierPaymentsLoading extends SupplierPaymentsState {
  const SupplierPaymentsLoading();
}

final class SupplierPaymentsEmpty extends SupplierPaymentsState {
  final int? filteredSupplierId;
  const SupplierPaymentsEmpty({this.filteredSupplierId});

  @override
  List<Object?> get props => [filteredSupplierId];
}

final class SupplierPaymentsError extends SupplierPaymentsState {
  final String message;
  const SupplierPaymentsError(this.message);

  @override
  List<Object?> get props => [message];
}

final class SupplierPaymentsLoaded extends SupplierPaymentsState {
  final List<SupplierPayment> allPayments;
  final List<SupplierPayment> filteredPayments;
  final String searchQuery;
  final int? selectedSupplierId;
  final Money totalPaid;

  const SupplierPaymentsLoaded({
    required this.allPayments,
    required this.filteredPayments,
    this.searchQuery = '',
    this.selectedSupplierId,
    required this.totalPaid,
  });

  SupplierPaymentsLoaded copyWith({
    List<SupplierPayment>? allPayments,
    List<SupplierPayment>? filteredPayments,
    String? searchQuery,
    int? selectedSupplierId,
    Money? totalPaid,
  }) {
    return SupplierPaymentsLoaded(
      allPayments: allPayments ?? this.allPayments,
      filteredPayments: filteredPayments ?? this.filteredPayments,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedSupplierId: selectedSupplierId ?? this.selectedSupplierId,
      totalPaid: totalPaid ?? this.totalPaid,
    );
  }

  @override
  List<Object?> get props => [
        allPayments,
        filteredPayments,
        searchQuery,
        selectedSupplierId,
        totalPaid,
      ];
}
