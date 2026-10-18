import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/money/money.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/states/empty_view.dart';
import '../../../../core/widgets/states/error_view.dart';
import '../../../../core/widgets/states/loading_view.dart';
import '../../../../core/widgets/app_kpi_card.dart';
import '../../domain/entities/cashbox_transaction_entity.dart';
import '../cubit/cashbox_cubit.dart';
import '../cubit/cashbox_state.dart';

class CashboxPage extends StatelessWidget {
  const CashboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CashboxCubit(
        watchTransactions: getIt(),
        watchBalance: getIt(),
        watchSummary: getIt(),
      )..init(),
      child: const _CashboxView(),
    );
  }
}

class _CashboxView extends StatelessWidget {
  const _CashboxView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CashboxCubit>();
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: BlocBuilder<CashboxCubit, CashboxState>(
        builder: (context, state) {
          return switch (state) {
            CashboxInitial() || CashboxLoading() => const LoadingView(),
            CashboxError(message: final msg) => ErrorView(
                message: msg,
                onRetry: () => cubit.init(),
              ),
            CashboxLoaded() => _buildLoadedView(context, cubit, state),
          };
        },
      ),
    );
  }

  Widget _buildLoadedView(
    BuildContext context,
    CashboxCubit cubit,
    CashboxLoaded state,
  ) {
    final colors = context.colors;
    final summary = state.dailySummary;
    final transactions = state.filteredTransactions;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'دفتر حركة الخزينة النقدية',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    AppSpacing.verticalXs,
                    Text(
                      'سجل شامل لكافة التدفقات النقدية (وارد / صادر) والرصيد اللحظي للخزينة',
                      style: TextStyle(fontSize: 13, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              AppSpacing.horizontalMd,
              _buildCurrentBalanceCard(context, state.currentBalance),
            ],
          ),
          AppSpacing.verticalMd,

          // 2. Daily Summary KPI Cards
          Row(
            children: [
              Expanded(
                child: AppKpiCard(
                  title: 'وارد اليوم (+)',
                  value: summary.totalIn.formatArabic(),
                  icon: Icons.arrow_downward_rounded,
                  color: colors.success,
                ),
              ),
              AppSpacing.horizontalMd,
              Expanded(
                child: AppKpiCard(
                  title: 'صادر اليوم (-)',
                  value: summary.totalOut.formatArabic(),
                  icon: Icons.arrow_upward_rounded,
                  color: colors.danger,
                ),
              ),
              AppSpacing.horizontalMd,
              Expanded(
                child: AppKpiCard(
                  title: 'صافي حركة اليوم',
                  value: summary.netAmount.formatArabic(),
                  icon: Icons.account_balance_wallet_rounded,
                  color: summary.netAmount.piastres >= 0 ? colors.primary : colors.danger,
                ),
              ),
              AppSpacing.horizontalMd,
              Expanded(
                child: AppKpiCard(
                  title: 'حركات اليوم',
                  value: '${summary.transactionCount} حركة',
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xFF0284C7),
                ),
              ),
            ],
          ),
          AppSpacing.verticalMd,

          // 3. Filter Bar
          _buildFilterBar(context, cubit, state),
          AppSpacing.verticalMd,

          // 4. Transactions Data Table
          Expanded(
            child: transactions.isEmpty
                ? const EmptyView(
                    title: 'لا توجد حركات مسجلة بالخزينة',
                    subtitle: 'لم يتم العثور على أي حركات نقدية مطابقة لمعايير البحث الحالية',
                    icon: Icons.account_balance_wallet_outlined,
                  )
                : _buildTransactionsTable(context, transactions),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentBalanceCard(BuildContext context, Money balance) {
    final colors = context.colors;
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceElevated : colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: colors.primary.withValues(alpha: isDark ? 0.45 : 0.65),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: isDark ? 0.08 : 0.12),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_balance_wallet_rounded, size: 16, color: colors.primary),
              const SizedBox(width: 6),
              Text(
                'الرصيد الفعلي الحالي في الخزينة',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            balance.formatArabic(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    CashboxCubit cubit,
    CashboxLoaded state,
  ) {
    final colors = context.colors;
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          // Search Input
          Expanded(
            flex: 3,
            child: TextField(
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'بحث في البيان أو المبلغ أو نوع الحركة...',
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
              onChanged: (val) => cubit.setSearchQuery(val),
            ),
          ),
          AppSpacing.horizontalMd,

          // Direction Filters
          SegmentedButton<String?>(
            segments: const [
              ButtonSegment<String?>(value: null, label: Text('الكل')),
              ButtonSegment<String?>(value: 'in', label: Text('وارد (+)')),
              ButtonSegment<String?>(value: 'out', label: Text('صادر (-)')),
            ],
            selected: {state.directionFilter},
            onSelectionChanged: (set) => cubit.setDirectionFilter(set.first),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return colors.primary.withValues(alpha: 0.15);
                }
                return colors.surfaceElevated;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return colors.primary;
                }
                return colors.textPrimary;
              }),
              side: WidgetStateProperty.all(BorderSide(color: colors.border)),
            ),
          ),
          AppSpacing.horizontalMd,

          // Type Filter Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: colors.border),
            ),
            child: DropdownButton<String?>(
              value: state.typeFilter,
              hint: Text('نوع الحركة', style: TextStyle(color: colors.textSecondary)),
              dropdownColor: colors.surfaceElevated,
              style: TextStyle(color: colors.textPrimary, fontSize: 13),
              underline: const SizedBox(),
              items: [
                DropdownMenuItem(value: null, child: Text('كافة الأنواع', style: TextStyle(color: colors.textPrimary))),
                DropdownMenuItem(value: 'sale_cash_in', child: Text('مبيعات نقدية', style: TextStyle(color: colors.textPrimary))),
                DropdownMenuItem(value: 'customer_payment_in', child: Text('تحصيلات عملاء', style: TextStyle(color: colors.textPrimary))),
                DropdownMenuItem(value: 'purchase_cash_out', child: Text('مشتريات نقدية', style: TextStyle(color: colors.textPrimary))),
                DropdownMenuItem(value: 'supplier_payment_out', child: Text('سدادات موردين', style: TextStyle(color: colors.textPrimary))),
                DropdownMenuItem(value: 'expense_out', child: Text('مصروفات نقدية', style: TextStyle(color: colors.textPrimary))),
                DropdownMenuItem(value: 'opening_balance', child: Text('رصيد افتتاحي', style: TextStyle(color: colors.textPrimary))),
              ],
              onChanged: (val) => cubit.setTypeFilter(val),
            ),
          ),
          AppSpacing.horizontalMd,

          // Date Range Picker Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colors.border),
              foregroundColor: colors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
            icon: Icon(Icons.date_range_rounded, size: 18, color: colors.primary),
            label: Text(
              state.fromDate != null && state.toDate != null
                  ? '${dateFormat.format(state.fromDate!)} - ${dateFormat.format(state.toDate!)}'
                  : 'تحديد الفترة',
              style: TextStyle(fontSize: 12, color: colors.textPrimary),
            ),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2025),
                lastDate: DateTime(2030),
                initialDateRange: state.fromDate != null && state.toDate != null
                    ? DateTimeRange(start: state.fromDate!, end: state.toDate!)
                    : null,
              );
              if (picked != null) {
                cubit.setDateRange(
                  DateTime(picked.start.year, picked.start.month, picked.start.day, 0, 0, 0),
                  DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59, 999),
                );
              }
            },
          ),

          if (state.directionFilter != null ||
              state.typeFilter != null ||
              state.fromDate != null ||
              state.searchQuery.isNotEmpty) ...[
            AppSpacing.horizontalSm,
            IconButton(
              icon: Icon(Icons.clear_rounded, size: 20, color: colors.danger),
              tooltip: 'إلغاء الفلاتر',
              onPressed: () => cubit.resetFilters(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionsTable(
    BuildContext context,
    List<CashboxTransactionEntity> transactions,
  ) {
    final colors = context.colors;
    final dateFormat = DateFormat('yyyy/MM/dd  hh:mm a');

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 850),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    colors.surfaceElevated,
                  ),
                  headingTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    fontSize: 13,
                  ),
                  dataTextStyle: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                  ),
                  columns: const [
                    DataColumn(label: Text('المعرف')),
                    DataColumn(label: Text('التاريخ والوقت')),
                    DataColumn(label: Text('نوع الحركة')),
                    DataColumn(label: Text('البيان / الملاحظة')),
                    DataColumn(label: Text('وارد (+)')),
                    DataColumn(label: Text('صادر (-)')),
                    DataColumn(label: Text('الرصيد بعدها')),
                  ],
                  rows: transactions.map((tx) {
                    final isIn = tx.isIn;

                    return DataRow(
                      cells: [
                        DataCell(Text('#${tx.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'))),
                        DataCell(Text(dateFormat.format(tx.createdAt))),
                        DataCell(_buildTypeBadge(context, tx)),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 240),
                            child: Text(
                              tx.note ?? '—',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: tx.note != null ? colors.textPrimary : colors.textMuted),
                            ),
                          ),
                        ),
                        // In
                        DataCell(
                          Text(
                            isIn ? tx.amount.formatArabic() : '—',
                            style: TextStyle(
                              fontWeight: isIn ? FontWeight.bold : FontWeight.normal,
                              color: isIn ? colors.success : colors.textMuted,
                            ),
                          ),
                        ),
                        // Out
                        DataCell(
                          Text(
                            !isIn ? tx.amount.formatArabic() : '—',
                            style: TextStyle(
                              fontWeight: !isIn ? FontWeight.bold : FontWeight.normal,
                              color: !isIn ? colors.danger : colors.textMuted,
                            ),
                          ),
                        ),
                        // Balance After
                        DataCell(
                          Text(
                            tx.balanceAfter.formatArabic(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
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
    );
  }

  Widget _buildTypeBadge(BuildContext context, CashboxTransactionEntity tx) {
    final colors = context.colors;
    final color = tx.isIn ? colors.success : colors.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tx.isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            tx.transactionTypeArabic,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
