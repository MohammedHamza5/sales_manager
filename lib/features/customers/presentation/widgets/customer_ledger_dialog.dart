import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/print/print_service.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_kpi_card.dart';
import '../../../../core/widgets/states/empty_view.dart';
import '../../../../core/widgets/states/error_view.dart';
import '../../../../core/widgets/states/loading_view.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_ledger_entry.dart';
import '../../domain/usecases/watch_customer_ledger_usecase.dart';
import '../cubit/customer_ledger_cubit.dart';
import '../cubit/customer_ledger_state.dart';
import '../../../customer_payments/presentation/cubit/customer_payments_cubit.dart';
import '../../../customer_payments/presentation/widgets/record_customer_payment_dialog.dart';

class CustomerLedgerDialog extends StatelessWidget {
  final Customer customer;

  const CustomerLedgerDialog({super.key, required this.customer});

  static Future<void> show(BuildContext context, Customer customer) {
    return showDialog<void>(
      context: context,
      builder: (context) => BlocProvider(
        create: (context) => CustomerLedgerCubit(
          watchCustomerLedgerUseCase: getIt<WatchCustomerLedgerUseCase>(),
          customerId: customer.id,
        )..init(),
        child: CustomerLedgerDialog(customer: customer),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CustomerLedgerCubit>();
    final colors = context.colors;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1020, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colors.primaryLight,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Icon(
                            Icons.receipt_long_rounded,
                            color: colors.primary,
                            size: 26,
                          ),
                        ),
                        AppSpacing.horizontalMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    customer.name,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  if (customer.phone != null) ...[
                                    AppSpacing.horizontalSm,
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.surfaceElevated,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: colors.border),
                                      ),
                                      child: Text(
                                        customer.phone!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              AppSpacing.verticalXs,
                              Text(
                                'كشف حساب تفصيلي: الحركات المالية، المبيعات، السدادات النقدية، والأرصدة',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  BlocBuilder<CustomerLedgerCubit, CustomerLedgerState>(
                    builder: (context, state) {
                      if (state is CustomerLedgerLoaded && state.entries.isNotEmpty) {
                        return IconButton(
                          onPressed: () => _printStatement(context, state.entries),
                          icon: Icon(Icons.print_outlined, color: colors.textSecondary),
                          tooltip: 'طباعة كشف الحساب',
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  ElevatedButton.icon(
                    onPressed: () => RecordCustomerPaymentDialog.show(
                      context,
                      getIt<CustomerPaymentsCubit>(),
                      preselectedCustomerId: customer.id,
                    ),
                    icon: const Icon(Icons.add_card, size: 16),
                    label: const Text('تسجيل تحصيل'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                    tooltip: AppStrings.cancel,
                  ),
                ],
              ),
              Divider(height: 24, thickness: 1, color: colors.border),

              // 2. Body Area
              Expanded(
                child: BlocBuilder<CustomerLedgerCubit, CustomerLedgerState>(
                  builder: (context, state) {
                    return switch (state) {
                      CustomerLedgerInitial() ||
                      CustomerLedgerLoading() =>
                        const LoadingView(),
                      CustomerLedgerError(message: final msg) => ErrorView(
                          message: msg,
                          onRetry: () => cubit.init(),
                        ),
                      CustomerLedgerEmpty(
                        message: final msg,
                        hasFilter: final hasFilter,
                      ) =>
                        EmptyView(
                          title: msg,
                          subtitle: hasFilter
                              ? 'لا توجد حركات تطابق نوع العملية المختار'
                              : 'لم يتم تسجيل أي حركة مالية أو فاتورة لهذا العميل بعد',
                          icon: Icons.receipt_long_outlined,
                          actionLabel: hasFilter ? 'عرض كل الحركات' : null,
                          onAction:
                              hasFilter ? () => cubit.setFilterType(null) : null,
                        ),
                      CustomerLedgerLoaded() =>
                        _buildLoadedStatement(context, cubit, state),
                    };
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadedStatement(
    BuildContext context,
    CustomerLedgerCubit cubit,
    CustomerLedgerLoaded state,
  ) {
    final colors = context.colors;
    final filtered = state.filteredEntries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. KPI Summary Cards
        Row(
          children: [
            _buildSummaryCard(
              context: context,
              label: 'إجمالي المسحوبات والديون (مدين +)',
              value: state.totalDebit.formatArabic(),
              icon: Icons.arrow_upward_rounded,
              color: colors.danger,
            ),
            AppSpacing.horizontalMd,
            _buildSummaryCard(
              context: context,
              label: 'إجمالي المدفوعات والسداد (دائن -)',
              value: state.totalCredit.formatArabic(),
              icon: Icons.arrow_downward_rounded,
              color: colors.success,
            ),
            AppSpacing.horizontalMd,
            _buildSummaryCard(
              context: context,
              label: 'صافي الرصيد الحالي',
              value: state.netBalance.formatArabic(),
              icon: Icons.account_balance_wallet_rounded,
              color: state.netBalance.piastres > 0
                  ? colors.danger
                  : (state.netBalance.piastres < 0
                      ? colors.primary
                      : colors.success),
            ),
            AppSpacing.horizontalMd,
            _buildSummaryCard(
              context: context,
              label: 'عدد الحركات',
              value: '${state.count}',
              icon: Icons.format_list_numbered_rounded,
              color: colors.textPrimary,
            ),
          ],
        ),
        AppSpacing.verticalMd,

        // 2. Filter Chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              key: const ValueKey('chip_all'),
              label: Text(
                'كل الحركات',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: state.filterEntryType == null ? colors.onPrimary : colors.textSecondary,
                ),
              ),
              selected: state.filterEntryType == null,
              selectedColor: colors.primary,
              backgroundColor: colors.surfaceElevated,
              side: BorderSide(
                color: state.filterEntryType == null ? colors.primary : colors.border,
              ),
              onSelected: (_) => cubit.setFilterType(null),
            ),
            ...CustomerLedgerEntryType.values.map((type) {
              final isSelected = state.filterEntryType == type;
              return ChoiceChip(
                key: ValueKey('chip_${type.name}'),
                label: Text(
                  type.arabicTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? colors.onPrimary : colors.textSecondary,
                  ),
                ),
                selected: isSelected,
                selectedColor: colors.primary,
                backgroundColor: colors.surfaceElevated,
                side: BorderSide(
                  color: isSelected ? colors.primary : colors.border,
                ),
                onSelected: (_) => cubit.setFilterType(type),
              );
            }),
          ],
        ),
        AppSpacing.verticalMd,

        // 3. DataTable of Ledger Entries
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(colors.surfaceElevated),
                  dataRowColor: WidgetStateProperty.all(colors.surface),
                  headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
                  columns: const [
                    DataColumn(
                      label: Text('التاريخ والوقت'),
                    ),
                    DataColumn(
                      label: Text('نوع الحركة'),
                    ),
                    DataColumn(
                      label: Text('المرجع'),
                    ),
                    DataColumn(
                      label: Text('مدين (يزيد الدين)'),
                    ),
                    DataColumn(
                      label: Text('دائن (سداد)'),
                    ),
                    DataColumn(
                      label: Text('الرصيد بعدها'),
                    ),
                    DataColumn(
                      label: Text('البيان / ملاحظات'),
                    ),
                    DataColumn(
                      label: Text('المسؤول'),
                    ),
                  ],
                  rows: filtered.map((e) => _buildLedgerRow(context, e)).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: AppKpiCard(
        title: label,
        value: value,
        icon: icon,
        color: color,
      ),
    );
  }

  DataRow _buildLedgerRow(BuildContext context, CustomerLedgerEntry entry) {
    final colors = context.colors;
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    final isDebit = entry.isDebtIncrease;
    final isCredit = entry.isDebtDecrease;

    return DataRow(
      cells: [
        // Date
        DataCell(
          Text(
            dateFormat.format(entry.createdAt),
            style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: colors.textSecondary),
          ),
        ),
        // Type Badge
        DataCell(_buildTypeBadge(context, entry.entryType)),
        // Reference
        DataCell(
          Text(
            entry.referenceId != null
                ? '#${entry.referenceId}'
                : (entry.referenceType ?? '—'),
            style: TextStyle(fontFamily: 'monospace', color: colors.textPrimary),
          ),
        ),
        // Debit
        DataCell(
          Text(
            isDebit ? entry.amount.formatArabic() : '—',
            style: TextStyle(
              fontWeight: isDebit ? FontWeight.bold : FontWeight.normal,
              color: isDebit ? colors.danger : colors.textSecondary,
            ),
          ),
        ),
        // Credit
        DataCell(
          Text(
            isCredit ? entry.amount.formatArabic() : '—',
            style: TextStyle(
              fontWeight: isCredit ? FontWeight.bold : FontWeight.normal,
              color: isCredit ? colors.success : colors.textSecondary,
            ),
          ),
        ),
        // Balance After
        DataCell(
          Text(
            entry.balanceAfter.formatArabic(),
            style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary),
          ),
        ),
        // Note
        DataCell(
          Text(
            entry.note ?? '—',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
        ),
        // CreatedBy
        DataCell(
          Text(
            entry.createdBy,
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeBadge(BuildContext context, CustomerLedgerEntryType type) {
    final colors = context.colors;
    final color = switch (type) {
      CustomerLedgerEntryType.sale => colors.primary,
      CustomerLedgerEntryType.payment => colors.success,
      CustomerLedgerEntryType.openingBalance => colors.warning,
      CustomerLedgerEntryType.customerReturn => colors.danger,
      CustomerLedgerEntryType.reversal => colors.accent,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        type.arabicTitle,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Future<void> _printStatement(
    BuildContext context,
    List<CustomerLedgerEntry> entries,
  ) async {
    try {
      final printService = getIt<PrintService>();
      final mapped = entries
          .map((e) => {
                'date': DateFormat('yyyy/MM/dd HH:mm').format(e.createdAt),
                'type': e.entryType.arabicTitle,
                'note': e.note ?? '—',
                'debit': e.isDebtIncrease ? e.amount.formatted : null,
                'credit': e.isDebtDecrease ? e.amount.formatted : null,
                'balanceAfter': e.balanceAfter.formatted,
              })
          .toList();

      await printService.printAccountStatement(
        title: 'كشف حساب عميل',
        partyName: customer.name,
        partyPhone: customer.phone,
        currentBalance: customer.currentBalance.formatted,
        entries: mapped,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في إرسال أمر الطباعة: $e'),
            backgroundColor: context.colors.danger,
          ),
        );
      }
    }
  }
}
