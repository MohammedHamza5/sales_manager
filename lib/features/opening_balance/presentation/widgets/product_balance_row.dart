import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/opening_balance_input.dart';

class ProductBalanceRow {
  static DataRow build({
    required BuildContext context,
    required ProductOpeningBalance product,
    required ValueChanged<Decimal> onQuantityChanged,
  }) {
    final colors = context.colors;
    return DataRow(
      cells: [
        // ID
        DataCell(
          Text(
            '#${product.productId}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
          ),
        ),
        // Product Name
        DataCell(
          Text(
            product.productName,
            style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary),
          ),
        ),
        // SKU / Code
        DataCell(
          Text(
            product.code ?? '—',
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
        // Unit Name
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colors.primaryLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              product.unit,
              style: TextStyle(fontSize: 12, color: colors.primary),
            ),
          ),
        ),
        // Quantity Input
        DataCell(
          SizedBox(
            width: 140,
            child: TextFormField(
              initialValue: product.initialQuantity > Decimal.zero
                  ? product.initialQuantity.toString()
                  : '',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: const InputDecoration(
                hintText: '0',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: (val) {
                final parsed = Decimal.tryParse(val.trim()) ?? Decimal.zero;
                onQuantityChanged(parsed);
              },
            ),
          ),
        ),
      ],
    );
  }
}
