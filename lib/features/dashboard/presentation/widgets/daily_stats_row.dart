import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/daily_stats.dart';
import 'stat_card.dart';

class DailyStatsRow extends StatelessWidget {
  final DailyStats stats;
  final VoidCallback? onSalesTap;
  final VoidCallback? onCollectionsTap;
  final VoidCallback? onPurchasesTap;
  final VoidCallback? onExpensesTap;

  const DailyStatsRow({
    super.key,
    required this.stats,
    this.onSalesTap,
    this.onCollectionsTap,
    this.onPurchasesTap,
    this.onExpensesTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: StatCard(
              title: 'مبيعات اليوم',
              value: stats.todaySales.formatted,
              subtitle: '${stats.todaySalesCount} فواتير بيع مؤكدة',
              icon: Icons.point_of_sale_outlined,
              color: colors.primary,
              badge: stats.todaySalesCount > 0 ? '${stats.todaySalesCount}' : null,
              onTap: onSalesTap,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: StatCard(
              title: 'تحصيلات العملاء اليوم',
              value: stats.todayCollections.formatted,
              subtitle: '${stats.todayCollectionsCount} سندات قبض نقدية',
              icon: Icons.payments_outlined,
              color: colors.success,
              badge: stats.todayCollectionsCount > 0 ? '${stats.todayCollectionsCount}' : null,
              onTap: onCollectionsTap,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: StatCard(
              title: 'مشتريات اليوم',
              value: stats.todayPurchases.formatted,
              subtitle: 'فواتير مشتريات مؤكدة',
              icon: Icons.shopping_bag_outlined,
              color: colors.warning,
              onTap: onPurchasesTap,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: StatCard(
              title: 'مصروفات اليوم',
              value: stats.todayExpenses.formatted,
              subtitle: 'مصروفات تشغيل ونثريات',
              icon: Icons.money_off_csred_outlined,
              color: colors.danger,
              onTap: onExpensesTap,
            ),
          ),
        ],
      ),
    );
  }
}
