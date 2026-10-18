import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/states/empty_view.dart';
import '../../../../core/widgets/states/error_view.dart';
import '../../../../core/widgets/states/loading_view.dart';
import '../../../../core/widgets/app_kpi_card.dart';
import '../cubit/returns_cubit.dart';
import '../cubit/returns_state.dart';
import '../widgets/customer_return_dialog.dart';
import '../widgets/supplier_return_dialog.dart';

class ReturnsPage extends StatelessWidget {
  const ReturnsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReturnsCubit(
        watchCustomerReturns: getIt(),
        watchSupplierReturns: getIt(),
        createCustomerReturn: getIt(),
        createSupplierReturn: getIt(),
      )..init(),
      child: const _ReturnsView(),
    );
  }
}

class _ReturnsView extends StatefulWidget {
  const _ReturnsView();

  @override
  State<_ReturnsView> createState() => _ReturnsViewState();
}

class _ReturnsViewState extends State<_ReturnsView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReturnsCubit>();
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
                      AppStrings.returns,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    AppSpacing.verticalXs,
                    Text(
                      'إدارة مرتجعات العملاء وإرجاع البضائع للموردين',
                      style: TextStyle(fontSize: 13, color: colors.textSecondary),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => CustomerReturnDialog.show(context, cubit),
                      icon: const Icon(Icons.person_remove_outlined, size: 18),
                      label: const Text(AppStrings.newCustomerReturn),
                    ),
                    AppSpacing.horizontalMd,
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textPrimary,
                        side: BorderSide(color: colors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => SupplierReturnDialog.show(context, cubit),
                      icon: Icon(Icons.business_outlined, size: 18, color: colors.primary),
                      label: const Text(AppStrings.newSupplierReturn),
                    ),
                  ],
                ),
              ],
            ),
            AppSpacing.verticalMd,

            // Content
            Expanded(
              child: BlocBuilder<ReturnsCubit, ReturnsState>(
                builder: (context, state) {
                  return switch (state) {
                    ReturnsInitial() || ReturnsLoading() =>
                      const LoadingView(message: 'جاري تحميل المرتجعات...'),
                    ReturnsError(message: final msg) => ErrorView(
                        message: msg,
                        onRetry: () => cubit.init(),
                      ),
                    ReturnsLoaded() => _buildLoadedView(context, state, cubit),
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
    ReturnsLoaded state,
    ReturnsCubit cubit,
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
                title: 'إجمالي مرتجعات العملاء',
                value: state.totalCustomerReturnsAmount.formatArabic(),
                subtitle: '${state.customerReturns.length} إذن مرتجع',
                subtitleColor: colors.textSecondary,
                icon: Icons.person_remove_outlined,
                color: colors.primary,
              ),
            ),
            AppSpacing.horizontalMd,
            Expanded(
              child: AppKpiCard(
                title: 'إجمالي مرتجعات الموردين',
                value: state.totalSupplierReturnsAmount.formatArabic(),
                subtitle: '${state.supplierReturns.length} إذن مرتجع',
                subtitleColor: colors.textSecondary,
                icon: Icons.business_outlined,
                color: colors.accent,
              ),
            ),
          ],
        ),
        AppSpacing.verticalMd,

        // Tab Selector & Search Bar
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
          child: Row(
            children: [
              ChoiceChip(
                label: Text(
                  'مرتجعات العملاء (${state.customerReturns.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: state.selectedTabIndex == 0 ? colors.onPrimary : colors.textSecondary,
                  ),
                ),
                selected: state.selectedTabIndex == 0,
                selectedColor: colors.primary,
                backgroundColor: colors.surfaceElevated,
                side: BorderSide(
                  color: state.selectedTabIndex == 0 ? colors.primary : colors.border,
                ),
                onSelected: (_) => cubit.setTab(0),
              ),
              AppSpacing.horizontalSm,
              ChoiceChip(
                label: Text(
                  'مرتجعات الموردين (${state.supplierReturns.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: state.selectedTabIndex == 1 ? colors.onPrimary : colors.textSecondary,
                  ),
                ),
                selected: state.selectedTabIndex == 1,
                selectedColor: colors.primary,
                backgroundColor: colors.surfaceElevated,
                side: BorderSide(
                  color: state.selectedTabIndex == 1 ? colors.primary : colors.border,
                ),
                onSelected: (_) => cubit.setTab(1),
              ),
              const Spacer(),
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'ابحث بالاسم، رقم المرتجع...',
                    hintStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
                    prefixIcon: Icon(Icons.search, size: 20, color: colors.textSecondary),
                    filled: true,
                    fillColor: colors.surfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  onChanged: (val) => cubit.search(val),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.verticalMd,

        // Table
        Expanded(
          child: state.selectedTabIndex == 0
              ? _buildCustomerReturnsTable(context, state)
              : _buildSupplierReturnsTable(context, state),
        ),
      ],
    );
  }

  Widget _buildCustomerReturnsTable(BuildContext context, ReturnsLoaded state) {
    final colors = context.colors;
    final list = state.filteredCustomerReturns;

    if (list.isEmpty) {
      return const EmptyView(
        title: 'لا توجد مرتجعات عملاء مسجلة',
        icon: Icons.assignment_return_outlined,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(colors.surfaceElevated),
            dataRowColor: WidgetStateProperty.all(colors.surface),
            headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
            columns: const [
              DataColumn(label: Text('رقم المرتجع')),
              DataColumn(label: Text('التاريخ')),
              DataColumn(label: Text('العميل')),
              DataColumn(label: Text('الفاتورة الأصلية')),
              DataColumn(label: Text('إجمالي المرتجع')),
              DataColumn(label: Text('ملاحظات')),
            ],
            rows: list.map((ret) {
              return DataRow(
                cells: [
                  DataCell(Text('#${ret.id}', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary))),
                  DataCell(Text(DateFormat('yyyy/MM/dd').format(ret.returnDate), style: TextStyle(color: colors.textSecondary))),
                  DataCell(Text(ret.customerName, style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary))),
                  DataCell(Text(ret.originalInvoiceNo != null ? '#${ret.originalInvoiceNo}' : '-', style: TextStyle(color: colors.textSecondary))),
                  DataCell(Text(ret.totalAmount.formatArabic(), style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary))),
                  DataCell(Text(ret.note ?? '-', style: TextStyle(color: colors.textSecondary))),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSupplierReturnsTable(BuildContext context, ReturnsLoaded state) {
    final colors = context.colors;
    final list = state.filteredSupplierReturns;

    if (list.isEmpty) {
      return const EmptyView(
        title: 'لا توجد مرتجعات موردين مسجلة',
        icon: Icons.assignment_return_outlined,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(colors.surfaceElevated),
            dataRowColor: WidgetStateProperty.all(colors.surface),
            headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
            columns: const [
              DataColumn(label: Text('رقم المرتجع')),
              DataColumn(label: Text('التاريخ')),
              DataColumn(label: Text('المورد')),
              DataColumn(label: Text('الفاتورة الأصلية')),
              DataColumn(label: Text('إجمالي المرتجع')),
              DataColumn(label: Text('ملاحظات')),
            ],
            rows: list.map((ret) {
              return DataRow(
                cells: [
                  DataCell(Text('#${ret.id}', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary))),
                  DataCell(Text(DateFormat('yyyy/MM/dd').format(ret.returnDate), style: TextStyle(color: colors.textSecondary))),
                  DataCell(Text(ret.supplierName, style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary))),
                  DataCell(Text(ret.originalInvoiceNo != null ? '#${ret.originalInvoiceNo}' : '-', style: TextStyle(color: colors.textSecondary))),
                  DataCell(Text(ret.totalAmount.formatArabic(), style: TextStyle(fontWeight: FontWeight.bold, color: colors.accent))),
                  DataCell(Text(ret.note ?? '-', style: TextStyle(color: colors.textSecondary))),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
