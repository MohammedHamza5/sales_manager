import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/money/money.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_kpi_card.dart';
import '../../../../core/widgets/states/empty_view.dart';
import '../../../../core/widgets/states/error_view.dart';
import '../../../../core/widgets/states/loading_view.dart';
import '../cubit/opening_balance_cubit.dart';
import '../cubit/opening_balance_state.dart';
import '../widgets/product_balance_row.dart';
import '../widgets/stakeholder_balance_row.dart';

class OpeningBalancePage extends StatelessWidget {
  const OpeningBalancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OpeningBalanceCubit(
        checkStatusUseCase: getIt(),
        saveOpeningBalancesUseCase: getIt(),
        getProductsUseCase: getIt(),
        getCustomersUseCase: getIt(),
        getSuppliersUseCase: getIt(),
      )..init(),
      child: const _OpeningBalanceView(),
    );
  }
}

class _OpeningBalanceView extends StatelessWidget {
  const _OpeningBalanceView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OpeningBalanceCubit>();
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: BlocConsumer<OpeningBalanceCubit, OpeningBalanceState>(
        listener: (context, state) {
          if (state is OpeningBalanceSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: colors.success,
                behavior: SnackBarBehavior.floating,
                width: 500,
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white),
                    AppSpacing.horizontalSm,
                    Expanded(child: Text(state.message)),
                  ],
                ),
              ),
            );
          } else if (state is OpeningBalanceReady && state.submitError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: colors.danger,
                behavior: SnackBarBehavior.floating,
                width: 500,
                content: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.white),
                    AppSpacing.horizontalSm,
                    Expanded(child: Text(state.submitError!)),
                  ],
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          return switch (state) {
            OpeningBalanceInitial() || OpeningBalanceLoading() => const LoadingView(),
            OpeningBalanceAlreadySaved(message: final msg) => _buildAlreadySavedView(context, msg),
            OpeningBalanceSuccess(message: final msg) => _buildSuccessView(context, msg),
            OpeningBalanceError(message: final msg) => ErrorView(
                message: msg,
                onRetry: () => cubit.init(),
              ),
            OpeningBalanceReady() => _buildReadyView(context, cubit, state),
          };
        },
      ),
    );
  }

  Widget _buildAlreadySavedView(BuildContext context, String message) {
    final colors = context.colors;
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colors.success.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_clock_rounded,
                    color: colors.success,
                    size: 48,
                  ),
                ),
                AppSpacing.verticalLg,
                Text(
                  'الأرصدة الافتتاحية مثبتة ومحمية',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                AppSpacing.verticalSm,
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: colors.textSecondary, height: 1.5),
                ),
                AppSpacing.verticalLg,
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.dashboard_rounded),
                  label: const Text('الانتقال إلى لوحة التحكم الرئيسية'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, String message) {
    final colors = context.colors;
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colors.success.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: colors.success,
                    size: 48,
                  ),
                ),
                AppSpacing.verticalLg,
                Text(
                  'اكتمل تثبيت الأرصدة بنجاح!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                AppSpacing.verticalSm,
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: colors.textSecondary),
                ),
                AppSpacing.verticalLg,
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('بدء العمل في النظام'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadyView(
    BuildContext context,
    OpeningBalanceCubit cubit,
    OpeningBalanceReady state,
  ) {
    final input = state.input;
    final colors = context.colors;

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
                      'الأرصدة الافتتاحية لنقطة الصفر',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    AppSpacing.verticalXs,
                    Text(
                      'تسجيل أرصدة البداية للخزينة النقدية، المخزون، ذمم العملاء، ومستحقات الموردين مرة واحدة فقط',
                      style: TextStyle(fontSize: 13, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              AppSpacing.horizontalMd,
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                onPressed: state.isSubmitting
                    ? null
                    : () => _confirmSave(context, cubit),
                icon: state.isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 20),
                label: Text(
                  state.isSubmitting ? 'جارٍ الحفظ الذري...' : 'حفظ وتثبيت الأرصدة نهائياً',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          AppSpacing.verticalMd,

          // 2. Summary Metric Cards
          Row(
            children: [
              Expanded(
                child: AppKpiCard(
                  title: 'نقدية الخزينة الافتتاحية',
                  value: input.cashboxBalance.formatArabic(),
                  icon: Icons.account_balance_wallet_rounded,
                  color: colors.primary,
                ),
              ),
              AppSpacing.horizontalMd,
              Expanded(
                child: AppKpiCard(
                  title: 'أصناف المخزون المُدخلة',
                  value: '${input.products.where((p) => p.initialQuantity > Decimal.zero).length} صنف (${input.totalProductsQuantity} قطعة)',
                  icon: Icons.inventory_2_rounded,
                  color: colors.info,
                ),
              ),
              AppSpacing.horizontalMd,
              Expanded(
                child: AppKpiCard(
                  title: 'إجمالي ديون العملاء',
                  value: input.totalCustomerDebt.formatArabic(),
                  icon: Icons.people_alt_rounded,
                  color: colors.warning,
                ),
              ),
              AppSpacing.horizontalMd,
              Expanded(
                child: AppKpiCard(
                  title: 'إجمالي مستحقات الموردين',
                  value: input.totalSupplierDue.formatArabic(),
                  icon: Icons.local_shipping_rounded,
                  color: colors.danger,
                ),
              ),
            ],
          ),
          AppSpacing.verticalMd,

          // 3. Section Tabs Bar
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  _buildTabButton(
                    context: context,
                    cubit: cubit,
                    index: 0,
                    currentIndex: state.activeTabIndex,
                    label: 'رصيد الخزينة',
                    icon: Icons.point_of_sale_rounded,
                  ),
                  _buildTabButton(
                    context: context,
                    cubit: cubit,
                    index: 1,
                    currentIndex: state.activeTabIndex,
                    label: 'مخزون المنتجات (${input.products.length})',
                    icon: Icons.warehouse_rounded,
                  ),
                  _buildTabButton(
                    context: context,
                    cubit: cubit,
                    index: 2,
                    currentIndex: state.activeTabIndex,
                    label: 'ذمم العملاء (${input.customers.length})',
                    icon: Icons.people_alt_rounded,
                  ),
                  _buildTabButton(
                    context: context,
                    cubit: cubit,
                    index: 3,
                    currentIndex: state.activeTabIndex,
                    label: 'مستحقات الموردين (${input.suppliers.length})',
                    icon: Icons.local_shipping_rounded,
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.verticalMd,

          // 4. Tab Content Body
          Expanded(
            child: IndexedStack(
              index: state.activeTabIndex,
              children: [
                _buildCashboxTab(context, cubit, state),
                _buildProductsTab(context, cubit, state),
                _buildCustomersTab(context, cubit, state),
                _buildSuppliersTab(context, cubit, state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required BuildContext context,
    required OpeningBalanceCubit cubit,
    required int index,
    required int currentIndex,
    required String label,
    required IconData icon,
  }) {
    final colors = context.colors;
    final isSelected = index == currentIndex;

    return Expanded(
      child: TextButton.icon(
        style: TextButton.styleFrom(
          backgroundColor: isSelected ? colors.primaryLight : Colors.transparent,
          foregroundColor: isSelected ? colors.primary : colors.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
        onPressed: () => cubit.setTab(index),
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCashboxTab(
    BuildContext context,
    OpeningBalanceCubit cubit,
    OpeningBalanceReady state,
  ) {
    final colors = context.colors;
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.primaryLight,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Icon(Icons.point_of_sale_rounded, color: colors.primary, size: 28),
                    ),
                    AppSpacing.horizontalMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'رصيد الخزينة الافتتاحي',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
                          ),
                          Text(
                            'السيولة النقدية المتواجدة حالياً في درج الكاشير/الخزينة بالجنيه',
                            style: TextStyle(fontSize: 12, color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalLg,
                TextFormField(
                  key: const ValueKey('cashbox_input'),
                  initialValue: state.input.cashboxBalance.piastres > 0
                      ? state.input.cashboxBalance.formatArabic(showCurrency: false)
                      : '',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'مبلغ النقدية بالجنيه *',
                    hintText: '0.00',
                    suffixText: 'ج.م',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    helperText: 'سيتم تسجيل هذا المبلغ كحركة رصيد افتتاحي في حركة الخزينة',
                  ),
                  onChanged: (val) {
                    final parsed = Money.tryParse(val.trim()) ?? Money.zero;
                    cubit.setCashboxBalance(parsed);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductsTab(
    BuildContext context,
    OpeningBalanceCubit cubit,
    OpeningBalanceReady state,
  ) {
    final colors = context.colors;
    final products = state.input.products;

    if (products.isEmpty) {
      return const EmptyView(
        title: 'لا توجد منتجات مسجلة بالنظام بعد',
        subtitle: 'يرجى تسجيل المنتجات أولاً من شاشة المنتجات قبل إدخال أرصدة المخزون',
        icon: Icons.inventory_2_outlined,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                colors.surfaceElevated,
              ),
              columns: const [
                DataColumn(label: Text('المعرف', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('اسم المنتج', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('الباركود / SKU', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('الوحدة', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('الكمية المتوفرة', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: products.map((p) {
                return ProductBalanceRow.build(
                  context: context,
                  product: p,
                  onQuantityChanged: (qty) => cubit.updateProductQuantity(p.productId, qty),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomersTab(
    BuildContext context,
    OpeningBalanceCubit cubit,
    OpeningBalanceReady state,
  ) {
    final colors = context.colors;
    final customers = state.input.customers;

    if (customers.isEmpty) {
      return const EmptyView(
        title: 'لا يوجد عملاء مسجلون بالنظام بعد',
        subtitle: 'إذا كان هناك عملاء عليهم ديون سابقة، سجلهم أولاً من شاشة العملاء',
        icon: Icons.people_outline_rounded,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                colors.surfaceElevated,
              ),
              columns: const [
                DataColumn(label: Text('المعرف', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('اسم العميل', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('الهاتف', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('الرصيد المدين المستحق عليه', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: customers.map((c) {
                return StakeholderBalanceRow.build(
                  context: context,
                  stakeholder: c,
                  hintText: '0.00',
                  onBalanceChanged: (bal) => cubit.updateCustomerBalance(c.stakeholderId, bal),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuppliersTab(
    BuildContext context,
    OpeningBalanceCubit cubit,
    OpeningBalanceReady state,
  ) {
    final colors = context.colors;
    final suppliers = state.input.suppliers;

    if (suppliers.isEmpty) {
      return const EmptyView(
        title: 'لا يوجد موردون مسجلون بالنظام بعد',
        subtitle: 'إذا كان هناك موردون مستحق لهم مبالغ سابقة، سجلهم أولاً من شاشة الموردين',
        icon: Icons.local_shipping_outlined,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                colors.surfaceElevated,
              ),
              columns: const [
                DataColumn(label: Text('المعرف', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('اسم المورد', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('الهاتف', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('المبلغ المستحق له علينا', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: suppliers.map((s) {
                return StakeholderBalanceRow.build(
                  context: context,
                  stakeholder: s,
                  hintText: '0.00',
                  onBalanceChanged: (bal) => cubit.updateSupplierBalance(s.stakeholderId, bal),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSave(BuildContext context, OpeningBalanceCubit cubit) async {
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colors.warning, size: 28),
            AppSpacing.horizontalSm,
            Expanded(child: Text('تأكيد حفظ وتثبيت الأرصدة', style: TextStyle(color: colors.textPrimary))),
          ],
        ),
        content: Text(
          'تنبيه: سيتم حفظ الأرصدة الافتتاحية في الخزينة والمخزون وحسابات العملاء والموردين نهائياً، ولن يمكن تعديل نقطة الصفر هذه بعد الحفظ. هل أنت متأكد من صحة كافة الأرقام المدخلة؟',
          style: TextStyle(fontSize: 14, height: 1.5, color: colors.textSecondary),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.check_rounded),
            label: const Text('نعم، احفظ وثبّت الأرصدة'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await cubit.submit();
    }
  }
}
