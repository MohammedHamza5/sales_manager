import 'package:equatable/equatable.dart';
import '../../domain/entities/backup_info.dart';

sealed class BackupRestoreState extends Equatable {
  const BackupRestoreState();

  @override
  List<Object?> get props => [];
}

final class BackupRestoreInitial extends BackupRestoreState {
  const BackupRestoreInitial();
}

final class BackupRestoreLoading extends BackupRestoreState {
  const BackupRestoreLoading();
}

final class BackupRestoreLoaded extends BackupRestoreState {
  final List<BackupInfo> history;
  final bool autoBackupEnabled;
  final int retentionCount;
  final bool isOperating;
  final String? operationSuccessMessage;
  final String? operationErrorMessage;

  const BackupRestoreLoaded({
    required this.history,
    this.autoBackupEnabled = true,
    this.retentionCount = 7,
    this.isOperating = false,
    this.operationSuccessMessage,
    this.operationErrorMessage,
  });

  BackupRestoreLoaded copyWith({
    List<BackupInfo>? history,
    bool? autoBackupEnabled,
    int? retentionCount,
    bool? isOperating,
    String? operationSuccessMessage,
    String? operationErrorMessage,
    bool clearOperationMessage = false,
  }) {
    return BackupRestoreLoaded(
      history: history ?? this.history,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      retentionCount: retentionCount ?? this.retentionCount,
      isOperating: isOperating ?? this.isOperating,
      operationSuccessMessage: clearOperationMessage
          ? null
          : (operationSuccessMessage ?? this.operationSuccessMessage),
      operationErrorMessage: clearOperationMessage
          ? null
          : (operationErrorMessage ?? this.operationErrorMessage),
    );
  }

  @override
  List<Object?> get props => [
        history,
        autoBackupEnabled,
        retentionCount,
        isOperating,
        operationSuccessMessage,
        operationErrorMessage,
      ];
}

final class BackupRestoreError extends BackupRestoreState {
  final String message;
  const BackupRestoreError({required this.message});

  @override
  List<Object?> get props => [message];
}
