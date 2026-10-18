import 'package:equatable/equatable.dart';

sealed class AppFailure extends Equatable {
  final String message;
  final String? technicalDetails;

  const AppFailure({
    required this.message,
    this.technicalDetails,
  });

  @override
  List<Object?> get props => [message, technicalDetails];
}

final class DatabaseFailure extends AppFailure {
  const DatabaseFailure({
    required super.message,
    super.technicalDetails,
  });
}

final class InsufficientStockFailure extends AppFailure {
  final String productName;
  final String requestedQuantity;
  final String availableQuantity;

  const InsufficientStockFailure({
    required this.productName,
    required this.requestedQuantity,
    required this.availableQuantity,
    required super.message,
    super.technicalDetails,
  });

  @override
  List<Object?> get props => [
        productName,
        requestedQuantity,
        availableQuantity,
        message,
        technicalDetails,
      ];
}

final class ValidationFailure extends AppFailure {
  final String field;

  const ValidationFailure({
    required this.field,
    required super.message,
    super.technicalDetails,
  });

  @override
  List<Object?> get props => [field, message, technicalDetails];
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure({
    required super.message,
    super.technicalDetails,
  });
}

final class ConflictFailure extends AppFailure {
  const ConflictFailure({
    required super.message,
    super.technicalDetails,
  });
}

final class BackupFailure extends AppFailure {
  const BackupFailure({
    required super.message,
    super.technicalDetails,
  });
}

final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure({
    required super.message,
    super.technicalDetails,
  });
}

final class UpdateFailure extends AppFailure {
  const UpdateFailure({
    required super.message,
    super.technicalDetails,
  });
}

final class AuthFailure extends AppFailure {
  const AuthFailure({
    required super.message,
    super.technicalDetails,
  });
}

