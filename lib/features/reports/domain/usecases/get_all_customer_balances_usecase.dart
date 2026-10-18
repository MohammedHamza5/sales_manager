import '../../../../core/result/result.dart';
import '../entities/customer_account_report.dart';
import '../repositories/report_repository.dart';

class GetAllCustomerBalancesUseCase {
  final ReportRepository _repository;

  const GetAllCustomerBalancesUseCase(this._repository);

  Future<Result<List<CustomerBalanceSummary>>> call() {
    return _repository.getAllCustomerBalances();
  }
}
