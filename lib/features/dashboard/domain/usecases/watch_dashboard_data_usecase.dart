import '../entities/dashboard_data.dart';
import '../repositories/dashboard_repository.dart';

class WatchDashboardDataUseCase {
  final DashboardRepository _repository;

  const WatchDashboardDataUseCase(this._repository);

  Stream<DashboardData> call() {
    return _repository.watchDashboardData();
  }
}
