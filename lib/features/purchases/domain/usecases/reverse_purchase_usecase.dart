import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/purchase.dart';
import '../repositories/purchase_repository.dart';

class ReversePurchaseUseCase {
  final PurchaseRepository _repository;

  const ReversePurchaseUseCase(this._repository);

  Future<Result<Purchase>> call({
    required int purchaseId,
    String createdBy = 'admin',
  }) async {
    if (purchaseId <= 0) {
      return const FailureResult(
        ValidationFailure(
          field: 'purchaseId',
          message: 'معرّف فاتورة الشراء غير صالح',
        ),
      );
    }

    return _repository.reversePurchase(
      purchaseId: purchaseId,
      createdBy: createdBy,
    );
  }
}
