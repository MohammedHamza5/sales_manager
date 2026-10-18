import 'package:decimal/decimal.dart';
import '../../../../core/money/money.dart';
import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class AddProductUseCase {
  final ProductRepository _repository;

  const AddProductUseCase(this._repository);

  Future<Result<Product>> call({
    required String name,
    String? code,
    required String unit,
    required Money salePrice,
    required Money purchasePrice,
    Decimal? initialQuantity,
    Decimal? lowStockThreshold,
    String createdBy = 'admin',
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      return const FailureResult(
        ValidationFailure(
          field: 'name',
          message: 'اسم المنتج مطلوب ولا يمكن أن يكون فارغاً',
        ),
      );
    }

    final cleanUnit = unit.trim();
    if (cleanUnit.isEmpty) {
      return const FailureResult(
        ValidationFailure(
          field: 'unit',
          message: 'وحدة القياس مطلوبة (مثال: قطعة، كيلو، علبة)',
        ),
      );
    }

    if (salePrice.piastres < 0) {
      return const FailureResult(
        ValidationFailure(
          field: 'salePrice',
          message: 'سعر البيع لا يمكن أن يكون سالباً',
        ),
      );
    }

    if (purchasePrice.piastres < 0) {
      return const FailureResult(
        ValidationFailure(
          field: 'purchasePrice',
          message: 'سعر الشراء لا يمكن أن يكون سالباً',
        ),
      );
    }

    if (initialQuantity != null && initialQuantity < Decimal.zero) {
      return const FailureResult(
        ValidationFailure(
          field: 'initialQuantity',
          message: 'الكمية الافتتاحية لا يمكن أن تكون سالبة',
        ),
      );
    }

    if (lowStockThreshold != null && lowStockThreshold < Decimal.zero) {
      return const FailureResult(
        ValidationFailure(
          field: 'lowStockThreshold',
          message: 'حد التنبيه للمخزون لا يمكن أن يكون سالباً',
        ),
      );
    }

    final cleanCode = code?.trim();
    if (cleanCode != null && cleanCode.isNotEmpty) {
      final existingResult = await _repository.getProductByCode(cleanCode);
      if (existingResult.isSuccess && existingResult.dataOrNull != null) {
        return FailureResult(
          ConflictFailure(
            message: 'كود المنتج "$cleanCode" مستخدم بالفعل لمنتج آخر',
          ),
        );
      }
    }

    return _repository.addProduct(
      name: cleanName,
      code: cleanCode?.isEmpty ?? true ? null : cleanCode,
      unit: cleanUnit,
      salePrice: salePrice,
      purchasePrice: purchasePrice,
      initialQuantity: initialQuantity,
      lowStockThreshold: lowStockThreshold,
      createdBy: createdBy,
    );
  }
}
