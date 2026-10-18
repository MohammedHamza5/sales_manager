import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/money/quantity.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_kpi_card.dart';
import '../../../../core/widgets/states/empty_view.dart';
import '../../../../core/widgets/states/error_view.dart';
import '../../../../core/widgets/states/loading_view.dart';
import '../../../products/domain/entities/product.dart';
import '../../domain/entities/inventory_movement.dart';
import '../cubit/product_movements_cubit.dart';
import '../cubit/product_movements_state.dart';
import 'stock_adjustment_dialog.dart';

class ProductMovementsDialog extends StatelessWidget {
  final Product product;

  const ProductMovementsDialog({super.key, required this.product});

  static Future<void> show(BuildContext context, Product product) {
    return showDialog<void>(
      context: context,
      builder: (context) => BlocProvider(
        create: (context) => ProductMovementsCubit(
          watchMovementsUseCase: getIt(),
          productId: product.id,
        )..init(),
        child: ProductMovementsDialog(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProductMovementsCubit>();
    final colors = context.colors;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colors.primaryLight,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Icon(Icons.history_rounded, color: colors.primary, size: 26),
                        ),
                        AppSpacing.horizontalMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    product.name,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  if (product.code != null) ...[
                                    AppSpacing.horizontalSm,
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: colors.surfaceElevated,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: colors.border),
                                      ),
                                      child: Text(
                                        product.code!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              AppSpacing.verticalXs,
                              Text(
                                'كشف حركة الصنف وسجل الدخول والخروج والمبيعات والمشتريات',
                                style: TextStyle(fontSize: 12, color: colors.textSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.accent,
                          side: BorderSide(color: colors.accent),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        label: const Text('تسوية لهذا الصنف'),
                        onPressed: () {
                          StockAdjustmentDialog.show(
                            context,
                            preselectedProduct: product,
                          );
                        },
                      ),
                      AppSpacing.horizontalSm,
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                        tooltip: AppStrings.cancel,
                      ),
                    ],
                  ),
                ],
              ),
              Divider(height: 24, thickness: 1, color: colors.border),

              // 2. Body Area
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
                              ? 'لا توجد حركات مخزنية مسجلة تطابق النوع المختار'
                              : 'لم يتم تسجيل أي حركة بيع أو شراء أو تسوية لهذا المنتج بعد',
                          icon: Icons.inventory_2_outlined,
                          actionLabel: hasFilter ? 'عرض كل الحركات' : null,
                          onAction: hasFilter ? () => cubit.setFilterType(null) : null,
                        ),
                      ProductMovementsLoaded(
                        movements: final movements,
                        filterType: final selectedFilter,
                        totalInflow: final inflow,
                        totalOutflow: final outflow,
                      ) =>
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Summary KPIs
                            Row(
                              children: [
                                _buildSummaryCard(
                                  context: context,
                                  label: 'الرصيد الفعلي الحالي',
                                  value: '${QuantityHelper.format(product.currentQuantity)} ${product.unit}',
                                  icon: Icons.warehouse_rounded,
                                  color: colors.primary,
                                ),
                                AppSpacing.horizontalMd,
                                _buildSummaryCard(
                                  context: context,
                                  label: 'إجمالي الوارد (+)',
                                  value: '+ ${QuantityHelper.format(inflow)} ${product.unit}',
                                  icon: Icons.arrow_downward_rounded,
                                  color: colors.success,
                                ),
                                AppSpacing.horizontalMd,
                                _buildSummaryCard(
                                  context: context,
                                  label: 'إجمالي المنصرف (-)',
                                  value: '- ${QuantityHelper.format(outflow)} ${product.unit}',
                                  icon: Icons.arrow_upward_rounded,
                                  color: colors.danger,
                                ),
                                AppSpacing.horizontalMd,
                                _buildSummaryCard(
                                  context: context,
                                  label: 'عدد الحركات',
                                  value: '${movements.length}',
                                  icon: Icons.receipt_long_rounded,
                                  color: colors.textPrimary,
                                ),
                              ],
                            ),
                            AppSpacing.verticalMd,

                            // Filter Chips
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ChoiceChip(
                                  label: Text(
                                    'كل الحركات',
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
                                  return ChoiceChip(
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
                                  );
                                }),
                              ],
                            ),
                            AppSpacing.verticalMd,

                            // Table of movements
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
                                        DataColumn(label: Text('نوع الحركة')),
                                        DataColumn(label: Text('الكمية')),
                                        DataColumn(label: Text('الرصيد بعدها')),
                                        DataColumn(label: Text('البيان / الملاحظات')),
                                        DataColumn(label: Text('المسؤول')),
                                      ],
                                      rows: movements.map((m) => _buildMovementRow(context, m)).toList(),
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
      ),
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: AppKpiCard(
        title: label,
        value: value,
        icon: icon,
        color: color,
      ),
    );
  }

  DataRow _buildMovementRow(BuildContext context, InventoryMovement movement) {
    final colors = context.colors;
    final dateFormat = DateFormat('yyyy/MM/dd - hh:mm a');
    final isPositive = movement.isInflow;

    return DataRow(
      cells: [
        DataCell(Text(dateFormat.format(movement.createdAt), style: TextStyle(fontSize: 12, color: colors.textSecondary))),
        DataCell(_buildTypeBadge(context, movement.type)),
        DataCell(
          Text(
            '${isPositive ? '+' : ''} ${QuantityHelper.format(movement.quantityDelta)} ${product.unit}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isPositive ? colors.success : colors.danger,
            ),
          ),
        ),
        DataCell(
          Text(
            '${QuantityHelper.format(movement.balanceAfter)} ${product.unit}',
            style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary),
          ),
        ),
        DataCell(
          Text(
            movement.note ?? '—',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
        ),
        DataCell(
          Text(
            movement.createdBy,
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
