import '../entities/purchase.dart';
import '../repositories/purchase_repository.dart';

class WatchPurchasesUseCase {
  final PurchaseRepository _repository;

  const WatchPurchasesUseCase(this._repository);

  Stream<List<Purchase>> call({
    int? supplierId,
    DateTime? fromDate,
    DateTime? toDate,
    PurchaseStatus? status,
    String? query,
  }) {
    return _repository.watchPurchases(
      supplierId: supplierId,
      fromDate: fromDate,
      toDate: toDate,
      status: status,
      query: query,
    );
  }
}
