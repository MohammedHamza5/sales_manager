import '../../../../core/result/result.dart';
import '../repositories/update_repository.dart';

class ApplyUpdateUseCase {
  final UpdateRepository _repository;

  ApplyUpdateUseCase(this._repository);

  Future<Result<void>> call(String installerPath) {
    return _repository.applyUpdate(installerPath);
  }
}
