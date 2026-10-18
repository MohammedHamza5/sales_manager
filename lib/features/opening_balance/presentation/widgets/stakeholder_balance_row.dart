import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/money/money.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/opening_balance_input.dart';

class StakeholderBalanceRow {
  static DataRow build({
    required BuildContext context,
    required StakeholderOpeningBalance stakeholder,
    required ValueChanged<Money> onBalanceChanged,
    String? hintText,
  }) {
    final colors = context.colors;
    return DataRow(
      cells: [
        // ID
        DataCell(
          Text(
            '#${stakeholder.stakeholderId}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
          ),
        ),
        // Name
        DataCell(
          Text(
            stakeholder.name,
            style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary),
          ),
        ),
        // Phone
        DataCell(
          Text(
            stakeholder.phone ?? '—',
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
        // Balance Input
        DataCell(
          SizedBox(
            width: 160,
            child: TextFormField(
              initialValue: stakeholder.balance.piastres > 0
                  ? stakeholder.balance.formatArabic(showCurrency: false)
                  : '',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                hintText: hintText ?? '0.00',
                suffixText: 'ج.م',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: (val) {
                final parsed = Money.tryParse(val.trim()) ?? Money.zero;
                onBalanceChanged(parsed);
              },
            ),
          ),
        ),
      ],
    );
  }
}
