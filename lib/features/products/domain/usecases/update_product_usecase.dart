import 'package:decimal/decimal.dart';
import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class UpdateProductUseCase {
  final ProductRepository _repository;

  const UpdateProductUseCase(this._repository);

  Future<Result<Product>> call(Product product) async {
    final cleanName = product.name.trim();
    if (cleanName.isEmpty) {
      return const FailureResult(
        ValidationFailure(
          field: 'name',
          message: 'اسم المنتج مطلوب ولا يمكن أن يكون فارغاً',
        ),
      );
    }

    final cleanUnit = product.unit.trim();
    if (cleanUnit.isEmpty) {
      return const FailureResult(
        ValidationFailure(
          field: 'unit',
          message: 'وحدة القياس مطلوبة',
        ),
      );
    }

    if (product.currentSalePrice.piastres < 0) {
      return const FailureResult(
        ValidationFailure(
          field: 'currentSalePrice',
          message: 'سعر البيع لا يمكن أن يكون سالباً',
        ),
      );
    }

    if (product.currentPurchasePrice.piastres < 0) {
      return const FailureResult(
        ValidationFailure(
          field: 'currentPurchasePrice',
          message: 'سعر الشراء لا يمكن أن يكون سالباً',
        ),
      );
    }

    if (product.lowStockThreshold != null && product.lowStockThreshold! < Decimal.zero) {
      return const FailureResult(
        ValidationFailure(
          field: 'lowStockThreshold',
          message: 'حد التنبيه للمخزون لا يمكن أن يكون سالباً',
        ),
      );
    }

    final cleanCode = product.code?.trim();
    if (cleanCode != null && cleanCode.isNotEmpty) {
      final existingResult = await _repository.getProductByCode(cleanCode);
      if (existingResult.isSuccess && existingResult.dataOrNull != null) {
        final existing = existingResult.dataOrNull!;
        if (existing.id != product.id) {
          return FailureResult(
            ConflictFailure(
              message: 'كود المنتج "$cleanCode" مستخدم بالفعل لمنتج آخر',
            ),
          );
        }
      }
    }

    final validatedProduct = product.copyWith(
      name: cleanName,
      unit: cleanUnit,
      code: cleanCode?.isEmpty ?? true ? null : cleanCode,
    );

    return _repository.updateProduct(validatedProduct);
  }
}
