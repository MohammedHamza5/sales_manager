import 'package:equatable/equatable.dart';
import '../../domain/entities/app_version.dart';

enum UpdateStatus {
  initial,
  checking,
  available,
  noUpdate,
  downloading,
  readyToInstall,
  error,
}

class UpdateState extends Equatable {
  final UpdateStatus status;
  final String currentVersion;
  final AppVersion? updateInfo;
  final double downloadProgress; // 0.0 to 1.0 (-1.0 for indeterminate)
  final String? downloadedFilePath;
  final String? errorMessage;
  final bool isManualCheck;

  const UpdateState({
    this.status = UpdateStatus.initial,
    this.currentVersion = '',
    this.updateInfo,
    this.downloadProgress = 0.0,
    this.downloadedFilePath,
    this.errorMessage,
    this.isManualCheck = false,
  });

  UpdateState copyWith({
    UpdateStatus? status,
    String? currentVersion,
    AppVersion? updateInfo,
    double? downloadProgress,
    String? downloadedFilePath,
    String? errorMessage,
    bool? isManualCheck,
  }) {
    return UpdateState(
      status: status ?? this.status,
      currentVersion: currentVersion ?? this.currentVersion,
      updateInfo: updateInfo ?? this.updateInfo,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadedFilePath: downloadedFilePath ?? this.downloadedFilePath,
      errorMessage: errorMessage ?? this.errorMessage,
      isManualCheck: isManualCheck ?? this.isManualCheck,
    );
  }

  @override
  List<Object?> get props => [
        status,
        currentVersion,
        updateInfo,
        downloadProgress,
        downloadedFilePath,
        errorMessage,
        isManualCheck,
      ];
}
