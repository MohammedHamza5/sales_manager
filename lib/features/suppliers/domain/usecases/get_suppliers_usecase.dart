import '../../../../core/result/result.dart';
import '../entities/supplier.dart';
import '../repositories/supplier_repository.dart';

class GetSuppliersUseCase {
  final SupplierRepository _repository;

  const GetSuppliersUseCase(this._repository);

  Future<Result<List<Supplier>>> call({
    String? query,
    bool? isActiveOnly,
  }) {
    return _repository.getSuppliers(
      query: query,
      isActiveOnly: isActiveOnly,
    );
  }
}
