import 'package:equatable/equatable.dart';
import '../../domain/entities/sale.dart';

sealed class SaleDetailState extends Equatable {
  const SaleDetailState();

  @override
  List<Object?> get props => [];
}

final class SaleDetailInitial extends SaleDetailState {
  const SaleDetailInitial();
}

final class SaleDetailLoading extends SaleDetailState {
  const SaleDetailLoading();
}

final class SaleDetailLoaded extends SaleDetailState {
  final Sale sale;
  final bool isReversing;
  final String? errorMessage;
  final bool reverseSuccess;

  const SaleDetailLoaded({
    required this.sale,
    this.isReversing = false,
    this.errorMessage,
    this.reverseSuccess = false,
  });

  SaleDetailLoaded copyWith({
    Sale? sale,
    bool? isReversing,
    String? Function()? errorMessage,
    bool? reverseSuccess,
  }) {
    return SaleDetailLoaded(
      sale: sale ?? this.sale,
      isReversing: isReversing ?? this.isReversing,
      errorMessage:
          errorMessage != null ? errorMessage() : this.errorMessage,
      reverseSuccess: reverseSuccess ?? this.reverseSuccess,
    );
  }

  @override
  List<Object?> get props => [sale, isReversing, errorMessage, reverseSuccess];
}

final class SaleDetailError extends SaleDetailState {
  final String message;

  const SaleDetailError({required this.message});

  @override
  List<Object?> get props => [message];
}
