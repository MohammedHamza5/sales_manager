import 'package:equatable/equatable.dart';
import '../../domain/entities/product.dart';

sealed class ProductsState extends Equatable {
  const ProductsState();

  @override
  List<Object?> get props => [];
}

final class ProductsInitial extends ProductsState {
  const ProductsInitial();
}

final class ProductsLoading extends ProductsState {
  const ProductsLoading();
}

final class ProductsEmpty extends ProductsState {
  final String message;
  final bool hasActiveFilters;

  const ProductsEmpty({
    required this.message,
    this.hasActiveFilters = false,
  });

  @override
  List<Object?> get props => [message, hasActiveFilters];
}

final class ProductsError extends ProductsState {
  final String message;

  const ProductsError({required this.message});

  @override
  List<Object?> get props => [message];
}

final class ProductsLoaded extends ProductsState {
  final List<Product> products;
  final String searchQuery;
  final bool? filterActiveOnly;
  final bool filterLowStockOnly;

  const ProductsLoaded({
    required this.products,
    this.searchQuery = '',
    this.filterActiveOnly = true,
    this.filterLowStockOnly = false,
  });

  int get totalCount => products.length;
  int get lowStockCount => products.where((p) => p.isLowStock).length;
  int get outOfStockCount => products.where((p) => p.isOutOfStock).length;

  ProductsLoaded copyWith({
    List<Product>? products,
    String? searchQuery,
    bool? filterActiveOnly,
    bool? filterLowStockOnly,
  }) {
    return ProductsLoaded(
      products: products ?? this.products,
      searchQuery: searchQuery ?? this.searchQuery,
      filterActiveOnly: filterActiveOnly ?? this.filterActiveOnly,
      filterLowStockOnly: filterLowStockOnly ?? this.filterLowStockOnly,
    );
  }

  @override
  List<Object?> get props => [
        products,
        searchQuery,
        filterActiveOnly,
        filterLowStockOnly,
      ];
}
