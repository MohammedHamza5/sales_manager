import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/states/empty_view.dart';
import '../../../../core/widgets/states/error_view.dart';
import '../../../../core/widgets/states/loading_view.dart';
import '../../../../core/widgets/app_kpi_card.dart';
import '../cubit/customer_payments_cubit.dart';
import '../cubit/customer_payments_state.dart';
import '../widgets/record_customer_payment_dialog.dart';

class CustomerPaymentsPage extends StatelessWidget {
  final int? customerId;

  const CustomerPaymentsPage({super.key, this.customerId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CustomerPaymentsCubit>()..init(customerId: customerId),
      child: const _CustomerPaymentsView(),
    );
  }
}

class _CustomerPaymentsView extends StatelessWidget {
  const _CustomerPaymentsView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CustomerPaymentsCubit>();
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سندات تحصيل العملاء',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'سجل النقدية المحصلة من العملاء والواردة للخزينة',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => RecordCustomerPaymentDialog.show(context, cubit),
                  icon: const Icon(Icons.add),
                  label: const Text('تسجيل سند تحصيل جديد'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Content
            Expanded(
              child: BlocBuilder<CustomerPaymentsCubit, CustomerPaymentsState>(
                builder: (context, state) {
                  return switch (state) {
                    CustomerPaymentsInitial() ||
                    CustomerPaymentsLoading() =>
                      const LoadingView(),
                    CustomerPaymentsError(message: final msg) => ErrorView(
                        message: msg,
                        onRetry: () => cubit.init(),
                      ),
                    CustomerPaymentsEmpty() => EmptyView(
                        title: 'لا توجد سندات تحصيل مسجلة حتى الآن',
                        subtitle: 'ابدأ بتسجيل أول سند تحصيل نقدية لتحديث أرصدة العملاء والخزينة',
                        icon: Icons.receipt_long_outlined,
                        actionLabel: 'تسجيل أول سند تحصيل',
                        onAction: () => RecordCustomerPaymentDialog.show(context, cubit),
                      ),
                    CustomerPaymentsLoaded() => _buildLoadedView(context, cubit, state),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedView(
    BuildContext context,
    CustomerPaymentsCubit cubit,
    CustomerPaymentsLoaded state,
  ) {
    final colors = context.colors;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // KPI Summary Cards
        Row(
          children: [
            Expanded(
              child: AppKpiCard(
                title: 'إجمالي النقدية المحصلة',
                value: state.totalCollected.formatted,
                icon: Icons.account_balance_wallet,
                color: colors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppKpiCard(
                title: 'عدد سندات التحصيل',
                value: '${state.allPayments.length}',
                icon: Icons.receipt,
                color: colors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Search bar
        TextField(
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'بحث باسم العميل أو رقم الفاتورة أو الملاحظات...',
            hintStyle: TextStyle(color: colors.textMuted),
            prefixIcon: Icon(Icons.search, color: colors.textSecondary),
            filled: true,
            fillColor: colors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.primary),
            ),
            isDense: true,
          ),
          onChanged: cubit.search,
        ),
        const SizedBox(height: AppSpacing.md),

        // Payments Data Table
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
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('العميل')),
                    DataColumn(label: Text('المبلغ')),
                    DataColumn(label: Text('تاريخ التحصيل')),
                    DataColumn(label: Text('الفاتورة المرتبطة')),
                    DataColumn(label: Text('ملاحظات')),
                    DataColumn(label: Text('المُسجِّل')),
                  ],
                  rows: state.filteredPayments.map((p) {
                    return DataRow(
                      cells: [
                        DataCell(Text(
                          '#${p.id}',
                          style: TextStyle(fontFamily: 'monospace', color: colors.textSecondary),
                        )),
                        DataCell(Text(
                          p.customerName,
                          style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
                        )),
                        DataCell(Text(
                          p.amount.formatted,
                          style: TextStyle(
                            color: colors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                        DataCell(Text(
                          dateFormat.format(p.paymentDate),
                          style: TextStyle(fontFamily: 'monospace', color: colors.textSecondary),
                        )),
                        DataCell(
                          p.linkedSaleInvoiceNo != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colors.primaryLight,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    'فاتورة #${p.linkedSaleInvoiceNo}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: colors.primary,
                                    ),
                                  ),
                                )
                              : Text('-', style: TextStyle(color: colors.textSecondary)),
                        ),
                        DataCell(Text(
                          p.note ?? '-',
                          style: TextStyle(color: colors.textSecondary),
                        )),
                        DataCell(Text(
                          p.createdBy,
                          style: TextStyle(color: colors.textSecondary),
                        )),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
