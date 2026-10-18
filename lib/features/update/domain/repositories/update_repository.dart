import '../../../../core/result/result.dart';
import '../entities/app_version.dart';

abstract class UpdateRepository {
  /// Checks whether an update is available on Supabase for the current platform.
  Future<Result<AppVersion?>> checkForUpdate({String? currentVersion});

  /// Resolves the absolute file path where the installer update should be saved.
  Future<Result<String>> getDownloadSavePath(AppVersion updateInfo);

  /// Streams the download progress (0.0 to 1.0) while saving the update installer.
  Stream<double> downloadUpdate(AppVersion updateInfo, String savePath);

  /// Launches the downloaded installer in detached mode to apply the update.
  Future<Result<void>> applyUpdate(String installerPath);

  /// Retrieves the current app version (e.g. '1.0.0').
  Future<String> getCurrentAppVersion();
}
