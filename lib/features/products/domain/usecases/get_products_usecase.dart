import '../../../../core/result/result.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProductsUseCase {
  final ProductRepository _repository;

  const GetProductsUseCase(this._repository);

  Future<Result<List<Product>>> call({
    String? query,
    bool? isActiveOnly,
    bool? isLowStockOnly,
  }) {
    return _repository.getProducts(
      query: query,
      isActiveOnly: isActiveOnly,
      isLowStockOnly: isLowStockOnly,
    );
  }
}
