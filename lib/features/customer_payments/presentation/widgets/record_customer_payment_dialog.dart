import 'package:flutter/material.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/money/money.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../customers/domain/repositories/customer_repository.dart';
import '../../data/daos/customer_payments_dao.dart';
import '../cubit/customer_payments_cubit.dart';

class RecordCustomerPaymentDialog extends StatefulWidget {
  final CustomerPaymentsCubit cubit;
  final int? preselectedCustomerId;

  const RecordCustomerPaymentDialog({
    super.key,
    required this.cubit,
    this.preselectedCustomerId,
  });

  static Future<void> show(
    BuildContext context,
    CustomerPaymentsCubit cubit, {
    int? preselectedCustomerId,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RecordCustomerPaymentDialog(
        cubit: cubit,
        preselectedCustomerId: preselectedCustomerId,
      ),
    );
  }

  @override
  State<RecordCustomerPaymentDialog> createState() =>
      _RecordCustomerPaymentDialogState();
}

class _RecordCustomerPaymentDialogState
    extends State<RecordCustomerPaymentDialog> {
  final _formKey = GlobalKey<FormState>();

  Customer? _selectedCustomer;
  List<Customer> _customers = [];
  List<SaleEntry> _unpaidSales = [];
  int? _selectedLinkedSaleId;

  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  DateTime _paymentDate = DateTime.now();
  bool _isLoadingCustomers = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
    _loadCustomers();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    final customerRepo = getIt<CustomerRepository>();
    final result = await customerRepo.getCustomers();
    if (result.isSuccess) {
      final activeList = result.dataOrNull!.where((c) => c.isActive).toList();
      setState(() {
        _customers = activeList;
        _isLoadingCustomers = false;
        if (widget.preselectedCustomerId != null) {
          _selectedCustomer = activeList.firstWhere(
            (c) => c.id == widget.preselectedCustomerId,
            orElse: () => activeList.first,
          );
          _loadUnpaidSales(_selectedCustomer!.id);
        }
      });
    } else {
      setState(() => _isLoadingCustomers = false);
    }
  }

  Future<void> _loadUnpaidSales(int customerId) async {
    final dao = getIt<CustomerPaymentsDao>();
    final sales = await dao.getUnpaidSalesForCustomer(customerId);
    setState(() {
      _unpaidSales = sales;
      _selectedLinkedSaleId = null;
    });
  }

  Money get _enteredAmount {
    return Money.tryParse(_amountController.text) ?? Money.zero;
  }

  int get _calculatedBalanceAfter {
    if (_selectedCustomer == null) return 0;
    return _selectedCustomer!.currentBalance.piastres - _enteredAmount.piastres;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCustomer == null) return;

    final colors = context.colors;
    setState(() => _isSubmitting = true);

    final res = await widget.cubit.recordPayment(
      customerId: _selectedCustomer!.id,
      amount: _enteredAmount,
      paymentDate: _paymentDate,
      linkedSaleId: _selectedLinkedSaleId,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res.isSuccess) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم تسجيل سند التحصيل بنجاح وتحديث الحساب والخزينة'),
          backgroundColor: colors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.failureOrNull?.message ?? 'فشل في تسجيل التحصيل'),
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
          child: _isLoadingCustomers
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
                              Icons.payments_outlined,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              'تسجيل سند تحصيل نقدية من عميل',
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

                      // Customer Selection
                      DropdownButtonFormField<Customer>(
                        value: _selectedCustomer,
                        dropdownColor: colors.surfaceElevated,
                        style: TextStyle(color: colors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'العميل *',
                          labelStyle: TextStyle(color: colors.textSecondary),
                          prefixIcon: Icon(Icons.person_outline, color: colors.primary),
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
                        items: _customers.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text('${c.name} (${c.phone ?? "بدون هاتف"})'),
                          );
                        }).toList(),
                        onChanged: (c) {
                          if (c != null) {
                            setState(() => _selectedCustomer = c);
                            _loadUnpaidSales(c.id);
                          }
                        },
                        validator: (v) => v == null ? 'يرجى اختيار العميل' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Customer Current Balance Preview
                      if (_selectedCustomer != null)
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
                                'رصيد المديونية الحالي على العميل:',
                                style: TextStyle(color: colors.textSecondary),
                              ),
                              Text(
                                _selectedCustomer!.currentBalance.formatted,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _selectedCustomer!.currentBalance.piastres > 0
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
                          labelText: 'المبلغ المُحصَّل (ج.م) *',
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
                                'تاريخ التحصيل: ${_paymentDate.year}-${_paymentDate.month.toString().padLeft(2, '0')}-${_paymentDate.day.toString().padLeft(2, '0')}',
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

                      // Linked Sale (Optional)
                      if (_unpaidSales.isNotEmpty)
                        DropdownButtonFormField<int?>(
                          value: _selectedLinkedSaleId,
                          dropdownColor: colors.surfaceElevated,
                          style: TextStyle(color: colors.textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'ربط بفاتورة غير مسددة (اختياري)',
                            labelStyle: TextStyle(color: colors.textSecondary),
                            prefixIcon: Icon(Icons.receipt_long_outlined, color: colors.primary),
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
                              child: Text('بدون ربط بفاتورة محددة (سند عام)'),
                            ),
                            ..._unpaidSales.map((s) {
                              final rem = Money(s.totalAmount - s.paidAmountAtCreation);
                              return DropdownMenuItem(
                                value: s.id,
                                child: Text(
                                  'فاتورة #${s.invoiceNo} (المتبقي: ${rem.formatted})',
                                ),
                              );
                            }),
                          ],
                          onChanged: (id) => setState(() => _selectedLinkedSaleId = id),
                        ),
                      if (_unpaidSales.isNotEmpty)
                        const SizedBox(height: AppSpacing.md),

                      // Note Input
                      TextFormField(
                        controller: _noteController,
                        style: TextStyle(color: colors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'ملاحظات / رقم الشيك أو الإيصال الورقي',
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
                      if (_selectedCustomer != null)
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
                                'المتبقي على العميل بعد هذا السند:',
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
                            label: const Text('تأكيد التحصيل والتوريد للخزينة'),
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
