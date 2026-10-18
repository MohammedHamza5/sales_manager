import '../entities/sale.dart';
import '../repositories/sale_repository.dart';

class WatchSalesUseCase {
  final SaleRepository _repository;

  const WatchSalesUseCase(this._repository);

  Stream<List<Sale>> call({
    int? customerId,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
    String? query,
  }) {
    return _repository.watchSales(
      customerId: customerId,
      fromDate: fromDate,
      toDate: toDate,
      status: status,
      query: query,
    );
  }
}
