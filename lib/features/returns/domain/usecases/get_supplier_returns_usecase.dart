import '../../../../core/result/result.dart';
import '../entities/supplier_return.dart';
import '../repositories/return_repository.dart';

class GetSupplierReturnsUseCase {
  final ReturnRepository _repository;

  const GetSupplierReturnsUseCase(this._repository);

  Future<Result<List<SupplierReturn>>> call({
    int? supplierId,
    DateTime? fromDate,
    DateTime? toDate,
    String? query,
  }) {
    return _repository.getSupplierReturns(
      supplierId: supplierId,
      fromDate: fromDate,
      toDate: toDate,
      query: query,
    );
  }
}
