import '../entities/product.dart';
import '../repositories/product_repository.dart';

class WatchProductsUseCase {
  final ProductRepository _repository;

  const WatchProductsUseCase(this._repository);

  Stream<List<Product>> call({
    String? query,
    bool? isActiveOnly,
  }) {
    return _repository.watchProducts(
      query: query,
      isActiveOnly: isActiveOnly,
    );
  }
}
