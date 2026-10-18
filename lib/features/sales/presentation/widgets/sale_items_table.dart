import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import '../../../../core/money/money.dart';
import '../../../../core/money/quantity.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubit/create_sale_state.dart';

class SaleItemsTable extends StatelessWidget {
  final List<SaleItemDraft> items;
  final void Function(int index, Decimal quantity) onQuantityChanged;
  final void Function(int index, Money price) onPriceChanged;
  final void Function(int index) onRemoveItem;

  const SaleItemsTable({
    super.key,
    required this.items,
    required this.onQuantityChanged,
    required this.onPriceChanged,
    required this.onRemoveItem,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (items.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: colors.border),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 48, color: colors.textMuted),
              AppSpacing.verticalSm,
              Text(
                'لم يتم إضافة أصناف إلى الفاتورة بعد',
                style: TextStyle(color: colors.textSecondary, fontSize: 15),
              ),
              AppSpacing.verticalXs,
              Text(
                'ابحث عن المنتج بالأعلى لإضافته لسلة البيع',
                style: TextStyle(color: colors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(colors.surfaceElevated),
          headingTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
            fontSize: 13,
          ),
          dataTextStyle: TextStyle(
            color: colors.textPrimary,
            fontSize: 12,
          ),
          horizontalMargin: AppSpacing.md,
          columnSpacing: AppSpacing.lg,
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('اسم الصنف')),
            DataColumn(label: Text('المتاح بالمخزن')),
            DataColumn(label: Text('الكمية')),
            DataColumn(label: Text('السعر')),
            DataColumn(label: Text('الإجمالي')),
            DataColumn(label: Text('حالة الرصيد')),
            DataColumn(label: Text('إجراء')),
          ],
          rows: List.generate(items.length, (index) {
            final item = items[index];
            final isOverselling = item.isOverselling;

            return DataRow(
              color: isOverselling
                  ? WidgetStateProperty.all(colors.danger.withValues(alpha: 0.08))
                  : null,
              cells: [
                DataCell(Text('${index + 1}')),
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (item.productCode != null && item.productCode!.isNotEmpty)
                        Text(
                          'كود: ${item.productCode} (${item.productUnit})',
                          style: TextStyle(fontSize: 11, color: colors.textMuted),
                        ),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    QuantityHelper.format(item.availableStock, unit: item.productUnit),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: item.availableStock <= Decimal.zero
                          ? colors.danger
                          : colors.textPrimary,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      initialValue: item.quantity.toString(),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: colors.surfaceElevated,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isOverselling ? colors.danger : colors.border,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isOverselling ? colors.danger : colors.border,
                          ),
                        ),
                        errorStyle: const TextStyle(fontSize: 0),
                      ),
                      onChanged: (val) {
                        final parsed = QuantityHelper.tryParse(val);
                        if (parsed != null && parsed > Decimal.zero) {
                          onQuantityChanged(index, parsed);
                        }
                      },
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 110,
                    child: TextFormField(
                      initialValue: (item.unitPrice.piastres / 100.0).toStringAsFixed(2),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: colors.surfaceElevated,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: colors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: colors.border),
                        ),
                      ),
                      onChanged: (val) {
                        final parsed = Money.tryParse(val);
                        if (parsed != null && parsed.piastres >= 0) {
                          onPriceChanged(index, parsed);
                        }
                      },
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    item.lineTotal.formatArabic(),
                    style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
                  ),
                ),
                DataCell(
                  isOverselling
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.danger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: colors.danger.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, size: 14, color: colors.danger),
                              const SizedBox(width: 4),
                              Text(
                                'تجاوز المخزون',
                                style: TextStyle(
                                  color: colors.danger,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: colors.success.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline, size: 14, color: colors.success),
                              const SizedBox(width: 4),
                              Text(
                                'يتبقى ${QuantityHelper.format(item.remainingStockAfterSale, unit: item.productUnit)}',
                                style: TextStyle(
                                  color: colors.success,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                DataCell(
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: colors.danger),
                    tooltip: 'حذف الصنف',
                    onPressed: () => onRemoveItem(index),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
