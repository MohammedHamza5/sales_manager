import '../../../../core/result/result.dart';
import '../entities/app_version.dart';
import '../repositories/update_repository.dart';

class CheckForUpdateUseCase {
  final UpdateRepository _repository;

  CheckForUpdateUseCase(this._repository);

  Future<Result<AppVersion?>> call({String? currentVersion}) {
    return _repository.checkForUpdate(currentVersion: currentVersion);
  }
}
