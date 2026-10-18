import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../products/domain/entities/product.dart';

class LowStockAlerts extends StatelessWidget {
  final List<Product> products;
  final ValueChanged<Product>? onProductTap;
  final VoidCallback? onViewAll;

  const LowStockAlerts({
    super.key,
    required this.products,
    this.onProductTap,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
                        color: products.isNotEmpty
                            ? colors.warning.withValues(alpha: 0.15)
                            : colors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        products.isNotEmpty
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline,
                        color: products.isNotEmpty ? colors.warning : colors.success,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'تنبيهات المخزون المنخفض',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (products.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.danger,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${products.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text('عرض المنتجات'),
                  ),
              ],
            ),
            Divider(height: AppSpacing.lg, color: colors.border),
            if (products.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 40, color: colors.success),
                      const SizedBox(height: 8),
                      Text(
                        'المخزون في حالة ممتازة',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'جميع المنتجات متوفرة فوق الحد الأدنى الآمن',
                        style: TextStyle(fontSize: 12, color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length > 5 ? 5 : products.length,
                separatorBuilder: (_, __) => Divider(height: 12, color: colors.border),
                itemBuilder: (context, index) {
                  final product = products[index];
                  final isDepleted = product.isOutOfStock;
                  return InkWell(
                    onTap: () => onProductTap?.call(product),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDepleted ? colors.danger : colors.warning,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: colors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (product.code != null)
                                  Text(
                                    'كود: ${product.code}',
                                    style: TextStyle(fontSize: 11, color: colors.textMuted),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${product.currentQuantity} ${product.unit}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isDepleted ? colors.danger : colors.warning,
                                ),
                              ),
                              Text(
                                'الحد الأدنى: ${product.lowStockThreshold ?? 0}',
                                style: TextStyle(fontSize: 11, color: colors.textMuted),
                              ),
                            ],
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
}
