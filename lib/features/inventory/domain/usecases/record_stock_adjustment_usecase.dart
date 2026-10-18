import 'package:decimal/decimal.dart';

import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/inventory_movement.dart';
import '../repositories/inventory_repository.dart';

class RecordStockAdjustmentUseCase {
  final InventoryRepository _repository;

  const RecordStockAdjustmentUseCase(this._repository);

  Future<Result<InventoryMovement>> call({
    required int productId,
    required Decimal quantityDelta,
    required String reason,
    String createdBy = 'admin',
  }) async {
    if (productId <= 0) {
      return const FailureResult(
        ValidationFailure(
          field: 'productId',
          message: 'معرّف المنتج غير صالح',
        ),
      );
    }

    if (quantityDelta == Decimal.zero) {
      return const FailureResult(
        ValidationFailure(
          field: 'quantityDelta',
          message: 'مقدار التسوية يجب ألا يكون صفراً',
        ),
      );
    }

    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      return const FailureResult(
        ValidationFailure(
          field: 'reason',
          message: 'سبب التسوية المخزنية مطلوب إلزاميًا لضمان التدقيق',
        ),
      );
    }

    return _repository.recordAdjustment(
      productId: productId,
      quantityDelta: quantityDelta,
      reason: trimmedReason,
      createdBy: createdBy,
    );
  }
}
