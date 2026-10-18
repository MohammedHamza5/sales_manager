import '../entities/supplier.dart';
import '../repositories/supplier_repository.dart';

class WatchSuppliersUseCase {
  final SupplierRepository _repository;

  const WatchSuppliersUseCase(this._repository);

  Stream<List<Supplier>> call({
    String? query,
    bool? isActiveOnly,
  }) {
    return _repository.watchSuppliers(
      query: query,
      isActiveOnly: isActiveOnly,
    );
  }
}
