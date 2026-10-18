import 'package:flutter/material.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/result/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/usecases/get_products_usecase.dart';

class ProductSelectorDialog extends StatefulWidget {
  const ProductSelectorDialog({super.key});

  static Future<Product?> show(BuildContext context) {
    return showDialog<Product>(
      context: context,
      builder: (_) => const ProductSelectorDialog(),
    );
  }

  @override
  State<ProductSelectorDialog> createState() => _ProductSelectorDialogState();
}

class _ProductSelectorDialogState extends State<ProductSelectorDialog> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadProducts({String? query}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final getProducts = getIt<GetProductsUseCase>();
    final result = await getProducts(
      query: query,
      isActiveOnly: true,
    );

    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        setState(() {
          _products = data;
          _isLoading = false;
        });
      case FailureResult(:final failure):
        setState(() {
          _error = failure.message;
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.inventory_2_outlined, color: colors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'اختيار منتج لإضافته للفاتورة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: true,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'ابحث بالاسم أو الباركود...',
                  hintStyle: TextStyle(color: colors.textSecondary),
                  prefixIcon: Icon(Icons.search, color: colors.primary),
                  filled: true,
                  fillColor: colors.surfaceElevated,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (val) => _loadProducts(query: val),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final colors = context.colors;
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: TextStyle(color: colors.danger),
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_outlined, size: 48, color: colors.textSecondary),
            const SizedBox(height: 12),
            Text(
              'لا توجد منتجات مطابقة للبحث',
              style: TextStyle(color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _products.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: colors.border),
      itemBuilder: (context, index) {
        final product = _products[index];
        return ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          hoverColor: colors.primaryLight,
          title: Text(
            product.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          subtitle: Text(
            'الكود: ${product.code ?? "لا يوجد"} · المخزون الحالي: ${product.currentQuantity} ${product.unit}',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          trailing: Text(
            'سعر الشراء: ${product.currentPurchasePrice.formatted}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
          onTap: () => Navigator.of(context).pop(product),
        );
      },
    );
  }
}
