import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;

import '../../../../core/config/app_config.dart';
import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/app_version.dart';
import '../../domain/repositories/update_repository.dart';
import '../datasources/update_local_datasource.dart';
import '../datasources/update_remote_datasource.dart';

class UpdateRepositoryImpl implements UpdateRepository {
  final UpdateRemoteDataSource _remote;
  final UpdateLocalDataSource _local;

  UpdateRepositoryImpl({
    required UpdateRemoteDataSource remote,
    required UpdateLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  @override
  Future<String> getCurrentAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) {
        return info.version;
      }
    } catch (e) {
      debugPrint('Error getting PackageInfo: $e');
    }
    return AppConfig.appVersion;
  }

  @override
  Future<Result<AppVersion?>> checkForUpdate({String? currentVersion}) async {
    try {
      final List<String> targetPlatforms;
      if (kIsWeb) {
        targetPlatforms = const ['web'];
      } else if (Platform.isWindows) {
        targetPlatforms = const [AppConfig.platformWindows, AppConfig.platformWindowsOffline];
      } else {
        return const Success(null);
      }

      final latest = await _remote.getLatestVersion(targetPlatforms);
      if (latest == null) {
        return const Success(null);
      }

      final activeVersion = currentVersion ?? await getCurrentAppVersion();

      if (isUpdateAvailable(activeVersion, latest.version)) {
        return Success(latest);
      }

      return const Success(null);
    } catch (e) {
      return FailureResult(
        UpdateFailure(
          message: 'فشل التحقق من التحديثات: $e',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Result<String>> getDownloadSavePath(AppVersion updateInfo) async {
    try {
      final dir = await _local.getUpdatesDirectory();
      final cleanVersion = updateInfo.version.replaceAll(RegExp(r'[^\w\.-]'), '_');
      final filePath = p.join(dir, 'SalesManager_Update_$cleanVersion.exe');
      return Success(filePath);
    } catch (e) {
      return FailureResult(
        UpdateFailure(
          message: 'تعذر تحديد مسار حفظ ملف التحديث: $e',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  @override
  Stream<double> downloadUpdate(AppVersion updateInfo, String savePath) {
    return _local.downloadFile(updateInfo.downloadUrl, savePath);
  }

  @override
  Future<Result<void>> applyUpdate(String installerPath, {bool silent = true}) async {
    try {
      await _local.launchInstaller(installerPath, silent: silent);
      return const Success(null);
    } catch (e) {
      return FailureResult(
        UpdateFailure(
          message: 'فشل تشغيل مثبت التحديث: $e',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  /// Compares semantic versioning (Major.Minor.Patch) and optional build number.
  /// Returns `true` if [latest] is strictly greater than [current].
  static bool isUpdateAvailable(String current, String latest) {
    try {
      final cleanCurrent = _normalizeVersion(current);
      final cleanLatest = _normalizeVersion(latest);

      final currentCore = cleanCurrent.coreParts;
      final latestCore = cleanLatest.coreParts;

      final maxLength = currentCore.length > latestCore.length ? currentCore.length : latestCore.length;

      for (int i = 0; i < maxLength; i++) {
        final c = i < currentCore.length ? currentCore[i] : 0;
        final l = i < latestCore.length ? latestCore[i] : 0;

        if (l > c) return true;
        if (l < c) return false;
      }

      // If core versions are identical, compare build number if available
      if (cleanLatest.buildNumber != null && cleanCurrent.buildNumber != null) {
        return cleanLatest.buildNumber! > cleanCurrent.buildNumber!;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  static _ParsedVersion _normalizeVersion(String raw) {
    var v = raw.trim();
    if (v.startsWith('v') || v.startsWith('V')) {
      v = v.substring(1);
    }

    int? buildNum;
    if (v.contains('+')) {
      final parts = v.split('+');
      v = parts[0];
      if (parts.length > 1) {
        buildNum = int.tryParse(parts[1]);
      }
    }

    final coreParts = v.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    return _ParsedVersion(coreParts: coreParts, buildNumber: buildNum);
  }
}

class _ParsedVersion {
  final List<int> coreParts;
  final int? buildNumber;

  const _ParsedVersion({required this.coreParts, this.buildNumber});
}
