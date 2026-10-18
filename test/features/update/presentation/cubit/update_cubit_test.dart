import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_manager/core/result/failures.dart';
import 'package:sales_manager/core/result/result.dart';
import 'package:sales_manager/features/update/domain/entities/app_version.dart';
import 'package:sales_manager/features/update/domain/usecases/apply_update_usecase.dart';
import 'package:sales_manager/features/update/domain/usecases/check_for_update_usecase.dart';
import 'package:sales_manager/features/update/domain/usecases/download_update_usecase.dart';
import 'package:sales_manager/features/update/domain/usecases/get_current_version_usecase.dart';
import 'package:sales_manager/features/update/presentation/cubit/update_cubit.dart';
import 'package:sales_manager/features/update/presentation/cubit/update_state.dart';

class MockCheckForUpdateUseCase extends Mock implements CheckForUpdateUseCase {}
class MockDownloadUpdateUseCase extends Mock implements DownloadUpdateUseCase {}
class MockApplyUpdateUseCase extends Mock implements ApplyUpdateUseCase {}
class MockGetCurrentVersionUseCase extends Mock implements GetCurrentVersionUseCase {}

void main() {
  late MockCheckForUpdateUseCase mockCheckForUpdate;
  late MockDownloadUpdateUseCase mockDownloadUpdate;
  late MockApplyUpdateUseCase mockApplyUpdate;
  late MockGetCurrentVersionUseCase mockGetCurrentVersion;
  late UpdateCubit cubit;

  const testUpdate = AppVersion(
    version: '1.0.1',
    platform: 'windows',
    downloadUrl: 'https://example.com/setup.exe',
    releaseNotes: 'إصلاحات وتحديثات',
    isRequired: false,
  );

  setUp(() {
    mockCheckForUpdate = MockCheckForUpdateUseCase();
    mockDownloadUpdate = MockDownloadUpdateUseCase();
    mockApplyUpdate = MockApplyUpdateUseCase();
    mockGetCurrentVersion = MockGetCurrentVersionUseCase();

    when(() => mockGetCurrentVersion()).thenAnswer((_) async => '1.0.0');

    cubit = UpdateCubit(
      checkForUpdateUseCase: mockCheckForUpdate,
      downloadUpdateUseCase: mockDownloadUpdate,
      applyUpdateUseCase: mockApplyUpdate,
      getCurrentVersionUseCase: mockGetCurrentVersion,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('UpdateCubit', () {
    test('initial state has UpdateStatus.initial', () {
      expect(cubit.state.status, UpdateStatus.initial);
      expect(cubit.state.updateInfo, isNull);
    });

    blocTest<UpdateCubit, UpdateState>(
      'emits [checking, available] when an update is found',
      build: () {
        when(() => mockCheckForUpdate(currentVersion: any(named: 'currentVersion')))
            .thenAnswer((_) async => const Success(testUpdate));
        return cubit;
      },
      act: (cubit) => cubit.checkForUpdates(isManual: false),
      expect: () => [
        const UpdateState(
          status: UpdateStatus.checking,
          isManualCheck: false,
          currentVersion: '',
        ),
        const UpdateState(
          status: UpdateStatus.checking,
          isManualCheck: false,
          currentVersion: '1.0.0',
        ),
        const UpdateState(
          status: UpdateStatus.available,
          isManualCheck: false,
          currentVersion: '1.0.0',
          updateInfo: testUpdate,
        ),
      ],
    );

    blocTest<UpdateCubit, UpdateState>(
      'emits [checking, noUpdate] when app is up to date',
      build: () {
        when(() => mockCheckForUpdate(currentVersion: any(named: 'currentVersion')))
            .thenAnswer((_) async => const Success(null));
        return cubit;
      },
      act: (cubit) => cubit.checkForUpdates(isManual: true),
      expect: () => [
        const UpdateState(
          status: UpdateStatus.checking,
          isManualCheck: true,
          currentVersion: '',
        ),
        const UpdateState(
          status: UpdateStatus.checking,
          isManualCheck: true,
          currentVersion: '1.0.0',
        ),
        const UpdateState(
          status: UpdateStatus.noUpdate,
          isManualCheck: true,
          currentVersion: '1.0.0',
          updateInfo: null,
        ),
      ],
    );

    blocTest<UpdateCubit, UpdateState>(
      'emits [checking, error] when update check fails',
      build: () {
        when(() => mockCheckForUpdate(currentVersion: any(named: 'currentVersion')))
            .thenAnswer((_) async => const FailureResult(UpdateFailure(message: 'خطأ في الشبكة')));
        return cubit;
      },
      act: (cubit) => cubit.checkForUpdates(),
      expect: () => [
        const UpdateState(
          status: UpdateStatus.checking,
          isManualCheck: false,
          currentVersion: '',
        ),
        const UpdateState(
          status: UpdateStatus.checking,
          isManualCheck: false,
          currentVersion: '1.0.0',
        ),
        const UpdateState(
          status: UpdateStatus.error,
          isManualCheck: false,
          currentVersion: '1.0.0',
          errorMessage: 'خطأ في الشبكة',
        ),
      ],
    );

    blocTest<UpdateCubit, UpdateState>(
      'downloads update and transitions to readyToInstall',
      build: () {
        when(() => mockDownloadUpdate.getSavePath(testUpdate))
            .thenAnswer((_) async => const Success('C:\\Mock\\Setup.exe'));
        when(() => mockDownloadUpdate.download(testUpdate, 'C:\\Mock\\Setup.exe'))
            .thenAnswer((_) => Stream.fromIterable([0.5, 1.0]));
        return cubit;
      },
      seed: () => const UpdateState(
        status: UpdateStatus.available,
        updateInfo: testUpdate,
        currentVersion: '1.0.0',
      ),
      act: (cubit) => cubit.downloadUpdate(),
      expect: () => [
        const UpdateState(
          status: UpdateStatus.downloading,
          updateInfo: testUpdate,
          currentVersion: '1.0.0',
          downloadProgress: 0.0,
        ),
        const UpdateState(
          status: UpdateStatus.downloading,
          updateInfo: testUpdate,
          currentVersion: '1.0.0',
          downloadProgress: 0.5,
        ),
        const UpdateState(
          status: UpdateStatus.downloading,
          updateInfo: testUpdate,
          currentVersion: '1.0.0',
          downloadProgress: 1.0,
        ),
        const UpdateState(
          status: UpdateStatus.readyToInstall,
          updateInfo: testUpdate,
          currentVersion: '1.0.0',
          downloadProgress: 1.0,
          downloadedFilePath: 'C:\\Mock\\Setup.exe',
        ),
      ],
    );
  });
}
