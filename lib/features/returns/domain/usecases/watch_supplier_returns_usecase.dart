import '../entities/supplier_return.dart';
import '../repositories/return_repository.dart';

class WatchSupplierReturnsUseCase {
  final ReturnRepository _repository;

  const WatchSupplierReturnsUseCase(this._repository);

  Stream<List<SupplierReturn>> call({
    int? supplierId,
    DateTime? fromDate,
    DateTime? toDate,
    String? query,
  }) {
    return _repository.watchSupplierReturns(
      supplierId: supplierId,
      fromDate: fromDate,
      toDate: toDate,
      query: query,
    );
  }
}
