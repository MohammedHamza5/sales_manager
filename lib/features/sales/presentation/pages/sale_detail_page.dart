import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/money/quantity.dart';
import '../../../../core/print/print_service.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/states/error_view.dart';
import '../../../../core/widgets/states/loading_view.dart';
import '../../domain/entities/sale.dart';
import '../cubit/sale_detail_cubit.dart';
import '../cubit/sale_detail_state.dart';

class SaleDetailPage extends StatelessWidget {
  final int id;

  const SaleDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SaleDetailCubit(
        getSaleByIdUseCase: getIt(),
        reverseSaleUseCase: getIt(),
      )..loadSale(id),
      child: _SaleDetailView(saleId: id),
    );
  }
}

class _SaleDetailView extends StatelessWidget {
  final int saleId;

  const _SaleDetailView({required this.saleId});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocConsumer<SaleDetailCubit, SaleDetailState>(
      listener: (context, state) {
        if (state is SaleDetailLoaded && state.reverseSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(AppStrings.reverseSuccess),
              backgroundColor: colors.success,
            ),
          );
        } else if (state is SaleDetailLoaded && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: colors.danger,
            ),
          );
        }
      },
      builder: (context, state) {
        return switch (state) {
          SaleDetailInitial() || SaleDetailLoading() => const Scaffold(
              body: LoadingView(message: 'جاري تحميل تفاصيل الفاتورة...'),
            ),
          SaleDetailError(message: final msg) => Scaffold(
              appBar: AppBar(),
              body: ErrorView(
                message: msg,
                onRetry: () => context.read<SaleDetailCubit>().loadSale(saleId),
              ),
            ),
          SaleDetailLoaded() => _buildLoadedView(context, state),
        };
      },
    );
  }

  Widget _buildLoadedView(BuildContext context, SaleDetailLoaded state) {
    final sale = state.sale;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'تفاصيل فاتورة بيع #${sale.invoiceNo}',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: colors.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: colors.border, height: 1),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'طباعة إيصال حراري (80mm)',
            icon: Icon(Icons.receipt_long_outlined, color: colors.textSecondary),
            onPressed: () => _printReceipt(context, sale),
          ),
          IconButton(
            tooltip: 'طباعة فاتورة A4',
            icon: Icon(Icons.print_outlined, color: colors.textSecondary),
            onPressed: () => _printInvoice(context, sale),
          ),
          if (sale.isConfirmed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: state.isReversing
                    ? null
                    : () => _showReverseConfirmationDialog(context, sale),
                icon: const Icon(Icons.undo, size: 18),
                label: const Text(AppStrings.reverseInvoice),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.danger,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Alert Banner (if reversed)
            if (sale.isReversed) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.danger.withValues(alpha: 0.12),
                  border: Border.all(color: colors.danger),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: colors.danger, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'هذه الفاتورة تم إلغاؤها وعكس أثرها بالكامل',
                            style: TextStyle(
                              color: colors.danger,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'تم إرجاع بضاعة الأصناف للمخزن وعكس الرصيد المالي في حساب العميل والخزينة.',
                            style: TextStyle(fontSize: 12, color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.verticalMd,
            ],

            // Top Summary Cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('بيانات العميل', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                        AppSpacing.verticalXs,
                        Text(sale.customerName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colors.textPrimary)),
                        if (sale.customerPhone != null)
                          Text(sale.customerPhone!, style: TextStyle(fontSize: 12, color: colors.textMuted)),
                      ],
                    ),
                  ),
                ),
                AppSpacing.horizontalMd,
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تاريخ الفاتورة', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                        AppSpacing.verticalXs,
                        Text(DateFormat('yyyy/MM/dd').format(sale.saleDate), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colors.textPrimary)),
                        Text('سجلت بواسطة: ${sale.createdBy}', style: TextStyle(fontSize: 12, color: colors.textMuted)),
                      ],
                    ),
                  ),
                ),
                AppSpacing.horizontalMd,
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('إجمالي الفاتورة', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                        AppSpacing.verticalXs,
                        Text(sale.totalAmount.formatArabic(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colors.primary)),
                        Text(
                          sale.isFullyPaid
                              ? (sale.hasReturns ? 'مسددة بالكامل (مع مرتجع)' : 'مسددة بالكامل نقداً')
                              : 'متبقي: ${sale.remainingAmount.formatArabic()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: sale.isFullyPaid ? colors.success : colors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (sale.hasReturns) ...[
                          const SizedBox(height: 2),
                          Text(
                            'مرتجع: ${sale.returnedAmount.formatArabic()} (الصافي: ${sale.netAmount.formatArabic()})',
                            style: TextStyle(fontSize: 11, color: colors.warning, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.verticalLg,

            // Items Table Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'أصناف الفاتورة',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
                  ),
                  AppSpacing.verticalMd,
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
                      columns: const [
                        DataColumn(label: Text('#')),
                        DataColumn(label: Text('اسم الصنف')),
                        DataColumn(label: Text('الكمية المباعة')),
                        DataColumn(label: Text('سعر الوحدة')),
                        DataColumn(label: Text('الإجمالي')),
                      ],
                      rows: sale.items.map((item) {
                        return DataRow(
                          cells: [
                            DataCell(Text('${sale.items.indexOf(item) + 1}')),
                            DataCell(
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  if (item.productCode.isNotEmpty)
                                    Text('كود: ${item.productCode}', style: TextStyle(fontSize: 11, color: colors.textMuted)),
                                ],
                              ),
                            ),
                            DataCell(Text(QuantityHelper.format(item.quantity, unit: item.productUnit))),
                            DataCell(Text(item.unitPriceAtSale.formatArabic())),
                            DataCell(Text(item.lineTotal.formatArabic(), style: const TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.verticalMd,

            // Note if present
            if (sale.note != null && sale.note!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ملاحظات الفاتورة:', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                    AppSpacing.verticalXs,
                    Text(sale.note!, style: TextStyle(color: colors.textSecondary)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReverseConfirmationDialog(BuildContext context, Sale sale) {
    final reasonController = TextEditingController();
    final cubit = context.read<SaleDetailCubit>();
    final colors = context.colors;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            side: BorderSide(color: colors.border),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: colors.danger),
              const SizedBox(width: 8),
              Text(AppStrings.reverseConfirmTitle, style: TextStyle(color: colors.textPrimary)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.reverseConfirmMessage, style: TextStyle(color: colors.textSecondary)),
              AppSpacing.verticalMd,
              TextField(
                controller: reasonController,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'سبب الإلغاء (اختياري)',
                  filled: true,
                  fillColor: colors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: colors.border),
                  ),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppStrings.cancel, style: TextStyle(color: colors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                cubit.reverseSale(sale.id, reason: reasonController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.danger,
                foregroundColor: Colors.white,
              ),
              child: const Text('تأكيد الإلغاء والعكس'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _printReceipt(BuildContext context, Sale sale) async {
    try {
      final printService = getIt<PrintService>();
      final items = sale.items
          .map((i) => {
                'name': i.productName,
                'quantity': i.quantity.toString(),
                'unit': i.productUnit.isNotEmpty ? i.productUnit : 'قطعة',
                'price': i.unitPriceAtSale.formatted,
                'total': i.lineTotal.formatted,
              })
          .toList();

      await printService.printSaleReceipt(
        invoiceNo: sale.invoiceNo.toString(),
        date: sale.saleDate,
        customerName: sale.customerName.isNotEmpty ? sale.customerName : 'عميل نقدي',
        items: items,
        totalAmount: sale.totalAmount.formatted,
        paidAmount: sale.paidAmountAtCreation.formatted,
        remainingAmount: sale.remainingAmount.formatted,
        note: sale.note,
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

  Future<void> _printInvoice(BuildContext context, Sale sale) async {
    try {
      final printService = getIt<PrintService>();
      final items = sale.items
          .map((i) => {
                'name': i.productName,
                'quantity': i.quantity.toString(),
                'unit': i.productUnit.isNotEmpty ? i.productUnit : 'قطعة',
                'price': i.unitPriceAtSale.formatted,
                'total': i.lineTotal.formatted,
              })
          .toList();

      await printService.printSaleInvoice(
        invoiceNo: sale.invoiceNo.toString(),
        date: sale.saleDate,
        customerName: sale.customerName.isNotEmpty ? sale.customerName : 'عميل نقدي',
        customerPhone: sale.customerPhone,
        items: items,
        totalAmount: sale.totalAmount.formatted,
        paidAmount: sale.paidAmountAtCreation.formatted,
        remainingAmount: sale.remainingAmount.formatted,
        note: sale.note,
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
