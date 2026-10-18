import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/states/error_view.dart';
import '../../../../core/widgets/states/loading_view.dart';
import '../../domain/entities/dashboard_data.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import '../widgets/stat_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<DashboardCubit>()..init(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  // Retains privacy toggle state across page visits in the current session
  static bool _hideAmounts = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          return switch (state) {
            DashboardInitial() || DashboardLoading() =>
              const LoadingView(message: 'جاري تحميل لوحة التحكم...'),
            DashboardError(message: final msg) => ErrorView(
                message: msg,
                onRetry: () => context.read<DashboardCubit>().refresh(),
              ),
            DashboardLoaded(data: final data) => _buildDashboardContent(context, data),
          };
        },
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, DashboardData data) {
    final colors = context.colors;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Wrap
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.dashboard,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'متابعة حية وفورية للمبيعات، الخزينة، الأرصدة، ونواقص المخزون',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Privacy eye button to hide/show sensitive figures
                  IconButton(
                    icon: Icon(
                      _hideAmounts ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      size: 20,
                    ),
                    tooltip: _hideAmounts ? 'إظهار الأرقام المالية' : 'إخفاء الأرقام المالية الحساسة',
                    color: _hideAmounts ? colors.primary : colors.textSecondary,
                    style: IconButton.styleFrom(
                      backgroundColor: _hideAmounts ? colors.primary.withValues(alpha: 0.15) : null,
                    ),
                    onPressed: () {
                      setState(() {
                        _hideAmounts = !_hideAmounts;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'تحديث البيانات',
                    color: colors.textSecondary,
                    onPressed: () => context.read<DashboardCubit>().refresh(),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/expenses'),
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: const Text('تسجيل مصروف'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/sales/create'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(AppStrings.newSale),
                  ),
                ],
              ),
            ],
          ),
          AppSpacing.verticalLg,

          // Primary KPIs Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1100
                  ? 4
                  : constraints.maxWidth > 750
                      ? 2
                      : 1;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.30,
                children: [
                  StatCard(
                    title: 'رصيد الخزينة الحالي',
                    value: data.cashboxBalance.formatted,
                    icon: Icons.account_balance_wallet_rounded,
                    color: colors.primary,
                    subtitle: 'النقدية الحالية بالدرج',
                    isHidden: _hideAmounts,
                    onTap: () => context.push('/cashbox'),
                  ),
                  StatCard(
                    title: 'مبيعات اليوم',
                    value: data.dailyStats.todaySales.formatted,
                    subtitle: '${data.dailyStats.todaySalesCount} فاتورة بيع اليوم',
                    icon: Icons.shopping_cart_rounded,
                    color: colors.success,
                    badge: data.dailyStats.todaySalesCount > 0
                        ? '${data.dailyStats.todaySalesCount} فواتير'
                        : null,
                    isHidden: _hideAmounts,
                    onTap: () => context.push('/sales'),
                  ),
                  StatCard(
                    title: 'تحصيلات اليوم',
                    value: data.dailyStats.todayCollections.formatted,
                    icon: Icons.payments_rounded,
                    color: colors.info,
                    subtitle: 'مقبوضات نقدية مسجلة اليوم',
                    isHidden: _hideAmounts,
                    onTap: () => context.push('/payments/customers'),
                  ),
                  StatCard(
                    title: 'مصروفات اليوم',
                    value: data.dailyStats.todayExpenses.formatted,
                    icon: Icons.receipt_long_rounded,
                    color: colors.danger,
                    subtitle: 'مصروفات تشغيلية ونثرية',
                    isHidden: _hideAmounts,
                    onTap: () => context.push('/expenses'),
                  ),
                ],
              );
            },
          ),
          AppSpacing.verticalMd,

          // Secondary Financial Cards (Debts & Purchases)
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1100
                  ? 4
                  : constraints.maxWidth > 750
                      ? 2
                      : 1;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.35,
                children: [
                  StatCard(
                    title: 'إجمالي ديون العملاء',
                    value: data.totalCustomerDebt.formatted,
                    subtitle: 'مستحقات على العملاء طرف المؤسسة',
                    icon: Icons.people_alt_outlined,
                    color: colors.warning,
                    isHidden: _hideAmounts,
                    onTap: () => context.push('/customers'),
                  ),
                  StatCard(
                    title: 'أرصدة دائنة للعملاء',
                    value: data.totalCustomerCredit.formatted,
                    subtitle: 'مستحقات للعملاء طرفنا (أمانات/مرتجعات)',
                    icon: Icons.account_balance_outlined,
                    color: data.totalCustomerCredit.piastres > 0 ? colors.primary : colors.textSecondary,
                    badge: data.totalCustomerCredit.piastres > 0 ? 'مستحق للعملاء' : null,
                    isHidden: _hideAmounts,
                    onTap: () => context.push('/customers'),
                  ),
                  StatCard(
                    title: 'إجمالي مستحقات الموردين',
                    value: data.totalSupplierPayables.formatted,
                    subtitle: 'ديون والتزامات للموردين',
                    icon: Icons.local_shipping_outlined,
                    color: Colors.deepOrangeAccent,
                    isHidden: _hideAmounts,
                    onTap: () => context.push('/suppliers'),
                  ),
                  StatCard(
                    title: 'مشتريات اليوم',
                    value: data.dailyStats.todayPurchases.formatted,
                    subtitle: data.dailyStats.todayReturnsCount > 0
                        ? 'مرتجعات مبيعات: ${_hideAmounts ? "••••••" : data.dailyStats.todayReturns.formatted}'
                        : 'إجمالي التوريدات والفواتير اليوم',
                    icon: Icons.shopping_bag_outlined,
                    color: Colors.teal,
                    isHidden: _hideAmounts,
                    onTap: () => context.push('/purchases'),
                  ),
                ],
              );
            },
          ),
          AppSpacing.verticalLg,

          // Two-column section: Low Stock Alerts & Recent Activities
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Low stock alert box
              Expanded(
                flex: 5,
                child: _buildLowStockCard(context, data),
              ),
              const SizedBox(width: AppSpacing.lg),

              // Recent Activities box
              Expanded(
                flex: 6,
                child: _buildRecentActivityCard(context, data),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockCard(BuildContext context, DashboardData data) {
    final colors = context.colors;
    final lowStock = data.lowStockProducts;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.danger.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.warning_amber_rounded,
                          color: colors.danger, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'تنبيهات نواقص المخزون',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (lowStock.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${lowStock.length} أصناف حرجة',
                    style: TextStyle(
                      color: colors.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (lowStock.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: 40, color: colors.success.withValues(alpha: 0.8)),
                    const SizedBox(height: 8),
                    Text(
                      'جميع مستويات المخزون آمنة وضمن الحدود',
                      style: TextStyle(fontSize: 14, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lowStock.length > 5 ? 5 : lowStock.length,
              separatorBuilder: (_, __) => Divider(color: colors.border, height: 1),
              itemBuilder: (context, index) {
                final p = lowStock[index];
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: colors.surfaceElevated,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  title: Text(
                    p.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'الحد الأدنى: ${p.lowStockThreshold ?? "-"} | الرصيد الحالي: ${p.currentQuantity}',
                    style: TextStyle(fontSize: 12, color: colors.textMuted),
                  ),
                  trailing: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => context.push('/purchases/create'),
                    child: const Text('طلب توريد', style: TextStyle(fontSize: 12)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard(BuildContext context, DashboardData data) {
    final colors = context.colors;
    final activities = data.recentActivities;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.history_rounded,
                          color: colors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'آخر الحركات التشغيلية',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'محدث لحظياً',
                style: TextStyle(fontSize: 12, color: colors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'لا توجد حركات مسجلة مؤخراً اليوم',
                  style: TextStyle(fontSize: 14, color: colors.textSecondary),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length > 5 ? 5 : activities.length,
              separatorBuilder: (_, __) => Divider(color: colors.border, height: 1),
              itemBuilder: (context, index) {
                final act = activities[index];
                final iconData = _getActivityIcon(act.type);
                final iconColor = _getActivityColor(context, act.type);

                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(iconData, color: iconColor, size: 16),
                  ),
                  title: Text(
                    act.description,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '${act.time.hour.toString().padLeft(2, '0')}:${act.time.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 12, color: colors.textMuted),
                  ),
                  trailing: Text(
                    _hideAmounts ? '••••••' : act.amount.formatted,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                      letterSpacing: _hideAmounts ? 2.0 : null,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    return switch (type) {
      'sale' => Icons.shopping_cart_outlined,
      'purchase' => Icons.shopping_bag_outlined,
      'expense' => Icons.receipt_long_outlined,
      'customer_payment' || 'supplier_payment' || 'payment' => Icons.payments_outlined,
      'customer_return' || 'supplier_return' || 'return' => Icons.assignment_return_outlined,
      _ => Icons.sync_alt_rounded,
    };
  }

  Color _getActivityColor(BuildContext context, String type) {
    final colors = context.colors;
    return switch (type) {
      'sale' => colors.success,
      'purchase' => Colors.teal,
      'expense' => colors.danger,
      'customer_payment' || 'supplier_payment' || 'payment' => colors.info,
      'customer_return' || 'supplier_return' || 'return' => colors.warning,
      _ => colors.textSecondary,
    };
  }
}
