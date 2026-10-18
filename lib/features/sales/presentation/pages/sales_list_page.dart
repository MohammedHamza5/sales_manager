import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/states/empty_view.dart';
import '../../../../core/widgets/states/error_view.dart';
import '../../../../core/widgets/states/loading_view.dart';
import '../../../../core/widgets/app_kpi_card.dart';
import '../../domain/entities/sale.dart';
import '../cubit/sales_list_cubit.dart';
import '../cubit/sales_list_state.dart';

class SalesListPage extends StatelessWidget {
  const SalesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SalesListCubit(getIt())..init(),
      child: const _SalesListView(),
    );
  }
}

class _SalesListView extends StatefulWidget {
  const _SalesListView();

  @override
  State<_SalesListView> createState() => _SalesListViewState();
}

class _SalesListViewState extends State<_SalesListView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SalesListCubit>();
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Page Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.sales,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      AppSpacing.verticalXs,
                      Text(
                        'سجل فواتير المبيعات، ومتابعة التحصيلات النقدية والآجلة',
                        style: TextStyle(fontSize: 13, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                  onPressed: () => context.push('/sales/create'),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text(
                    AppStrings.newSale,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            AppSpacing.verticalMd,

            // Main Content Area
            Expanded(
              child: BlocBuilder<SalesListCubit, SalesListState>(
                builder: (context, state) {
                  return switch (state) {
                    SalesListInitial() || SalesListLoading() =>
                      const LoadingView(message: 'جاري تحميل فواتير المبيعات...'),
                    SalesListEmpty(message: final msg) => EmptyView(
                        title: msg,
                        icon: Icons.receipt_long_outlined,
                        actionLabel: AppStrings.newSale,
                        onAction: () => context.push('/sales/create'),
                      ),
                    SalesListError(message: final msg) => ErrorView(
                        message: msg,
                        onRetry: () => cubit.init(),
                      ),
                    SalesListLoaded() => _buildLoadedView(context, state, cubit),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedView(
    BuildContext context,
    SalesListLoaded state,
    SalesListCubit cubit,
  ) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // KPI Summary Cards
        Row(
          children: [
            Expanded(
              child: AppKpiCard(
                title: AppStrings.salesCount,
                value: '${state.confirmedCount} فاتورة',
                subtitle: state.reversedCount > 0 ? '(${state.reversedCount} مُلغاة)' : null,
                icon: Icons.receipt_outlined,
                color: colors.primary,
              ),
            ),
            AppSpacing.horizontalMd,
            Expanded(
              child: AppKpiCard(
                title: AppStrings.totalSales,
                value: state.totalSalesAmount.formatArabic(),
                icon: Icons.payments_outlined,
                color: const Color(0xFF0284C7),
              ),
            ),
            AppSpacing.horizontalMd,
            Expanded(
              child: AppKpiCard(
                title: AppStrings.totalPaid,
                value: state.totalPaidAmount.formatArabic(),
                icon: Icons.savings_outlined,
                color: colors.success,
              ),
            ),
            AppSpacing.horizontalMd,
            Expanded(
              child: AppKpiCard(
                title: AppStrings.totalRemaining,
                value: state.totalRemainingAmount.formatArabic(),
                icon: Icons.account_balance_wallet_outlined,
                color: colors.danger,
              ),
            ),
          ],
        ),
        AppSpacing.verticalMd,

        // Toolbar: Search & Filter Chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'ابحث برقم الفاتورة، اسم العميل، الهاتف...',
                    hintStyle: TextStyle(color: colors.textMuted),
                    prefixIcon: Icon(Icons.search, size: 20, color: colors.textMuted),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: colors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      borderSide: BorderSide(color: colors.primary),
                    ),
                  ),
                  onChanged: (val) => cubit.search(val),
                ),
              ),
              AppSpacing.horizontalMd,
              _buildFilterChip(
                context: context,
                label: 'الكل',
                isSelected: state.statusFilter == null,
                onSelected: () => cubit.filterByStatus(null),
              ),
              AppSpacing.horizontalSm,
              _buildFilterChip(
                context: context,
                label: 'مؤكدة',
                isSelected: state.statusFilter == SaleStatus.confirmed,
                onSelected: () => cubit.filterByStatus(SaleStatus.confirmed),
              ),
              AppSpacing.horizontalSm,
              _buildFilterChip(
                context: context,
                label: 'مُلغاة',
                isSelected: state.statusFilter == SaleStatus.reversed,
                onSelected: () => cubit.filterByStatus(SaleStatus.reversed),
              ),
            ],
          ),
        ),
        AppSpacing.verticalMd,

        // Data Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: colors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: SingleChildScrollView(
                child: SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(colors.surfaceElevated),
                    headingTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                      fontSize: 13,
                    ),
                    dataTextStyle: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                    ),
                    horizontalMargin: AppSpacing.md,
                    columnSpacing: AppSpacing.lg,
                    columns: const [
                      DataColumn(label: Text('رقم الفاتورة')),
                      DataColumn(label: Text('التاريخ')),
                      DataColumn(label: Text('العميل')),
                      DataColumn(label: Text('الإجمالي')),
                      DataColumn(label: Text('المدفوع')),
                      DataColumn(label: Text('المتبقي')),
                      DataColumn(label: Text('الحالة وطريقة الدفع')),
                      DataColumn(label: Text('إجراء')),
                    ],
                    rows: state.filteredSales.map((sale) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              '#${sale.invoiceNo}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                            ),
                          ),
                          DataCell(Text(DateFormat('yyyy/MM/dd').format(sale.saleDate))),
                          DataCell(
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(sale.customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                if (sale.customerPhone != null)
                                  Text(sale.customerPhone!, style: TextStyle(fontSize: 11, color: colors.textMuted)),
                              ],
                            ),
                          ),
                          DataCell(Text(sale.totalAmount.formatArabic())),
                          DataCell(Text(sale.paidAmountAtCreation.formatArabic())),
                          DataCell(
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sale.remainingAmount.formatArabic(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: sale.remainingAmount.piastres > 0 ? colors.danger : colors.success,
                                  ),
                                ),
                                if (sale.hasReturns)
                                  Text(
                                    'مرتجع: ${sale.returnedAmount.formatArabic()}',
                                    style: TextStyle(fontSize: 10, color: colors.warning, fontWeight: FontWeight.w600),
                                  ),
                              ],
                            ),
                          ),
                          DataCell(_buildStatusBadge(context, sale)),
                          DataCell(
                            IconButton(
                              icon: Icon(Icons.visibility_outlined, color: colors.primary),
                              tooltip: 'عرض تفاصيل الفاتورة',
                              onPressed: () => context.push('/sales/${sale.id}'),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    final colors = context.colors;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: colors.primary,
      backgroundColor: colors.surfaceElevated,
      side: BorderSide(
        color: isSelected ? colors.primary : colors.border,
      ),
      labelStyle: TextStyle(
        color: isSelected ? colors.onPrimary : colors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (_) => onSelected(),
    );
  }

  Widget _buildStatusBadge(BuildContext context, Sale sale) {
    final colors = context.colors;

    if (sale.isReversed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colors.textMuted.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          'مُلغاة',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textSecondary),
        ),
      );
    }

    final String text;
    final Color badgeColor;

    if (sale.isFullyPaid) {
      text = sale.hasReturns ? 'مسددة (مع مرتجع)' : 'نقدي (مسدد)';
      badgeColor = colors.success;
    } else if (sale.isPartial) {
      text = sale.hasReturns ? 'جزئي (مع مرتجع)' : 'جزئي';
      badgeColor = colors.warning;
    } else {
      text = sale.hasReturns ? 'آجل (مع مرتجع)' : 'آجل بالكامل';
      badgeColor = colors.danger;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
      ),
    );
  }
}
