import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/money/money.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/create_purchase_state.dart';

class PurchaseItemRow extends StatefulWidget {
  final int index;
  final InvoiceItemDraft item;
  final void Function(Decimal quantity) onQuantityChanged;
  final void Function(Money unitCost) onUnitCostChanged;
  final VoidCallback onRemove;

  const PurchaseItemRow({
    super.key,
    required this.index,
    required this.item,
    required this.onQuantityChanged,
    required this.onUnitCostChanged,
    required this.onRemove,
  });

  @override
  State<PurchaseItemRow> createState() => _PurchaseItemRowState();
}

class _PurchaseItemRowState extends State<PurchaseItemRow> {
  late final TextEditingController _quantityController;
  late final TextEditingController _costController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.item.quantity.toString(),
    );
    _costController = TextEditingController(
      text: widget.item.unitCost.formattedWithoutCurrency,
    );
  }

  @override
  void didUpdateWidget(covariant PurchaseItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.quantity != widget.item.quantity) {
      if (_quantityController.text != widget.item.quantity.toString()) {
        _quantityController.text = widget.item.quantity.toString();
      }
    }
    if (oldWidget.item.unitCost != widget.item.unitCost) {
      if (_costController.text !=
          widget.item.unitCost.formattedWithoutCurrency) {
        _costController.text = widget.item.unitCost.formattedWithoutCurrency;
      }
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          // Index
          SizedBox(
            width: 32,
            child: Text(
              '${widget.index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.textSecondary,
              ),
            ),
          ),
          // Product details
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.item.productName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  'المخزون الحالي: ${widget.item.currentStock} ${widget.item.productUnit}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Quantity
          SizedBox(
            width: 100,
            child: TextField(
              controller: _quantityController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: colors.surfaceElevated,
                labelText: 'الكمية (${widget.item.productUnit})',
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: colors.border),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: (val) {
                final d = Decimal.tryParse(val);
                if (d != null && d > Decimal.zero) {
                  widget.onQuantityChanged(d);
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          // Unit Cost
          SizedBox(
            width: 120,
            child: TextField(
              controller: _costController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: colors.surfaceElevated,
                labelText: 'سعر الشراء (ج.م)',
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: colors.border),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: (val) {
                final m = Money.tryParse(val);
                if (m != null) {
                  widget.onUnitCostChanged(m);
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          // Line Total
          SizedBox(
            width: 120,
            child: Text(
              widget.item.lineTotal.formatted,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: colors.primary,
              ),
            ),
          ),
          // Delete button
          IconButton(
            icon: Icon(Icons.delete_outline, color: colors.danger),
            tooltip: 'حذف الصنف',
            onPressed: widget.onRemove,
          ),
        ],
      ),
    );
  }
}
