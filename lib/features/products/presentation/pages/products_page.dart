import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/money/quantity.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/states/empty_view.dart';
import '../../../../core/widgets/states/error_view.dart';
import '../../../../core/widgets/states/loading_view.dart';
import '../../domain/entities/product.dart';
import '../cubit/products_cubit.dart';
import '../cubit/products_state.dart';
import '../widgets/product_form_dialog.dart';
import '../../../inventory/presentation/widgets/product_movements_dialog.dart';
import '../../../inventory/presentation/widgets/stock_adjustment_dialog.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductsCubit(
        watchProductsUseCase: getIt(),
        addProductUseCase: getIt(),
        updateProductUseCase: getIt(),
        toggleProductStatusUseCase: getIt(),
      )..init(),
      child: const _ProductsView(),
    );
  }
}

class _ProductsView extends StatefulWidget {
  const _ProductsView();

  @override
  State<_ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<_ProductsView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<ProductsCubit>().search(query);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProductsCubit>();
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Title & Add Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.products,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    AppSpacing.verticalXs,
                    Text(
                      'إدارة وتتبع قائمة المنتجات وأسعارها والكميات المتاحة',
                      style: TextStyle(fontSize: 13, color: colors.textSecondary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => ProductFormDialog.show(context, cubit),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('إضافة منتج جديد'),
                ),
              ],
            ),
            AppSpacing.verticalMd,

            // Filter & Search Toolbar
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  // Search Bar
                  Expanded(
                    flex: 4,
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: colors.textPrimary),
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'البحث باسم المنتج أو الكود...',
                        hintStyle: TextStyle(color: colors.textMuted),
                        prefixIcon: Icon(Icons.search, color: colors.textSecondary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, size: 18, color: colors.textSecondary),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: colors.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colors.primary),
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  AppSpacing.horizontalMd,

                  // Filter Chips
                  BlocBuilder<ProductsCubit, ProductsState>(
                    builder: (context, state) {
                      final activeFilter = state is ProductsLoaded ? state.filterActiveOnly : true;
                      final lowStockFilter = state is ProductsLoaded ? state.filterLowStockOnly : false;

                      return Row(
                        children: [
                          FilterChip(
                            label: Text(
                              'النشطة فقط',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: activeFilter == true ? colors.onPrimary : colors.textSecondary,
                              ),
                            ),
                            selected: activeFilter == true,
                            selectedColor: colors.primary,
                            backgroundColor: colors.surfaceElevated,
                            side: BorderSide(
                              color: activeFilter == true ? colors.primary : colors.border,
                            ),
                            onSelected: (_) => cubit.setFilterActive(true),
                          ),
                          AppSpacing.horizontalSm,
                          FilterChip(
                            label: Text(
                              'الكل',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: activeFilter == null ? colors.onPrimary : colors.textSecondary,
                              ),
                            ),
                            selected: activeFilter == null,
                            selectedColor: colors.primary,
                            backgroundColor: colors.surfaceElevated,
                            side: BorderSide(
                              color: activeFilter == null ? colors.primary : colors.border,
                            ),
                            onSelected: (_) => cubit.setFilterActive(null),
                          ),
                          AppSpacing.horizontalSm,
                          FilterChip(
                            label: Text(
                              'المعطلة',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: activeFilter == false ? colors.onPrimary : colors.textSecondary,
                              ),
                            ),
                            selected: activeFilter == false,
                            selectedColor: colors.primary,
                            backgroundColor: colors.surfaceElevated,
                            side: BorderSide(
                              color: activeFilter == false ? colors.primary : colors.border,
                            ),
                            onSelected: (_) => cubit.setFilterActive(false),
                          ),
                          AppSpacing.horizontalSm,
                          FilterChip(
                            avatar: Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: lowStockFilter ? colors.onPrimary : colors.warning,
                            ),
                            label: Text(
                              'نواقص المخزون',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: lowStockFilter ? colors.onPrimary : colors.warning,
                              ),
                            ),
                            selected: lowStockFilter,
                            selectedColor: colors.warning,
                            backgroundColor: colors.surfaceElevated,
                            side: BorderSide(
                              color: lowStockFilter ? colors.warning : colors.border,
                            ),
                            onSelected: (_) => cubit.toggleLowStockFilter(),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            AppSpacing.verticalMd,

            // Body Area with the 4 States
            Expanded(
              child: BlocBuilder<ProductsCubit, ProductsState>(
                builder: (context, state) {
                  return switch (state) {
                    ProductsInitial() || ProductsLoading() => const LoadingView(),
                    ProductsError(message: final msg) => ErrorView(
                        message: msg,
                        onRetry: () => cubit.init(),
                      ),
                    ProductsEmpty(message: final msg, hasActiveFilters: final hasFilters) => EmptyView(
                        title: msg,
                        subtitle: hasFilters
                            ? 'جرّب تغيير كلمات البحث أو إلغاء فلاتر التصفية'
                            : 'ابدأ بإضافة أول منتج لمخزنك الآن',
                        icon: hasFilters ? Icons.search_off_rounded : Icons.inventory_2_outlined,
                        actionLabel: hasFilters ? 'إلغاء الفلاتر' : 'إضافة منتج جديد',
                        onAction: hasFilters
                            ? () {
                                _searchController.clear();
                                cubit.search('');
                                cubit.setFilterActive(true);
                                if (state.hasActiveFilters) {
                                  cubit.toggleLowStockFilter();
                                }
                              }
                            : () => ProductFormDialog.show(context, cubit),
                      ),
                    ProductsLoaded(
                      products: final items,
                      lowStockCount: final lowCount,
                      outOfStockCount: final outCount,
                    ) =>
                      Column(
                        children: [
                          // Quick KPIs
                          Row(
                            children: [
                              _buildMetricCard(
                                context: context,
                                label: 'إجمالي الأصناف المعروضة',
                                value: '${items.length}',
                                icon: Icons.category_outlined,
                                color: colors.primary,
                              ),
                              AppSpacing.horizontalMd,
                              _buildMetricCard(
                                context: context,
                                label: 'أصناف بلغت حد الطلب',
                                value: '$lowCount',
                                icon: Icons.warning_amber_rounded,
                                color: colors.warning,
                              ),
                              AppSpacing.horizontalMd,
                              _buildMetricCard(
                                context: context,
                                label: 'أصناف نفدت بالكامل',
                                value: '$outCount',
                                icon: Icons.remove_shopping_cart_outlined,
                                color: colors.danger,
                              ),
                            ],
                          ),
                          AppSpacing.verticalMd,

                          // Products DataTable
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colors.border),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(colors.surfaceElevated),
                                    dataRowColor: WidgetStateProperty.all(colors.surface),
                                    headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
                                    columns: const [
                                      DataColumn(label: Text('كود الصنف')),
                                      DataColumn(label: Text('اسم المنتج')),
                                      DataColumn(label: Text('الوحدة')),
                                      DataColumn(label: Text('سعر الشراء')),
                                      DataColumn(label: Text('سعر البيع')),
                                      DataColumn(label: Text('هامش الربح')),
                                      DataColumn(label: Text('الرصيد المتاح')),
                                      DataColumn(label: Text('حد التنبيه')),
                                      DataColumn(label: Text('الحالة')),
                                      DataColumn(label: Text('الإجراءات')),
                                    ],
                                    rows: items.map((product) => _buildProductRow(context, cubit, product)).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final colors = context.colors;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            AppSpacing.horizontalMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildProductRow(BuildContext context, ProductsCubit cubit, Product product) {
    final colors = context.colors;

    return DataRow(
      cells: [
        DataCell(Text(product.code ?? '—', style: TextStyle(fontFamily: 'monospace', color: colors.textSecondary))),
        DataCell(
          Text(
            product.name,
            style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary),
          ),
        ),
        DataCell(Text(product.unit, style: TextStyle(color: colors.textSecondary))),
        DataCell(Text(product.currentPurchasePrice.formatArabic(), style: TextStyle(color: colors.textPrimary))),
        DataCell(Text(product.currentSalePrice.formatArabic(), style: TextStyle(color: colors.textPrimary))),
        DataCell(
          Text(
            product.currentUnitMargin.formatArabic(),
            style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                QuantityHelper.format(product.currentQuantity),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: product.isOutOfStock
                      ? colors.danger
                      : product.isLowStock
                          ? colors.warning
                          : colors.textPrimary,
                ),
              ),
              if (product.isLowStock) ...[
                AppSpacing.horizontalXs,
                Tooltip(
                  message: 'الرصيد وصل أو تجاوز حد تنبيه النقص',
                  child: Icon(Icons.warning_amber_rounded, size: 16, color: colors.warning),
                ),
              ],
            ],
          ),
        ),
        DataCell(
          Text(
            product.lowStockThreshold != null
                ? QuantityHelper.format(product.lowStockThreshold!)
                : '—',
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (product.isActive ? colors.success : colors.textSecondary).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                color: (product.isActive ? colors.success : colors.textSecondary).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              product.isActive ? 'نشط' : 'معطل',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: product.isActive ? colors.success : colors.textSecondary,
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.tune_rounded, size: 19, color: colors.accent),
                tooltip: 'تسوية مخزنية سريعة',
                onPressed: () => StockAdjustmentDialog.show(
                  context,
                  preselectedProduct: product,
                ),
              ),
              IconButton(
                icon: Icon(Icons.history_rounded, size: 20, color: colors.info),
                tooltip: 'سجل حركة المخزون',
                onPressed: () => ProductMovementsDialog.show(context, product),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 18, color: colors.primary),
                tooltip: AppStrings.edit,
                onPressed: () => ProductFormDialog.show(context, cubit, product),
              ),
              IconButton(
                icon: Icon(
                  product.isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                  size: 24,
                  color: product.isActive ? colors.success : colors.textSecondary,
                ),
                tooltip: product.isActive ? 'إيقاف المنتج' : 'تفعيل المنتج',
                onPressed: () => cubit.toggleProductStatus(product.id, !product.isActive),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
