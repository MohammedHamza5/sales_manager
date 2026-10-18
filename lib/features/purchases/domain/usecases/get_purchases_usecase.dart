import '../../../../core/result/result.dart';
import '../entities/purchase.dart';
import '../repositories/purchase_repository.dart';

class GetPurchasesUseCase {
  final PurchaseRepository _repository;

  const GetPurchasesUseCase(this._repository);

  Future<Result<List<Purchase>>> call({
    int? supplierId,
    DateTime? fromDate,
    DateTime? toDate,
    PurchaseStatus? status,
    String? query,
  }) {
    return _repository.getPurchases(
      supplierId: supplierId,
      fromDate: fromDate,
      toDate: toDate,
      status: status,
      query: query,
    );
  }
}
