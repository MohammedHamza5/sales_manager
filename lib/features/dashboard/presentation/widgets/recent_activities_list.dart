import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/recent_activity.dart';

class RecentActivitiesList extends StatelessWidget {
  final List<RecentActivity> activities;
  final ValueChanged<RecentActivity>? onActivityTap;
  final VoidCallback? onViewAll;

  const RecentActivitiesList({
    super.key,
    required this.activities,
    this.onActivityTap,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final timeFormat = DateFormat('hh:mm a', 'ar');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.border),
      ),
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.history_outlined,
                        color: colors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'آخر العمليات والحركات النقدية',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text('سجل الخزينة'),
                  ),
              ],
            ),
            Divider(height: AppSpacing.lg, color: colors.border),
            if (activities.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 40, color: colors.textMuted),
                      const SizedBox(height: 8),
                      Text(
                        'لا توجد عمليات مسجلة حديثاً',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.length > 7 ? 7 : activities.length,
                separatorBuilder: (_, __) => Divider(height: 12, color: colors.border),
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  final isIn = activity.direction == 'in';
                  final amountColor = isIn ? colors.success : colors.danger;

                  return InkWell(
                    onTap: () => onActivityTap?.call(activity),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      child: Row(
                        children: [
                          _buildTypeIcon(context, activity.type, isIn),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activity.description,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: colors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  timeFormat.format(activity.time),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${isIn ? "+" : "-"}${activity.amount.formatted}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: amountColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon(BuildContext context, String type, bool isIn) {
    final colors = context.colors;
    IconData icon;
    Color color;

    switch (type) {
      case 'sale':
        icon = Icons.point_of_sale;
        color = colors.primary;
        break;
      case 'customer_payment':
        icon = Icons.payments;
        color = colors.success;
        break;
      case 'purchase':
        icon = Icons.shopping_bag;
        color = colors.warning;
        break;
      case 'supplier_payment':
        icon = Icons.local_shipping;
        color = Colors.deepOrange;
        break;
      case 'expense':
        icon = Icons.money_off;
        color = colors.danger;
        break;
      default:
        icon = isIn ? Icons.arrow_downward : Icons.arrow_upward;
        color = isIn ? colors.success : colors.danger;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}
