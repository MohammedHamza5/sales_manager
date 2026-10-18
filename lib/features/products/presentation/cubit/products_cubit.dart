import 'dart:async';
import 'package:decimal/decimal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/money/money.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/add_product_usecase.dart';
import '../../domain/usecases/toggle_product_status_usecase.dart';
import '../../domain/usecases/update_product_usecase.dart';
import '../../domain/usecases/watch_products_usecase.dart';
import 'products_state.dart';

class ProductsCubit extends Cubit<ProductsState> {
  final WatchProductsUseCase _watchProductsUseCase;
  final AddProductUseCase _addProductUseCase;
  final UpdateProductUseCase _updateProductUseCase;
  final ToggleProductStatusUseCase _toggleProductStatusUseCase;

  StreamSubscription<List<Product>>? _productsSubscription;

  String _currentQuery = '';
  bool? _currentActiveFilter = true; // Default: show active products
  bool _currentLowStockFilter = false;

  ProductsCubit({
    required WatchProductsUseCase watchProductsUseCase,
    required AddProductUseCase addProductUseCase,
    required UpdateProductUseCase updateProductUseCase,
    required ToggleProductStatusUseCase toggleProductStatusUseCase,
  })  : _watchProductsUseCase = watchProductsUseCase,
        _addProductUseCase = addProductUseCase,
        _updateProductUseCase = updateProductUseCase,
        _toggleProductStatusUseCase = toggleProductStatusUseCase,
        super(const ProductsInitial());

  void init() {
    _subscribeToProducts();
  }

  void search(String query) {
    _currentQuery = query.trim();
    _subscribeToProducts();
  }

  void setFilterActive(bool? isActiveOnly) {
    _currentActiveFilter = isActiveOnly;
    _subscribeToProducts();
  }

  void toggleLowStockFilter() {
    _currentLowStockFilter = !_currentLowStockFilter;
    _subscribeToProducts();
  }

  void _subscribeToProducts() {
    emit(const ProductsLoading());
    _productsSubscription?.cancel();

    _productsSubscription = _watchProductsUseCase(
      query: _currentQuery.isEmpty ? null : _currentQuery,
      isActiveOnly: _currentActiveFilter,
    ).listen(
      (allProducts) {
        var filteredList = allProducts;
        if (_currentLowStockFilter) {
          filteredList = filteredList.where((p) => p.isLowStock).toList();
        }

        final hasFilters = _currentQuery.isNotEmpty ||
            _currentActiveFilter != null ||
            _currentLowStockFilter;

        if (filteredList.isEmpty) {
          emit(
            ProductsEmpty(
              message: hasFilters
                  ? 'لا توجد منتجات تطابق معايير البحث والترشيح'
                  : 'لا توجد منتجات مسجلة في النظام حتى الآن',
              hasActiveFilters: hasFilters,
            ),
          );
        } else {
          emit(
            ProductsLoaded(
              products: filteredList,
              searchQuery: _currentQuery,
              filterActiveOnly: _currentActiveFilter,
              filterLowStockOnly: _currentLowStockFilter,
            ),
          );
        }
      },
      onError: (Object error) {
        emit(ProductsError(message: 'حدث خطأ أثناء تحميل المنتجات: $error'));
      },
    );
  }

  Future<Result<Product>> addProduct({
    required String name,
    String? code,
    required String unit,
    required Money salePrice,
    required Money purchasePrice,
    Decimal? initialQuantity,
    Decimal? lowStockThreshold,
    String createdBy = 'admin',
  }) {
    return _addProductUseCase(
      name: name,
      code: code,
      unit: unit,
      salePrice: salePrice,
      purchasePrice: purchasePrice,
      initialQuantity: initialQuantity,
      lowStockThreshold: lowStockThreshold,
      createdBy: createdBy,
    );
  }

  Future<Result<Product>> updateProduct(Product product) {
    return _updateProductUseCase(product);
  }

  Future<Result<void>> toggleProductStatus(int id, bool isActive) {
    return _toggleProductStatusUseCase(id, isActive);
  }

  @override
  Future<void> close() {
    _productsSubscription?.cancel();
    return super.close();
  }
}
