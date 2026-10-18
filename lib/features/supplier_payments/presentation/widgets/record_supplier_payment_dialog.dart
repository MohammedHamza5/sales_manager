import 'package:flutter/material.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/money/money.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../suppliers/domain/entities/supplier.dart';
import '../../../suppliers/domain/repositories/supplier_repository.dart';
import '../../data/daos/supplier_payments_dao.dart';
import '../cubit/supplier_payments_cubit.dart';

class RecordSupplierPaymentDialog extends StatefulWidget {
  final SupplierPaymentsCubit cubit;
  final int? preselectedSupplierId;

  const RecordSupplierPaymentDialog({
    super.key,
    required this.cubit,
    this.preselectedSupplierId,
  });

  static Future<void> show(
    BuildContext context,
    SupplierPaymentsCubit cubit, {
    int? preselectedSupplierId,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RecordSupplierPaymentDialog(
        cubit: cubit,
        preselectedSupplierId: preselectedSupplierId,
      ),
    );
  }

  @override
  State<RecordSupplierPaymentDialog> createState() =>
      _RecordSupplierPaymentDialogState();
}

class _RecordSupplierPaymentDialogState
    extends State<RecordSupplierPaymentDialog> {
  final _formKey = GlobalKey<FormState>();

  Supplier? _selectedSupplier;
  List<Supplier> _suppliers = [];
  List<PurchaseEntry> _unpaidPurchases = [];
  int? _selectedLinkedPurchaseId;

  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  DateTime _paymentDate = DateTime.now();
  bool _isLoadingSuppliers = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    final supplierRepo = getIt<SupplierRepository>();
    final result = await supplierRepo.getSuppliers();
    if (result.isSuccess) {
      final activeList = result.dataOrNull!.where((s) => s.isActive).toList();
      setState(() {
        _suppliers = activeList;
        _isLoadingSuppliers = false;
        if (widget.preselectedSupplierId != null) {
          _selectedSupplier = activeList.firstWhere(
            (s) => s.id == widget.preselectedSupplierId,
            orElse: () => activeList.first,
          );
          _loadUnpaidPurchases(_selectedSupplier!.id);
        }
      });
    } else {
      setState(() => _isLoadingSuppliers = false);
    }
  }

  Future<void> _loadUnpaidPurchases(int supplierId) async {
    final dao = getIt<SupplierPaymentsDao>();
    final purchases = await dao.getUnpaidPurchasesForSupplier(supplierId);
    setState(() {
      _unpaidPurchases = purchases;
      _selectedLinkedPurchaseId = null;
    });
  }

  Money get _enteredAmount {
    return Money.tryParse(_amountController.text) ?? Money.zero;
  }

  int get _calculatedBalanceAfter {
    if (_selectedSupplier == null) return 0;
    return _selectedSupplier!.currentBalance.piastres - _enteredAmount.piastres;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedSupplier == null) return;

    final colors = context.colors;
    setState(() => _isSubmitting = true);

    final res = await widget.cubit.recordPayment(
      supplierId: _selectedSupplier!.id,
      amount: _enteredAmount,
      paymentDate: _paymentDate,
      linkedPurchaseId: _selectedLinkedPurchaseId,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res.isSuccess) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم تسجيل سند سداد المورد بنجاح وخصم المبلغ من الخزينة'),
          backgroundColor: colors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.failureOrNull?.message ?? 'فشل في تسجيل السداد'),
          backgroundColor: colors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: _isLoadingSuppliers
              ? const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: colors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.outbox_rounded,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              'تسجيل سند صرف / سداد لمورد',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(Icons.close, color: colors.textSecondary),
                          ),
                        ],
                      ),
                      Divider(height: 32, color: colors.border),

                      // Supplier Selection
                      DropdownButtonFormField<Supplier>(
                        value: _selectedSupplier,
                        dropdownColor: colors.surfaceElevated,
                        style: TextStyle(color: colors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'المورد *',
                          labelStyle: TextStyle(color: colors.textSecondary),
                          prefixIcon: Icon(Icons.business_outlined, color: colors.primary),
                          filled: true,
                          fillColor: colors.surfaceElevated,
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
                        ),
                        items: _suppliers.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text('${s.name} (${s.phone ?? "بدون هاتف"})'),
                          );
                        }).toList(),
                        onChanged: (s) {
                          if (s != null) {
                            setState(() => _selectedSupplier = s);
                            _loadUnpaidPurchases(s.id);
                          }
                        },
                        validator: (v) => v == null ? 'يرجى اختيار المورد' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Supplier Current Dues Preview
                      if (_selectedSupplier != null)
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: colors.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'مستحقات المورد الحالية:',
                                style: TextStyle(color: colors.textSecondary),
                              ),
                              Text(
                                _selectedSupplier!.currentBalance.formatted,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _selectedSupplier!.currentBalance.piastres > 0
                                      ? colors.danger
                                      : colors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: AppSpacing.md),

                      // Amount Input
                      TextFormField(
                        controller: _amountController,
                        style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'المبلغ المسدد (ج.م) *',
                          labelStyle: TextStyle(color: colors.textSecondary),
                          prefixIcon: Icon(Icons.attach_money, color: colors.primary),
                          filled: true,
                          fillColor: colors.surfaceElevated,
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
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'يرجى إدخال المبلغ';
                          }
                          final num = double.tryParse(val.trim());
                          if (num == null || num <= 0) {
                            return 'أدخل مبلغاً صحيحاً أكبر من صفر';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Payment Date Picker
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: colors.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 20, color: colors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'تاريخ السداد: ${_paymentDate.year}-${_paymentDate.month.toString().padLeft(2, '0')}-${_paymentDate.day.toString().padLeft(2, '0')}',
                                style: TextStyle(color: colors.textPrimary),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _paymentDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (picked != null) {
                                  setState(() => _paymentDate = picked);
                                }
                              },
                              style: TextButton.styleFrom(foregroundColor: colors.primary),
                              child: const Text('تغيير التاريخ'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Linked Purchase (Optional)
                      if (_unpaidPurchases.isNotEmpty)
                        DropdownButtonFormField<int?>(
                          value: _selectedLinkedPurchaseId,
                          dropdownColor: colors.surfaceElevated,
                          style: TextStyle(color: colors.textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'ربط بفاتورة شراء غير مسددة (اختياري)',
                            labelStyle: TextStyle(color: colors.textSecondary),
                            prefixIcon: Icon(Icons.receipt_outlined, color: colors.primary),
                            filled: true,
                            fillColor: colors.surfaceElevated,
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
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('بدون ربط بفاتورة محددة (سداد عام)'),
                            ),
                            ..._unpaidPurchases.map((p) {
                              final rem = Money(p.totalAmount - p.paidAmountAtCreation);
                              return DropdownMenuItem(
                                value: p.id,
                                child: Text(
                                  'فاتورة شراء #${p.invoiceNo} (المتبقي: ${rem.formatted})',
                                ),
                              );
                            }),
                          ],
                          onChanged: (id) => setState(() => _selectedLinkedPurchaseId = id),
                        ),
                      if (_unpaidPurchases.isNotEmpty)
                        const SizedBox(height: AppSpacing.md),

                      // Note Input
                      TextFormField(
                        controller: _noteController,
                        style: TextStyle(color: colors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'ملاحظات / رقم إيصال الصرف أو السند',
                          labelStyle: TextStyle(color: colors.textSecondary),
                          prefixIcon: Icon(Icons.note_alt_outlined, color: colors.textSecondary),
                          filled: true,
                          fillColor: colors.surfaceElevated,
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
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Live Balance After Preview (Zero-Surprise)
                      if (_selectedSupplier != null)
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: colors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'المتبقي للمورد بعد هذا السداد:',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                Money(_calculatedBalanceAfter).formatted,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xl),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.textPrimary,
                              side: BorderSide(color: colors.border),
                            ),
                            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                            child: const Text('إلغاء'),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: colors.onPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _isSubmitting ? null : _submit,
                            icon: _isSubmitting
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colors.onPrimary,
                                    ),
                                  )
                                : const Icon(Icons.check),
                            label: const Text('تأكيد الصرف والخصم من الخزينة'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
