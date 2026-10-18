import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/dashboard_data.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardDataUseCase {
  final DashboardRepository _repository;

  const GetDashboardDataUseCase(this._repository);

  Future<Result<DashboardData>> call() async {
    try {
      final data = await _repository.getDashboardData();
      return Success(data);
    } catch (e) {
      return FailureResult(DatabaseFailure(message: 'فشل في جلب بيانات لوحة التحكم: $e'));
    }
  }
}
