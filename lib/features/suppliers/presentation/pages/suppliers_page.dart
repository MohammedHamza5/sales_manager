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
import '../../../supplier_payments/presentation/cubit/supplier_payments_cubit.dart';
import '../../../supplier_payments/presentation/widgets/record_supplier_payment_dialog.dart';
import '../../domain/entities/supplier.dart';
import '../cubit/suppliers_cubit.dart';
import '../cubit/suppliers_state.dart';
import '../widgets/supplier_form_dialog.dart';
import '../widgets/supplier_ledger_dialog.dart';

class SuppliersPage extends StatelessWidget {
  const SuppliersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SuppliersCubit(
        watchSuppliersUseCase: getIt(),
        addSupplierUseCase: getIt(),
        updateSupplierUseCase: getIt(),
        toggleSupplierStatusUseCase: getIt(),
      )..init(),
      child: const _SuppliersView(),
    );
  }
}

class _SuppliersView extends StatefulWidget {
  const _SuppliersView();

  @override
  State<_SuppliersView> createState() => _SuppliersViewState();
}

class _SuppliersViewState extends State<_SuppliersView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SuppliersCubit>();
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
                      'الموردون والحسابات الجارية',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    AppSpacing.verticalXs,
                    Text(
                      'إدارة بيانات الموردين، ومتابعة فواتير الشراء والأرصدة المستحقة وكشوفات الحساب',
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
                      label: const Text('سندات السداد'),
                      onPressed: () => context.push('/payments/suppliers'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.local_shipping_rounded, size: 20),
                      label: const Text('تسجيل مورد جديد'),
                      onPressed: () => SupplierFormDialog.show(context, cubit),
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
              child: BlocBuilder<SuppliersCubit, SuppliersState>(
                builder: (context, state) {
                  final isLoaded = state is SuppliersLoaded;
                  final showDueOnly = isLoaded ? state.showDueOnly : false;
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
                              key: const ValueKey('chip_active'),
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
                              key: const ValueKey('chip_due'),
                              label: Text(
                                'مستحق لهم ديون فقط',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: showDueOnly ? colors.onPrimary : colors.textSecondary,
                                ),
                              ),
                              selected: showDueOnly,
                              selectedColor: colors.warning,
                              backgroundColor: colors.surfaceElevated,
                              side: BorderSide(
                                color: showDueOnly ? colors.warning : colors.border,
                              ),
                              onSelected: (_) => cubit.toggleDueFilter(),
                            ),
                            AppSpacing.horizontalSm,
                            ChoiceChip(
                              key: const ValueKey('chip_all'),
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
                              key: const ValueKey('chip_inactive'),
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
              child: BlocBuilder<SuppliersCubit, SuppliersState>(
                builder: (context, state) {
                  return switch (state) {
                    SuppliersInitial() || SuppliersLoading() => const LoadingView(),
                    SuppliersError(message: final msg) => ErrorView(
                        message: msg,
                        onRetry: () => cubit.init(),
                      ),
                    SuppliersEmpty(message: final msg, hasActiveFilters: final hasFilter) =>
                      EmptyView(
                        title: msg,
                        subtitle: hasFilter
                            ? 'لم يتم العثور على أي موردين يطابقون خيارات البحث والفلترة'
                            : 'ابدأ بتسجيل أول مورد في النظام لمتابعة المشتريات والمدفوعات',
                        icon: Icons.local_shipping_outlined,
                        actionLabel: hasFilter ? 'إعادة تعيين الفلاتر' : 'إضافة مورد جديد',
                        onAction: hasFilter
                            ? () {
                                _searchController.clear();
                                cubit.search('');
                                cubit.setActiveFilter(true);
                                if (state.hasActiveFilters) {
                                  cubit.toggleDueFilter();
                                }
                              }
                            : () => SupplierFormDialog.show(context, cubit),
                      ),
                    SuppliersLoaded() => _buildLoadedView(context, cubit, state),
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
    SuppliersCubit cubit,
    SuppliersLoaded state,
  ) {
    final colors = context.colors;
    final filtered = state.filteredSuppliers;

    if (filtered.isEmpty) {
      return EmptyView(
        title: 'لا توجد نتائج مطابقة للبحث أو الفلتر',
        subtitle: 'جرّب تعديل كلمات البحث أو إلغاء فلتر الديون والموردين النشطين',
        icon: Icons.person_search_rounded,
        actionLabel: 'إعادة تعيين الفلاتر',
        onAction: () {
          _searchController.clear();
          cubit.search('');
          cubit.setActiveFilter(null);
          if (state.showDueOnly) {
            cubit.toggleDueFilter();
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
                title: 'إجمالي الموردين المسجلين',
                value: '${state.suppliers.length}',
                icon: Icons.store_rounded,
                color: colors.primary,
              ),
            ),
            AppSpacing.horizontalMd,
            Expanded(
              child: AppKpiCard(
                title: 'موردون مستحق لهم مبالغ',
                value: '${state.totalDueSuppliersCount} مورد',
                icon: Icons.assignment_late_rounded,
                color: colors.warning,
              ),
            ),
            AppSpacing.horizontalMd,
            Expanded(
              child: AppKpiCard(
                title: 'إجمالي المبالغ المستحقة للموردين',
                value: state.totalDueAmount.formatArabic(),
                icon: Icons.account_balance_wallet_rounded,
                color: colors.danger,
              ),
            ),
          ],
        ),
        AppSpacing.verticalMd,

        // Suppliers DataTable
        Expanded(
          child: Card(
            color: colors.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              side: BorderSide(color: colors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(colors.surfaceElevated),
                    columns: [
                      DataColumn(label: Text('المعرف', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary))),
                      DataColumn(label: Text('اسم المورد', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary))),
                      DataColumn(label: Text('الهاتف', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary))),
                      DataColumn(label: Text('العنوان', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary))),
                      DataColumn(label: Text('الرصيد الحالي', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary))),
                      DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary))),
                      DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary))),
                    ],
                    rows: filtered.map((s) => _buildSupplierRow(context, cubit, s)).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  DataRow _buildSupplierRow(
    BuildContext context,
    SuppliersCubit cubit,
    Supplier supplier,
  ) {
    final colors = context.colors;
    return DataRow(
      cells: [
        DataCell(
          Text(
            '#${supplier.id}',
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', color: colors.textSecondary),
          ),
        ),
        DataCell(
          Text(
            supplier.name,
            style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary),
          ),
        ),
        DataCell(
          Text(
            supplier.phone ?? '—',
            style: TextStyle(fontFamily: 'monospace', color: colors.textSecondary),
          ),
        ),
        DataCell(
          Text(
            supplier.address ?? '—',
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
        DataCell(
          _buildBalanceBadge(context, supplier),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (supplier.isActive ? colors.success : colors.textSecondary).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                color: (supplier.isActive ? colors.success : colors.textSecondary).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              supplier.isActive ? 'نشط' : 'معطل',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: supplier.isActive ? colors.success : colors.textSecondary,
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.payments_outlined, size: 20, color: colors.warning),
                tooltip: 'تسجيل سند سداد',
                onPressed: () => RecordSupplierPaymentDialog.show(
                  context,
                  getIt<SupplierPaymentsCubit>(),
                  preselectedSupplierId: supplier.id,
                ),
              ),
              IconButton(
                icon: Icon(Icons.receipt_long_rounded, size: 20, color: colors.info),
                tooltip: 'كشف الحساب',
                onPressed: () => SupplierLedgerDialog.show(context, supplier),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 18, color: colors.primary),
                tooltip: AppStrings.edit,
                onPressed: () => SupplierFormDialog.show(context, cubit, supplier),
              ),
              IconButton(
                icon: Icon(
                  supplier.isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                  size: 24,
                  color: supplier.isActive ? colors.success : colors.textSecondary,
                ),
                tooltip: supplier.isActive ? 'إيقاف المورد' : 'تفعيل المورد',
                onPressed: () => cubit.toggleSupplierStatus(supplier.id, !supplier.isActive),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceBadge(BuildContext context, Supplier supplier) {
    final colors = context.colors;
    final balance = supplier.currentBalance;
    final isDue = supplier.hasBalanceDue;
    final isDebtor = supplier.isDebtorToUs;

    final color = isDue
        ? colors.danger
        : (isDebtor ? colors.info : colors.success);

    final title = isDue
        ? 'مستحق له: ${balance.formatArabic()}'
        : (isDebtor
            ? 'مدين لنا: ${balance.abs().formatArabic()}'
            : 'خالص (0.00 ج.م)');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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

