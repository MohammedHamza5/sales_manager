import 'package:decimal/decimal.dart';
import '../../../../core/money/money.dart';
import '../../../../core/result/result.dart';
import '../entities/product.dart';

abstract class ProductRepository {
  /// Fetch list of products with optional search query and filters.
  Future<Result<List<Product>>> getProducts({
    String? query,
    bool? isActiveOnly,
    bool? isLowStockOnly,
  });

  /// Real-time reactive stream of products for UI / Dashboard.
  Stream<List<Product>> watchProducts({
    String? query,
    bool? isActiveOnly,
  });

  /// Retrieve a specific product by its ID.
  Future<Result<Product>> getProductById(int id);

  /// Find product by code.
  Future<Result<Product?>> getProductByCode(String code);

  /// Add a new product. If [initialQuantity] > 0, an opening balance movement is atomically generated.
  Future<Result<Product>> addProduct({
    required String name,
    String? code,
    required String unit,
    required Money salePrice,
    required Money purchasePrice,
    Decimal? initialQuantity,
    Decimal? lowStockThreshold,
    String createdBy = 'admin',
  });

  /// Update an existing product's metadata and prices.
  Future<Result<Product>> updateProduct(Product product);

  /// Toggle activation status (active / inactive) - No hard delete allowed.
  Future<Result<void>> toggleProductStatus(int id, bool isActive);
}
