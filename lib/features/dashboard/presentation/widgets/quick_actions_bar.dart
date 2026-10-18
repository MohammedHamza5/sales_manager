import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class QuickActionsBar extends StatelessWidget {
  const QuickActionsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: colors.primary, size: 20),
              const SizedBox(width: 6),
              Text(
                'إجراءات سريعة:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildActionButton(
                    context,
                    label: 'فاتورة بيع جديدة',
                    icon: Icons.add_shopping_cart,
                    color: colors.primary,
                    route: '/sales',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildActionButton(
                    context,
                    label: 'فاتورة شراء جديدة',
                    icon: Icons.add_business_outlined,
                    color: colors.warning,
                    route: '/purchases',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildActionButton(
                    context,
                    label: 'تحصيل نقدية (عميل)',
                    icon: Icons.input_rounded,
                    color: colors.success,
                    route: '/customer-payments',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildActionButton(
                    context,
                    label: 'سداد نقدية (مورد)',
                    icon: Icons.output_rounded,
                    color: Colors.deepOrange,
                    route: '/supplier-payments',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildActionButton(
                    context,
                    label: 'صرف مصروف',
                    icon: Icons.money_off,
                    color: colors.danger,
                    route: '/expenses',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildActionButton(
                    context,
                    label: 'التقارير الشاملة',
                    icon: Icons.bar_chart_outlined,
                    color: Colors.indigo,
                    route: '/reports',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return FilledButton.tonalIcon(
      onPressed: () => context.push(route),
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      style: FilledButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withValues(alpha: 0.2)),
        ),
      ),
    );
  }
}
