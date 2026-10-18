import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/money/quantity.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/states/empty_view.dart';
import '../../../../core/widgets/states/error_view.dart';
import '../../../../core/widgets/states/loading_view.dart';
import '../../domain/entities/inventory_movement.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/usecases/get_products_usecase.dart';
import '../cubit/product_movements_cubit.dart';
import '../cubit/product_movements_state.dart';
import '../widgets/stock_adjustment_dialog.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductMovementsCubit(
        watchMovementsUseCase: getIt(),
        productId: null, // null = all warehouse movements
      )..init(),
      child: const _InventoryView(),
    );
  }
}

class _InventoryView extends StatelessWidget {
  const _InventoryView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProductMovementsCubit>();
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.inventoryMovements,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    AppSpacing.verticalXs,
                    Text(
                      'السجل الموحد لجميع حركات دخول وخروج وتعديل المخزون في المنشأة',
                      style: TextStyle(fontSize: 13, color: colors.textSecondary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.tune_rounded, size: 20),
                  label: const Text('تسوية مخزنية يدوية'),
                  onPressed: () async {
                    final getProducts = getIt<GetProductsUseCase>();
                    final result = await getProducts();
                    if (context.mounted) {
                      final products = result.isSuccess ? (result.dataOrNull ?? <Product>[]) : <Product>[];
                      await StockAdjustmentDialog.show(
                        context,
                        availableProducts: products,
                      );
                    }
                  },
                ),
              ],
            ),
            AppSpacing.verticalMd,

            // Filter Toolbar
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: BlocBuilder<ProductMovementsCubit, ProductMovementsState>(
                builder: (context, state) {
                  final selectedFilter =
                      state is ProductMovementsLoaded ? state.filterType : null;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: Text(
                            'جميع العمليات',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: selectedFilter == null ? colors.onPrimary : colors.textSecondary,
                            ),
                          ),
                          selected: selectedFilter == null,
                          selectedColor: colors.primary,
                          backgroundColor: colors.surfaceElevated,
                          side: BorderSide(
                            color: selectedFilter == null ? colors.primary : colors.border,
                          ),
                          onSelected: (_) => cubit.setFilterType(null),
                        ),
                        ...MovementType.values.map((type) {
                          final isSelected = selectedFilter == type;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(
                                type.arabicTitle,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? colors.onPrimary : colors.textSecondary,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: colors.primary,
                              backgroundColor: colors.surfaceElevated,
                              side: BorderSide(
                                color: isSelected ? colors.primary : colors.border,
                              ),
                              onSelected: (_) => cubit.setFilterType(type),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
            AppSpacing.verticalMd,

            // Body Area with 4 States
            Expanded(
              child: BlocBuilder<ProductMovementsCubit, ProductMovementsState>(
                builder: (context, state) {
                  return switch (state) {
                    ProductMovementsInitial() || ProductMovementsLoading() => const LoadingView(),
                    ProductMovementsError(message: final msg) => ErrorView(
                        message: msg,
                        onRetry: () => cubit.init(),
                      ),
                    ProductMovementsEmpty(message: final msg, hasFilter: final hasFilter) => EmptyView(
                        title: msg,
                        subtitle: hasFilter
                            ? 'لا توجد حركات تطابق الفلتر المختار'
                            : 'لا توجد أي حركات مخزنية مسجلة بالنظام حتى الآن',
                        icon: Icons.history_toggle_off_rounded,
                        actionLabel: hasFilter ? 'إلغاء الفلتر' : null,
                        onAction: hasFilter ? () => cubit.setFilterType(null) : null,
                      ),
                    ProductMovementsLoaded(
                      movements: final movements,
                      totalInflow: final inflow,
                      totalOutflow: final outflow,
                    ) =>
                      Column(
                        children: [
                          // Quick KPIs
                          Row(
                            children: [
                              _buildMetricCard(
                                context: context,
                                label: 'إجمالي العمليات المسجلة',
                                value: '${movements.length}',
                                icon: Icons.history_rounded,
                                color: colors.primary,
                              ),
                              AppSpacing.horizontalMd,
                              _buildMetricCard(
                                context: context,
                                label: 'مجموع الكميات الواردة (+)',
                                value: '+ ${QuantityHelper.format(inflow)}',
                                icon: Icons.arrow_downward_rounded,
                                color: colors.success,
                              ),
                              AppSpacing.horizontalMd,
                              _buildMetricCard(
                                context: context,
                                label: 'مجموع الكميات المنصرفة (-)',
                                value: '- ${QuantityHelper.format(outflow)}',
                                icon: Icons.arrow_upward_rounded,
                                color: colors.danger,
                              ),
                            ],
                          ),
                          AppSpacing.verticalMd,

                          // Table
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
                                      DataColumn(label: Text('التاريخ والوقت')),
                                      DataColumn(label: Text('اسم المنتج')),
                                      DataColumn(label: Text('نوع الحركة')),
                                      DataColumn(label: Text('الكمية')),
                                      DataColumn(label: Text('الرصيد بعدها')),
                                      DataColumn(label: Text('البيان / الملاحظات')),
                                      DataColumn(label: Text('المسؤول')),
                                    ],
                                    rows: movements.map((m) => _buildRow(context, m)).toList(),
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
                  Text(label, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                  Text(
                    value,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, InventoryMovement m) {
    final colors = context.colors;
    final dateFormat = DateFormat('yyyy/MM/dd - hh:mm a');
    final isPositive = m.isInflow;
    final unit = m.productUnit ?? '';

    return DataRow(
      cells: [
        DataCell(Text(dateFormat.format(m.createdAt), style: TextStyle(fontSize: 12, color: colors.textSecondary))),
        DataCell(
          Text(
            m.productName ?? 'صنف #${m.productId}',
            style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary),
          ),
        ),
        DataCell(_buildTypeBadge(context, m.type)),
        DataCell(
          Text(
            '${isPositive ? '+' : ''} ${QuantityHelper.format(m.quantityDelta)} $unit',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isPositive ? colors.success : colors.danger,
            ),
          ),
        ),
        DataCell(
          Text(
            '${QuantityHelper.format(m.balanceAfter)} $unit',
            style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary),
          ),
        ),
        DataCell(
          Text(
            m.note ?? '—',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
        ),
        DataCell(
          Text(
            m.createdBy,
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeBadge(BuildContext context, MovementType type) {
    final colors = context.colors;
    final (color, icon) = switch (type) {
      MovementType.openingBalance => (colors.primary, Icons.lock_clock_outlined),
      MovementType.purchase => (colors.success, Icons.local_shipping_outlined),
      MovementType.sale => (colors.danger, Icons.shopping_cart_outlined),
      MovementType.customerReturn => (colors.info, Icons.assignment_return_outlined),
      MovementType.supplierReturn => (colors.warning, Icons.assignment_returned_outlined),
      MovementType.adjustment => (colors.accent, Icons.tune_rounded),
      MovementType.reversal => (colors.textSecondary, Icons.undo_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            type.arabicTitle,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
