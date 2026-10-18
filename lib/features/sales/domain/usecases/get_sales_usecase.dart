import '../../../../core/result/result.dart';
import '../entities/sale.dart';
import '../repositories/sale_repository.dart';

class GetSalesUseCase {
  final SaleRepository _repository;

  const GetSalesUseCase(this._repository);

  Future<Result<List<Sale>>> call({
    int? customerId,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
    String? query,
  }) {
    return _repository.getSales(
      customerId: customerId,
      fromDate: fromDate,
      toDate: toDate,
      status: status,
      query: query,
    );
  }
}
