import 'package:flutter_test/flutter_test.dart';
import 'package:sales_manager/core/result/result.dart';
import 'package:sales_manager/features/update/data/datasources/update_local_datasource.dart';
import 'package:sales_manager/features/update/data/datasources/update_remote_datasource.dart';
import 'package:sales_manager/features/update/data/models/app_version_model.dart';
import 'package:sales_manager/features/update/data/repositories/update_repository_impl.dart';
import 'package:sales_manager/features/update/domain/entities/app_version.dart';

class MockRemoteDataSource implements UpdateRemoteDataSource {
  AppVersionModel? mockVersion;
  List<String>? recordedPlatforms;

  @override
  Future<AppVersionModel?> getLatestVersion(List<String> platforms) async {
    recordedPlatforms = platforms;
    return mockVersion;
  }
}

class MockLocalDataSource implements UpdateLocalDataSource {
  String? launchedInstaller;
  bool? launchedSilent;

  @override
  Stream<double> downloadFile(String url, String savePath) async* {
    yield 0.5;
    yield 1.0;
  }

  @override
  Future<String> getUpdatesDirectory() async {
    return 'C:\\Mock\\Updates';
  }

  @override
  Future<void> launchInstaller(String installerPath, {bool silent = true}) async {
    launchedInstaller = installerPath;
    launchedSilent = silent;
  }
}

void main() {
  late MockRemoteDataSource mockRemote;
  late MockLocalDataSource mockLocal;
  late UpdateRepositoryImpl repository;

  setUp(() {
    mockRemote = MockRemoteDataSource();
    mockLocal = MockLocalDataSource();
    repository = UpdateRepositoryImpl(remote: mockRemote, local: mockLocal);
  });

  group('Semantic Version Comparison', () {
    test('detects newer patch version', () {
      expect(UpdateRepositoryImpl.isUpdateAvailable('1.0.0', '1.0.1'), isTrue);
    });

    test('detects newer minor version', () {
      expect(UpdateRepositoryImpl.isUpdateAvailable('1.0.9', '1.1.0'), isTrue);
    });

    test('detects newer major version', () {
      expect(UpdateRepositoryImpl.isUpdateAvailable('1.9.9', '2.0.0'), isTrue);
    });

    test('returns false when latest is older', () {
      expect(UpdateRepositoryImpl.isUpdateAvailable('1.1.0', '1.0.9'), isFalse);
    });

    test('returns false when versions are identical', () {
      expect(UpdateRepositoryImpl.isUpdateAvailable('1.0.0', '1.0.0'), isFalse);
    });

    test('handles leading v prefix', () {
      expect(UpdateRepositoryImpl.isUpdateAvailable('v1.0.0', 'v1.0.1'), isTrue);
      expect(UpdateRepositoryImpl.isUpdateAvailable('1.0.0', 'v1.0.1'), isTrue);
    });

    test('compares build numbers when core versions match', () {
      expect(UpdateRepositoryImpl.isUpdateAvailable('1.0.0+1', '1.0.0+2'), isTrue);
      expect(UpdateRepositoryImpl.isUpdateAvailable('1.0.0+2', '1.0.0+1'), isFalse);
    });
  });

  group('Check For Update Logic', () {
    test('returns available update when cloud version is higher', () async {
      mockRemote.mockVersion = const AppVersionModel(
        version: '1.1.0',
        platform: 'windows',
        downloadUrl: 'https://example.com/setup.exe',
        releaseNotes: 'تحسينات جديدة',
      );

      final result = await repository.checkForUpdate(currentVersion: '1.0.0');

      expect(result, isA<Success<AppVersion?>>());
      final update = result.dataOrNull;
      expect(update, isNotNull);
      expect(update!.version, '1.1.0');
    });

    test('returns null when cloud version is same or older', () async {
      mockRemote.mockVersion = const AppVersionModel(
        version: '1.0.0',
        platform: 'windows',
        downloadUrl: 'https://example.com/setup.exe',
      );

      final result = await repository.checkForUpdate(currentVersion: '1.0.0');

      expect(result, isA<Success<AppVersion?>>());
      expect(result.dataOrNull, isNull);
    });

    test('returns null when no record exists on cloud', () async {
      mockRemote.mockVersion = null;

      final result = await repository.checkForUpdate(currentVersion: '1.0.0');

      expect(result, isA<Success<AppVersion?>>());
      expect(result.dataOrNull, isNull);
    });
  });

  group('Installer & Download Path', () {
    test('generates clean download path in update directory', () async {
      const update = AppVersionModel(
        version: '1.0.1',
        platform: 'windows',
        downloadUrl: 'https://example.com/setup.exe',
      );

      final pathResult = await repository.getDownloadSavePath(update);
      expect(pathResult, isA<Success<String>>());
      expect(pathResult.dataOrNull, contains('SalesManager_Update_1.0.1.exe'));
    });

    test('delegates applyUpdate to local data source', () async {
      final result = await repository.applyUpdate('C:\\Mock\\Updates\\setup.exe');
      expect(result, isA<Success<void>>());
      expect(mockLocal.launchedInstaller, 'C:\\Mock\\Updates\\setup.exe');
      expect(mockLocal.launchedSilent, isTrue);
    });
  });
}
