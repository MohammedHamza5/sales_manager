import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_auto_backup_usecase.dart';
import '../../domain/usecases/create_manual_backup_usecase.dart';
import '../../domain/usecases/export_backup_usecase.dart';
import '../../domain/usecases/get_backup_history_usecase.dart';
import '../../domain/usecases/manage_backup_settings_usecase.dart';
import '../../domain/usecases/restore_backup_usecase.dart';
import '../../../../core/result/result.dart';
import 'backup_restore_state.dart';

class BackupRestoreCubit extends Cubit<BackupRestoreState> {
  final CreateManualBackupUseCase _createManualBackupUseCase;
  final ExportBackupUseCase _exportBackupUseCase;
  final CreateAutoBackupUseCase _createAutoBackupUseCase;
  final RestoreBackupUseCase _restoreBackupUseCase;
  final GetBackupHistoryUseCase _getBackupHistoryUseCase;
  final ManageBackupSettingsUseCase _manageBackupSettingsUseCase;

  BackupRestoreCubit({
    required CreateManualBackupUseCase createManualBackupUseCase,
    required ExportBackupUseCase exportBackupUseCase,
    required CreateAutoBackupUseCase createAutoBackupUseCase,
    required RestoreBackupUseCase restoreBackupUseCase,
    required GetBackupHistoryUseCase getBackupHistoryUseCase,
    required ManageBackupSettingsUseCase manageBackupSettingsUseCase,
  })  : _createManualBackupUseCase = createManualBackupUseCase,
        _exportBackupUseCase = exportBackupUseCase,
        _createAutoBackupUseCase = createAutoBackupUseCase,
        _restoreBackupUseCase = restoreBackupUseCase,
        _getBackupHistoryUseCase = getBackupHistoryUseCase,
        _manageBackupSettingsUseCase = manageBackupSettingsUseCase,
        super(const BackupRestoreInitial());

  CreateAutoBackupUseCase get createAutoBackupUseCase => _createAutoBackupUseCase;

  Future<void> load() async {
    emit(const BackupRestoreLoading());

    final historyResult = await _getBackupHistoryUseCase();
    final enabledResult = await _manageBackupSettingsUseCase.isAutoBackupEnabled();
    final retentionResult =
        await _manageBackupSettingsUseCase.getAutoBackupRetentionCount();

    final history = historyResult.dataOrNull ?? [];
    final enabled = enabledResult.dataOrNull ?? true;
    final retention = retentionResult.dataOrNull ?? 7;

    emit(
      BackupRestoreLoaded(
        history: history,
        autoBackupEnabled: enabled,
        retentionCount: retention,
      ),
    );
  }

  Future<void> createManualBackup() async {
    final currentState = state;
    if (currentState is! BackupRestoreLoaded) return;

    emit(currentState.copyWith(isOperating: true, clearOperationMessage: true));

    final result = await _createManualBackupUseCase();

    if (result.isSuccess) {
      final filePath = result.dataOrNull ?? '';
      final historyRes = await _getBackupHistoryUseCase();
      emit(
        currentState.copyWith(
          isOperating: false,
          history: historyRes.dataOrNull ?? currentState.history,
          operationSuccessMessage: 'تم إنشاء النسخة الاحتياطية بنجاح في:\n$filePath',
        ),
      );
    } else {
      emit(
        currentState.copyWith(
          isOperating: false,
          operationErrorMessage: result.failureOrNull?.message,
        ),
      );
    }
  }

  Future<void> exportBackupToUsb() async {
    final currentState = state;
    if (currentState is! BackupRestoreLoaded) return;

    emit(currentState.copyWith(isOperating: true, clearOperationMessage: true));

    final result = await _exportBackupUseCase();

    if (result.isSuccess) {
      final filePath = result.dataOrNull ?? '';
      final historyRes = await _getBackupHistoryUseCase();
      emit(
        currentState.copyWith(
          isOperating: false,
          history: historyRes.dataOrNull ?? currentState.history,
          operationSuccessMessage: 'تم تصدير النسخة الاحتياطية بنجاح إلى:\n$filePath',
        ),
      );
    } else {
      emit(
        currentState.copyWith(
          isOperating: false,
          operationErrorMessage: result.failureOrNull?.message,
        ),
      );
    }
  }

  Future<void> restoreBackup(String backupFilePath) async {
    final currentState = state;
    if (currentState is! BackupRestoreLoaded) return;

    emit(currentState.copyWith(isOperating: true, clearOperationMessage: true));

    final result = await _restoreBackupUseCase(backupFilePath);

    if (result is Success<String>) {
      emit(
        currentState.copyWith(
          isOperating: false,
          operationSuccessMessage: result.data,
        ),
      );
    } else if (result is FailureResult<String>) {
      emit(
        currentState.copyWith(
          isOperating: false,
          operationErrorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> createAutoBackupNow() async {
    final currentState = state;
    if (currentState is! BackupRestoreLoaded) return;

    emit(currentState.copyWith(isOperating: true, clearOperationMessage: true));

    final result = await _createAutoBackupUseCase(
      retentionCount: currentState.retentionCount,
    );

    if (result is Success<String>) {
      final historyRes = await _getBackupHistoryUseCase();
      emit(
        currentState.copyWith(
          isOperating: false,
          history: historyRes.dataOrNull ?? currentState.history,
          operationSuccessMessage: 'تم إنشاء النسخة التلقائية بنجاح في:\n${result.data}',
        ),
      );
    } else if (result is FailureResult<String>) {
      emit(
        currentState.copyWith(
          isOperating: false,
          operationErrorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> toggleAutoBackup(bool enabled) async {
    final currentState = state;
    if (currentState is! BackupRestoreLoaded) return;

    await _manageBackupSettingsUseCase.setAutoBackupEnabled(enabled);
    emit(currentState.copyWith(autoBackupEnabled: enabled));
  }

  Future<void> setRetentionCount(int count) async {
    final currentState = state;
    if (currentState is! BackupRestoreLoaded) return;

    await _manageBackupSettingsUseCase.setAutoBackupRetentionCount(count);
    emit(currentState.copyWith(retentionCount: count));
  }

  void clearOperationMessage() {
    final currentState = state;
    if (currentState is! BackupRestoreLoaded) return;
    emit(currentState.copyWith(clearOperationMessage: true));
  }
}
