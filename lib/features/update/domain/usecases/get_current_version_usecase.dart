import '../repositories/update_repository.dart';

class GetCurrentVersionUseCase {
  final UpdateRepository _repository;

  GetCurrentVersionUseCase(this._repository);

  Future<String> call() {
    return _repository.getCurrentAppVersion();
  }
}
