import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/states/empty_view.dart';
import '../../../../core/widgets/states/error_view.dart';
import '../../../../core/widgets/states/loading_view.dart';
import '../../../../core/widgets/app_kpi_card.dart';
import '../../domain/entities/expense.dart';
import '../cubit/expenses_cubit.dart';
import '../cubit/expenses_state.dart';
import '../widgets/record_expense_dialog.dart';

class ExpensesPage extends StatelessWidget {
  const ExpensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ExpensesCubit(
        watchExpenses: getIt(),
        recordExpense: getIt(),
      )..init(),
      child: const _ExpensesView(),
    );
  }
}

class _ExpensesView extends StatelessWidget {
  const _ExpensesView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ExpensesCubit>();
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: BlocBuilder<ExpensesCubit, ExpensesState>(
        builder: (context, state) {
          return switch (state) {
            ExpensesInitial() || ExpensesLoading() => const LoadingView(),
            ExpensesError(message: final msg) => ErrorView(
                message: msg,
                onRetry: () => cubit.init(),
              ),
            ExpensesLoaded() => _buildLoadedView(context, cubit, state),
          };
        },
      ),
    );
  }

  Widget _buildLoadedView(
    BuildContext context,
    ExpensesCubit cubit,
    ExpensesLoaded state,
  ) {
    final colors = context.colors;
    final filteredExpenses = state.filteredExpenses;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'دفتر المصروفات والنثريات',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    AppSpacing.verticalXs,
                    Text(
                      'تسجيل وتدقيق كافة المصروفات التشغيلية مع خصمها التلقائي من الخزينة',
                      style: TextStyle(fontSize: 13, color: colors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                label: const Text(
                  'تسجيل مصروف جديد',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => RecordExpenseDialog.show(context, cubit),
              ),
            ],
          ),
          AppSpacing.verticalMd,

          // 2. Metric KPI Cards
          Row(
            children: [
              Expanded(
                child: AppKpiCard(
                  title: 'إجمالي المصروفات المعروضة',
                  value: state.totalFilteredAmount.formatArabic(),
                  icon: Icons.receipt_long_rounded,
                  color: colors.danger,
                ),
              ),
              AppSpacing.horizontalMd,
              Expanded(
                child: AppKpiCard(
                  title: 'مصروفات اليوم',
                  value: state.todayTotalAmount.formatArabic(),
                  icon: Icons.today_rounded,
                  color: const Color(0xFFD97706),
                ),
              ),
              AppSpacing.horizontalMd,
              Expanded(
                child: AppKpiCard(
                  title: 'مصروفات الشهر الحالي',
                  value: state.thisMonthTotalAmount.formatArabic(),
                  icon: Icons.calendar_month_rounded,
                  color: const Color(0xFF7C3AED),
                ),
              ),
              AppSpacing.horizontalMd,
              Expanded(
                child: AppKpiCard(
                  title: 'عدد الحركات',
                  value: '${filteredExpenses.length} حركة',
                  icon: Icons.numbers_rounded,
                  color: const Color(0xFF0284C7),
                ),
              ),
            ],
          ),
          AppSpacing.verticalMd,

          // 3. Filter Bar
          _buildFilterBar(context, cubit, state),
          AppSpacing.verticalMd,

          // 4. Data Table
          Expanded(
            child: filteredExpenses.isEmpty
                ? const EmptyView(
                    title: 'لا توجد مصروفات مسجلة',
                    subtitle: 'لم يتم العثور على أي مصروفات تطابق معايير البحث المحددة',
                    icon: Icons.receipt_long_outlined,
                  )
                : _buildExpensesTable(context, filteredExpenses),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    ExpensesCubit cubit,
    ExpensesLoaded state,
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
          // Search field
          Expanded(
            flex: 3,
            child: TextField(
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'بحث في البند، البيان، أو المبلغ...',
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

          // Category Filter Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: colors.border),
            ),
            child: DropdownButton<String?>(
              value: state.categoryFilter,
              hint: Text('كافة البنود', style: TextStyle(color: colors.textSecondary)),
              dropdownColor: colors.surfaceElevated,
              style: TextStyle(color: colors.textPrimary, fontSize: 13),
              underline: const SizedBox(),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text('كافة البنود', style: TextStyle(color: colors.textPrimary)),
                ),
                ...state.allCategories.map(
                  (cat) => DropdownMenuItem(
                    value: cat,
                    child: Text(cat, style: TextStyle(color: colors.textPrimary)),
                  ),
                ),
              ],
              onChanged: (val) => cubit.setCategoryFilter(val),
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

          if (state.categoryFilter != null ||
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

  Widget _buildExpensesTable(
    BuildContext context,
    List<Expense> expenses,
  ) {
    final colors = context.colors;
    final dateFormat = DateFormat('yyyy/MM/dd');
    final timeFormat = DateFormat('hh:mm a');

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
                    DataColumn(label: Text('تاريخ المصروف')),
                    DataColumn(label: Text('بند المصروف')),
                    DataColumn(label: Text('البيان / التفاصيل')),
                    DataColumn(label: Text('المبلغ المصروف')),
                    DataColumn(label: Text('المستخدم')),
                    DataColumn(label: Text('وقت التسجيل')),
                  ],
                  rows: expenses.map((e) {
                    return DataRow(
                      cells: [
                        DataCell(Text('#${e.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'))),
                        DataCell(Text(dateFormat.format(e.expenseDate))),
                        DataCell(_buildCategoryBadge(context, e.category)),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 280),
                            child: Text(
                              e.note ?? '—',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: e.note != null ? colors.textPrimary : colors.textMuted),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '- ${e.amount.formatArabic()}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colors.danger,
                            ),
                          ),
                        ),
                        DataCell(Text(e.createdBy)),
                        DataCell(Text(timeFormat.format(e.createdAt), style: TextStyle(fontSize: 11, color: colors.textMuted))),
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

  Widget _buildCategoryBadge(BuildContext context, String category) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colors.primary,
        ),
      ),
    );
  }
}
