import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/print/print_service.dart';
import '../../../../core/result/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../../domain/usecases/reverse_purchase_usecase.dart';

class PurchaseDetailPage extends StatefulWidget {
  final int id;

  const PurchaseDetailPage({super.key, required this.id});

  @override
  State<PurchaseDetailPage> createState() => _PurchaseDetailPageState();
}

class _PurchaseDetailPageState extends State<PurchaseDetailPage> {
  Purchase? _purchase;
  bool _isLoading = true;
  String? _error;
  bool _isReversing = false;

  @override
  void initState() {
    super.initState();
    _loadPurchase();
  }

  Future<void> _loadPurchase() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final repo = getIt<PurchaseRepository>();
    final result = await repo.getPurchaseById(widget.id);

    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        setState(() {
          _purchase = data;
          _isLoading = false;
        });
      case FailureResult(:final failure):
        setState(() {
          _error = failure.message;
          _isLoading = false;
        });
    }
  }

  Future<void> _showReverseConfirmationDialog() async {
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colors.danger, size: 28),
            const SizedBox(width: 12),
            Text('تأكيد إلغاء وعكس فاتورة الشراء', style: TextStyle(color: colors.textPrimary)),
          ],
        ),
        content: Text(
          'سيؤدي إلغاء هذه الفاتورة إلى:\n'
          '• إنقاص المخزون لجميع الأصناف الواردة بهذه الفاتورة.\n'
          '• خفض مديونية المورد بقيمة المتبقي.\n'
          '• استرداد النقدية المسددة للخزينة.\n'
          '• وسم الفاتورة كـ "معكوسة ومُلغاة".\n\n'
          'هل أنت متأكد من المتابعة؟',
          style: TextStyle(color: colors.textSecondary, height: 1.5),
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.textPrimary,
              side: BorderSide(color: colors.border),
            ),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('تراجع'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: colors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.undo, size: 18),
            label: const Text('تأكيد العكس'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isReversing = true);
      final reverseUseCase = getIt<ReversePurchaseUseCase>();
      final result = await reverseUseCase(purchaseId: widget.id);

      if (!mounted) return;
      setState(() => _isReversing = false);

      switch (result) {
        case Success(:final data):
          setState(() {
            _purchase = data;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تم عكس وإلغاء فاتورة الشراء بنجاح'),
              backgroundColor: colors.success,
            ),
          );
        case FailureResult(:final failure):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: colors.danger,
              duration: const Duration(seconds: 4),
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text(
          _purchase != null
              ? 'تفاصيل فاتورة شراء #${_purchase!.invoiceNo}'
              : 'تفاصيل فاتورة الشراء',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => context.go('/purchases'),
        ),
        actions: [
          if (_purchase != null)
            IconButton(
              tooltip: 'طباعة فاتورة مشتريات A4',
              icon: Icon(Icons.print_outlined, color: colors.textSecondary),
              onPressed: () => _printPurchaseInvoice(_purchase!),
            ),
          if (_purchase != null && _purchase!.isConfirmed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.danger,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed:
                    _isReversing ? null : _showReverseConfirmationDialog,
                icon: _isReversing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.undo, size: 18),
                label: const Text('إلغاء وعكس الفاتورة'),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final colors = context.colors;
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.danger),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(fontSize: 16, color: colors.textPrimary)),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
              ),
              onPressed: _loadPurchase,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    final p = _purchase!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Reversal Banner if reversed
          if (p.isReversed)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.danger),
              ),
              child: Row(
                children: [
                  Icon(Icons.cancel_outlined, color: colors.danger, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'هذه الفاتورة تم إلغاؤها وعكس أثرها المالي والمخزني بالكامل.',
                      style: TextStyle(
                        color: colors.danger,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Header Info Card
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoColumn('رقم الفاتورة', '#${p.invoiceNo}'),
                _buildInfoColumn('المورد', p.supplierName),
                _buildInfoColumn(
                  'تاريخ الشراء',
                  '${p.purchaseDate.year}/${p.purchaseDate.month.toString().padLeft(2, '0')}/${p.purchaseDate.day.toString().padLeft(2, '0')}',
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الحالة', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (p.isConfirmed ? colors.success : colors.danger).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: (p.isConfirmed ? colors.success : colors.danger).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        p.status.arabicTitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: p.isConfirmed ? colors.success : colors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Items Table Card
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    border: Border(bottom: BorderSide(color: colors.border)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 20, color: colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'أصناف الفاتورة',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                DataTable(
                  headingRowColor: WidgetStateProperty.all(colors.surfaceElevated),
                  dataRowColor: WidgetStateProperty.all(colors.surface),
                  headingTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                  columns: const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('اسم المنتج')),
                    DataColumn(label: Text('الكمية')),
                    DataColumn(label: Text('سعر الشراء')),
                    DataColumn(label: Text('الإجمالي')),
                  ],
                  rows: p.items.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    return DataRow(
                      cells: [
                        DataCell(Text('${i + 1}', style: TextStyle(color: colors.textSecondary))),
                        DataCell(Text(item.productName, style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary))),
                        DataCell(Text('${item.quantity} ${item.productUnit}', style: TextStyle(color: colors.textPrimary))),
                        DataCell(Text(item.unitCostAtPurchase.formatted, style: TextStyle(color: colors.textPrimary))),
                        DataCell(
                          Text(
                            item.lineTotal.formatted,
                            style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Financial Summary
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildFinancialRow('إجمالي الفاتورة', p.totalAmount.formatted, isBold: true),
                Divider(height: 24, color: colors.border),
                _buildFinancialRow('المدفوع نقداً', p.paidAmountAtCreation.formatted),
                const SizedBox(height: 10),
                _buildFinancialRow(
                  'المتبقي على الفاتورة (دين للمورد)',
                  p.remainingAmount.formatted,
                  isBold: true,
                  color: p.remainingAmount.piastres > 0 ? colors.danger : colors.success,
                ),
                if (p.note != null && p.note!.isNotEmpty) ...[
                  Divider(height: 24, color: colors.border),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ملاحظات: ', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                      Expanded(child: Text(p.note!, style: TextStyle(color: colors.textSecondary))),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, {Color? color}) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialRow(String label, String value, {bool isBold = false, Color? color}) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: colors.textPrimary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Future<void> _printPurchaseInvoice(Purchase purchase) async {
    try {
      final printService = getIt<PrintService>();
      final items = purchase.items
          .map((i) => {
                'name': i.productName,
                'quantity': i.quantity.toString(),
                'unit': i.productUnit.isNotEmpty ? i.productUnit : 'قطعة',
                'price': i.unitCostAtPurchase.formatted,
                'total': i.lineTotal.formatted,
              })
          .toList();

      await printService.printPurchaseInvoice(
        invoiceNo: purchase.invoiceNo.toString(),
        date: purchase.purchaseDate,
        supplierName: purchase.supplierName.isNotEmpty
            ? purchase.supplierName
            : 'مورد',
        items: items,
        totalAmount: purchase.totalAmount.formatted,
        paidAmount: purchase.paidAmountAtCreation.formatted,
        remainingAmount: purchase.remainingAmount.formatted,
        note: purchase.note,
      );
    } catch (e) {
      if (mounted) {
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
