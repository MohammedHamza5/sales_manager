import 'package:equatable/equatable.dart';
import 'failures.dart';

sealed class Result<T> extends Equatable {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is FailureResult<T>;

  T? get dataOrNull => switch (this) {
        Success(data: final d) => d,
        FailureResult() => null,
      };

  AppFailure? get failureOrNull => switch (this) {
        Success() => null,
        FailureResult(failure: final f) => f,
      };

  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(AppFailure failure) onFailure,
  }) {
    return switch (this) {
      Success(data: final d) => onSuccess(d),
      FailureResult(failure: final f) => onFailure(f),
    };
  }

  @override
  List<Object?> get props => [];
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  List<Object?> get props => [data];
}

final class FailureResult<T> extends Result<T> {
  final AppFailure failure;
  const FailureResult(this.failure);

  @override
  List<Object?> get props => [failure];
}
