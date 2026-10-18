import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/strings/app_strings.dart';
import '../../domain/usecases/apply_update_usecase.dart';
import '../../domain/usecases/check_for_update_usecase.dart';
import '../../domain/usecases/download_update_usecase.dart';
import '../../domain/usecases/get_current_version_usecase.dart';
import 'update_state.dart';

class UpdateCubit extends Cubit<UpdateState> {
  final CheckForUpdateUseCase _checkForUpdateUseCase;
  final DownloadUpdateUseCase _downloadUpdateUseCase;
  final ApplyUpdateUseCase _applyUpdateUseCase;
  final GetCurrentVersionUseCase _getCurrentVersionUseCase;

  StreamSubscription<double>? _downloadSub;

  UpdateCubit({
    required CheckForUpdateUseCase checkForUpdateUseCase,
    required DownloadUpdateUseCase downloadUpdateUseCase,
    required ApplyUpdateUseCase applyUpdateUseCase,
    required GetCurrentVersionUseCase getCurrentVersionUseCase,
  })  : _checkForUpdateUseCase = checkForUpdateUseCase,
        _downloadUpdateUseCase = downloadUpdateUseCase,
        _applyUpdateUseCase = applyUpdateUseCase,
        _getCurrentVersionUseCase = getCurrentVersionUseCase,
        super(const UpdateState());

  Future<void> initCurrentVersion() async {
    if (state.currentVersion.isEmpty) {
      final version = await _getCurrentVersionUseCase();
      emit(state.copyWith(currentVersion: version));
    }
  }

  Future<void> checkForUpdates({bool isManual = false}) async {
    emit(state.copyWith(
      status: UpdateStatus.checking,
      isManualCheck: isManual,
      errorMessage: null,
    ));

    final version = state.currentVersion.isNotEmpty
        ? state.currentVersion
        : await _getCurrentVersionUseCase();

    emit(state.copyWith(currentVersion: version));

    final result = await _checkForUpdateUseCase(currentVersion: version);

    result.fold(
      onSuccess: (updateInfo) {
        if (updateInfo != null) {
          emit(state.copyWith(
            status: UpdateStatus.available,
            updateInfo: updateInfo,
          ));
        } else {
          emit(state.copyWith(
            status: UpdateStatus.noUpdate,
            updateInfo: null,
          ));
        }
      },
      onFailure: (failure) {
        emit(state.copyWith(
          status: UpdateStatus.error,
          errorMessage: failure.message,
        ));
      },
    );
  }

  Future<void> downloadUpdate() async {
    final updateInfo = state.updateInfo;
    if (updateInfo == null) return;

    await _downloadSub?.cancel();

    emit(state.copyWith(
      status: UpdateStatus.downloading,
      downloadProgress: 0.0,
      errorMessage: null,
    ));

    final pathResult = await _downloadUpdateUseCase.getSavePath(updateInfo);

    if (pathResult.isFailure) {
      emit(state.copyWith(
        status: UpdateStatus.error,
        errorMessage: pathResult.failureOrNull?.message ?? AppStrings.updateDownloadFailed,
      ));
      return;
    }

    final savePath = pathResult.dataOrNull!;

    try {
      _downloadSub = _downloadUpdateUseCase.download(updateInfo, savePath).listen(
        (progress) {
          emit(state.copyWith(downloadProgress: progress));
        },
        onDone: () {
          emit(state.copyWith(
            status: UpdateStatus.readyToInstall,
            downloadProgress: 1.0,
            downloadedFilePath: savePath,
          ));
        },
        onError: (Object e) {
          emit(state.copyWith(
            status: UpdateStatus.error,
            errorMessage: '${AppStrings.updateDownloadFailed}: $e',
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: UpdateStatus.error,
        errorMessage: '${AppStrings.updateDownloadFailed}: $e',
      ));
    }
  }

  Future<void> installUpdate({bool silent = true}) async {
    final filePath = state.downloadedFilePath;
    if (filePath == null) return;

    final result = await _applyUpdateUseCase(filePath);

    result.fold(
      onSuccess: (_) {
        // App will terminate if silent installer detached successfully
      },
      onFailure: (failure) {
        emit(state.copyWith(
          status: UpdateStatus.error,
          errorMessage: failure.message,
        ));
      },
    );
  }

  void resetError() {
    emit(state.copyWith(
      status: state.updateInfo != null ? UpdateStatus.available : UpdateStatus.initial,
      errorMessage: null,
    ));
  }

  void dismissDialog() {
    if (state.status == UpdateStatus.available && !(state.updateInfo?.isRequired ?? false)) {
      emit(state.copyWith(status: UpdateStatus.initial));
    }
  }

  @override
  Future<void> close() {
    _downloadSub?.cancel();
    return super.close();
  }
}
