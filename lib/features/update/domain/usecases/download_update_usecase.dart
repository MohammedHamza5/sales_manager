import '../../../../core/result/result.dart';
import '../entities/app_version.dart';
import '../repositories/update_repository.dart';

class DownloadUpdateUseCase {
  final UpdateRepository _repository;

  DownloadUpdateUseCase(this._repository);

  Future<Result<String>> getSavePath(AppVersion updateInfo) {
    return _repository.getDownloadSavePath(updateInfo);
  }

  Stream<double> download(AppVersion updateInfo, String savePath) {
    return _repository.downloadUpdate(updateInfo, savePath);
  }
}
