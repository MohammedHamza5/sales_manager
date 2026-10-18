import '../../../../core/result/result.dart';
import '../entities/customer_account_report.dart';
import '../repositories/report_repository.dart';

class GetCustomerReportUseCase {
  final ReportRepository _repository;

  const GetCustomerReportUseCase(this._repository);

  Future<Result<CustomerAccountReport>> call({
    required int customerId,
    required DateTime from,
    required DateTime to,
  }) {
    return _repository.getCustomerReport(
      customerId: customerId,
      from: from,
      to: to,
    );
  }
}
