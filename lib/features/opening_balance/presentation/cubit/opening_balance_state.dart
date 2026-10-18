import 'package:equatable/equatable.dart';

import '../../domain/entities/opening_balance_input.dart';

sealed class OpeningBalanceState extends Equatable {
  const OpeningBalanceState();

  @override
  List<Object?> get props => [];
}

final class OpeningBalanceInitial extends OpeningBalanceState {
  const OpeningBalanceInitial();
}

final class OpeningBalanceLoading extends OpeningBalanceState {
  const OpeningBalanceLoading();
}

final class OpeningBalanceAlreadySaved extends OpeningBalanceState {
  final String message;

  const OpeningBalanceAlreadySaved({
    this.message = 'تم حفظ وتثبيت الأرصدة الافتتاحية للنظام بالفعل مسبقاً، ولا يمكن تعديلها.',
  });

  @override
  List<Object?> get props => [message];
}

final class OpeningBalanceError extends OpeningBalanceState {
  final String message;

  const OpeningBalanceError({required this.message});

  @override
  List<Object?> get props => [message];
}

final class OpeningBalanceReady extends OpeningBalanceState {
  final OpeningBalanceInput input;
  final int activeTabIndex;
  final bool isSubmitting;
  final String? submitError;

  const OpeningBalanceReady({
    required this.input,
    this.activeTabIndex = 0,
    this.isSubmitting = false,
    this.submitError,
  });

  OpeningBalanceReady copyWith({
    OpeningBalanceInput? input,
    int? activeTabIndex,
    bool? isSubmitting,
    String? Function()? submitError,
  }) {
    return OpeningBalanceReady(
      input: input ?? this.input,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError != null ? submitError() : this.submitError,
    );
  }

  @override
  List<Object?> get props => [input, activeTabIndex, isSubmitting, submitError];
}

final class OpeningBalanceSuccess extends OpeningBalanceState {
  final String message;

  const OpeningBalanceSuccess({
    this.message = 'تم حفظ وتثبيت الأرصدة الافتتاحية للنظام بنجاح تام!',
  });

  @override
  List<Object?> get props => [message];
}
