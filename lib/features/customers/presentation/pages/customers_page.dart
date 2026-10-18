import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/states/empty_view.dart';
import '../../../../core/widgets/states/error_view.dart';
import '../../../../core/widgets/states/loading_view.dart';
import '../../../../core/widgets/app_kpi_card.dart';
import '../../../customer_payments/presentation/cubit/customer_payments_cubit.dart';
import '../../../customer_payments/presentation/widgets/record_customer_payment_dialog.dart';
import '../../domain/entities/customer.dart';
import '../cubit/customers_cubit.dart';
import '../cubit/customers_state.dart';
import '../widgets/customer_form_dialog.dart';
import '../widgets/customer_ledger_dialog.dart';

class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CustomersCubit(
        watchCustomersUseCase: getIt(),
        addCustomerUseCase: getIt(),
        updateCustomerUseCase: getIt(),
        toggleCustomerStatusUseCase: getIt(),
      )..init(),
      child: const _CustomersView(),
    );
  }
}

class _CustomersView extends StatefulWidget {
  const _CustomersView();

  @override
  State<_CustomersView> createState() => _CustomersViewState();
}

class _CustomersViewState extends State<_CustomersView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CustomersCubit>();
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'العملاء والحسابات الجارية',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    AppSpacing.verticalXs,
                    Text(
                      'إدارة بيانات العملاء، ومتابعة المديونيات وكشوفات الحساب وسجلات السداد',
                      style: TextStyle(fontSize: 13, color: colors.textSecondary),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textPrimary,
                        side: BorderSide(color: colors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: Icon(Icons.payments_outlined, size: 20, color: colors.primary),
                      label: const Text('سندات التحصيل'),
                      onPressed: () => context.push('/payments/customers'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.person_add_rounded, size: 20),
                      label: const Text('تسجيل عميل جديد'),
                      onPressed: () => CustomerFormDialog.show(context, cubit),
                    ),
                  ],
                ),
              ],
            ),
            AppSpacing.verticalMd,

            // 2. Search & Filter Bar
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: BlocBuilder<CustomersCubit, CustomersState>(
                builder: (context, state) {
                  final isLoaded = state is CustomersLoaded;
                  final showDebtorsOnly = isLoaded ? state.showDebtorsOnly : false;
                  final showCreditorsOnly = isLoaded ? state.showCreditorsOnly : false;
                  final activeFilter = isLoaded ? state.activeFilter : true;

                  return Row(
                    children: [
                      // Search Field
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(color: colors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'البحث بالاسم، الهاتف، أو العنوان...',
                            hintStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
                            prefixIcon: Icon(Icons.search_rounded, color: colors.textSecondary),
                            filled: true,
                            fillColor: colors.surfaceElevated,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: colors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: colors.primary),
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear_rounded, size: 18, color: colors.textSecondary),
                                    onPressed: () {
                                      _searchController.clear();
                                      cubit.search('');
                                    },
                                  )
                                : null,
                            isDense: true,
                          ),
                          onChanged: (val) => cubit.search(val),
                        ),
                      ),
                      AppSpacing.horizontalMd,

                      // Status Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: Text(
                                'النشطون',
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
                              onSelected: (_) => cubit.setActiveFilter(true),
                            ),
                            AppSpacing.horizontalSm,
                            FilterChip(
                              label: Text(
                                'عليهم ديون',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: showDebtorsOnly ? colors.onPrimary : colors.textSecondary,
                                ),
                              ),
                              selected: showDebtorsOnly,
                              selectedColor: colors.warning,
                              backgroundColor: colors.surfaceElevated,
                              side: BorderSide(
                                color: showDebtorsOnly ? colors.warning : colors.border,
                              ),
                              onSelected: (_) => cubit.toggleDebtorsFilter(),
                            ),
                            AppSpacing.horizontalSm,
                            FilterChip(
                              label: Text(
                                'لهم أرصدة دائنة',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: showCreditorsOnly ? colors.onPrimary : colors.textSecondary,
                                ),
                              ),
                              selected: showCreditorsOnly,
                              selectedColor: colors.primary,
                              backgroundColor: colors.surfaceElevated,
                              side: BorderSide(
                                color: showCreditorsOnly ? colors.primary : colors.border,
                              ),
                              onSelected: (_) => cubit.toggleCreditorsFilter(),
                            ),
                            AppSpacing.horizontalSm,
                            ChoiceChip(
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
                              onSelected: (_) => cubit.setActiveFilter(null),
                            ),
                            AppSpacing.horizontalSm,
                            ChoiceChip(
                              label: Text(
                                'المعطلون',
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
                              onSelected: (_) => cubit.setActiveFilter(false),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            AppSpacing.verticalMd,

            // 3. Body Content (4 States)
            Expanded(
              child: BlocBuilder<CustomersCubit, CustomersState>(
                builder: (context, state) {
                  return switch (state) {
                    CustomersInitial() || CustomersLoading() => const LoadingView(),
                    CustomersError(message: final msg) => ErrorView(
                        message: msg,
                        onRetry: () => cubit.init(),
                      ),
                    CustomersEmpty(message: final msg, hasActiveFilters: final hasFilter) =>
                      EmptyView(
                        title: msg,
                        subtitle: hasFilter
                            ? 'لم يتم العثور على أي عملاء يطابقون خيارات البحث والفلترة'
                            : 'ابدأ بتسجيل أول عميل في النظام لمتابعة المبيعات والمديونيات',
                        icon: Icons.people_outline_rounded,
                        actionLabel: hasFilter ? 'إعادة تعيين الفلاتر' : 'إضافة عميل جديد',
                        onAction: hasFilter
                            ? () {
                                _searchController.clear();
                                cubit.search('');
                                cubit.setActiveFilter(true);
                                if (state.hasActiveFilters) {
                                  cubit.toggleDebtorsFilter();
                                }
                              }
                            : () => CustomerFormDialog.show(context, cubit),
                      ),
                    CustomersLoaded() => _buildLoadedView(context, cubit, state),
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
    CustomersCubit cubit,
    CustomersLoaded state,
  ) {
    final colors = context.colors;
    final filtered = state.filteredCustomers;

    if (filtered.isEmpty) {
      return EmptyView(
        title: 'لا توجد نتائج مطابقة للبحث أو الفلتر',
        subtitle: 'جرّب تعديل كلمات البحث أو إلغاء فلتر الديون والعملاء النشطين',
        icon: Icons.person_search_rounded,
        actionLabel: 'إعادة تعيين الفلاتر',
        onAction: () {
          _searchController.clear();
          cubit.search('');
          cubit.setActiveFilter(null);
          if (state.showDebtorsOnly) {
            cubit.toggleDebtorsFilter();
          }
        },
      );
    }

    return Column(
      children: [
        // KPI Cards Row
        Row(
          children: [
            Expanded(
              child: AppKpiCard(
                title: 'إجمالي العملاء المسجلين',
                value: '${state.customers.length}',
                icon: Icons.groups_rounded,
                color: colors.primary,
              ),
            ),
            AppSpacing.horizontalMd,
            Expanded(
              child: AppKpiCard(
                title: 'عملاء عليهم ديون مستحقة',
                value: '${state.totalDebtorsCount} عميل',
                icon: Icons.assignment_late_rounded,
                color: colors.warning,
              ),
            ),
            AppSpacing.horizontalMd,
            Expanded(
              child: AppKpiCard(
                title: 'إجمالي ديون العملاء',
                value: state.totalDebtAmount.formatArabic(),
                icon: Icons.account_balance_wallet_rounded,
                color: colors.danger,
              ),
            ),
            AppSpacing.horizontalMd,
            Expanded(
              child: AppKpiCard(
                title: 'أرصدة دائنة للعملاء (لهم طرفنا)',
                value: state.totalCreditAmount.formatArabic(),
                subtitle: state.totalCreditorsCount > 0 ? '${state.totalCreditorsCount} عميل دائن' : null,
                icon: Icons.account_balance_outlined,
                color: state.totalCreditAmount.piastres > 0 ? colors.primary : colors.textSecondary,
              ),
            ),
          ],
        ),
        AppSpacing.verticalMd,

        // Customers DataTable
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
                    DataColumn(label: Text('المعرف')),
                    DataColumn(label: Text('اسم العميل')),
                    DataColumn(label: Text('الهاتف')),
                    DataColumn(label: Text('العنوان')),
                    DataColumn(label: Text('الرصيد الحالي')),
                    DataColumn(label: Text('الحالة')),
                    DataColumn(label: Text('الإجراءات')),
                  ],
                  rows: filtered.map((c) => _buildCustomerRow(context, cubit, c)).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  DataRow _buildCustomerRow(
    BuildContext context,
    CustomersCubit cubit,
    Customer customer,
  ) {
    final colors = context.colors;
    return DataRow(
      cells: [
        DataCell(
          Text(
            '#${customer.id}',
            style: TextStyle(fontWeight: FontWeight.bold, color: colors.textSecondary, fontFamily: 'monospace'),
          ),
        ),
        DataCell(
          Text(
            customer.name,
            style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary),
          ),
        ),
        DataCell(
          Text(
            customer.phone ?? '—',
            style: TextStyle(fontFamily: 'monospace', color: colors.textPrimary),
          ),
        ),
        DataCell(
          Text(customer.address ?? '—', style: TextStyle(color: colors.textSecondary)),
        ),
        DataCell(
          _buildBalanceBadge(context, customer),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (customer.isActive ? colors.success : colors.textSecondary).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: (customer.isActive ? colors.success : colors.textSecondary).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              customer.isActive ? 'نشط' : 'معطل',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: customer.isActive ? colors.success : colors.textSecondary,
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.payments_outlined, size: 20, color: colors.success),
                tooltip: 'تسجيل سند تحصيل',
                onPressed: () => RecordCustomerPaymentDialog.show(
                  context,
                  getIt<CustomerPaymentsCubit>(),
                  preselectedCustomerId: customer.id,
                ),
              ),
              IconButton(
                icon: Icon(Icons.receipt_long_rounded, size: 20, color: colors.primary),
                tooltip: 'كشف الحساب',
                onPressed: () => CustomerLedgerDialog.show(context, customer),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 18, color: colors.primary),
                tooltip: AppStrings.edit,
                onPressed: () => CustomerFormDialog.show(context, cubit, customer),
              ),
              IconButton(
                icon: Icon(
                  customer.isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                  size: 24,
                  color: customer.isActive ? colors.success : colors.textSecondary,
                ),
                tooltip: customer.isActive ? 'إيقاف العميل' : 'تفعيل العميل',
                onPressed: () => cubit.toggleCustomerStatus(customer.id, !customer.isActive),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceBadge(BuildContext context, Customer customer) {
    final colors = context.colors;
    final balance = customer.currentBalance;
    final isDebt = customer.hasDebt;
    final isCredit = customer.isCreditor;

    final color = isDebt
        ? colors.danger
        : (isCredit ? colors.primary : colors.success);

    final title = isDebt
        ? 'مدين: ${balance.formatArabic()}'
        : (isCredit
            ? 'دائن: ${balance.abs().formatArabic()}'
            : 'خالص (0.00 ج.م)');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
