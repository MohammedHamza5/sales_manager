import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/money/money.dart';
import '../../../../core/result/result.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubit/expenses_cubit.dart';

class RecordExpenseDialog extends StatefulWidget {
  final ExpensesCubit cubit;

  const RecordExpenseDialog({
    super.key,
    required this.cubit,
  });

  static Future<bool?> show(BuildContext context, ExpensesCubit cubit) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RecordExpenseDialog(cubit: cubit),
    );
  }

  @override
  State<RecordExpenseDialog> createState() => _RecordExpenseDialogState();
}

class _RecordExpenseDialogState extends State<RecordExpenseDialog> {
  final _formKey = GlobalKey<FormState>();

  final List<String> _predefinedCategories = [
    'بوفيه وضيافة',
    'كهرباء ومياه',
    'إيجار',
    'مرتبات وأجور',
    'نقل وشحن',
    'صيانة ونظافة',
    'أدوات ومهمات',
    'متنوعات',
  ];

  late String _selectedCategory;
  bool _isCustomCategory = false;

  late final TextEditingController _customCategoryController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  final _amountFocusNode = FocusNode();
  final _customCategoryFocusNode = FocusNode();
  final _noteFocusNode = FocusNode();

  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _predefinedCategories.first;
    _customCategoryController = TextEditingController();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _customCategoryController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _amountFocusNode.dispose();
    _customCategoryFocusNode.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    final parsedAmount = Money.tryParse(_amountController.text);
    if (parsedAmount == null || parsedAmount.piastres <= 0) {
      _showFeedback('يرجى إدخال مبلغ صحيح أكبر من الصفر', isError: true);
      return;
    }

    final category = _isCustomCategory
        ? _customCategoryController.text.trim()
        : _selectedCategory.trim();

    if (category.isEmpty) {
      _showFeedback('يرجى تحديد أو كتابة بند المصروف', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await widget.cubit.recordExpense(
      category: category,
      amount: parsedAmount,
      expenseDate: _selectedDate,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    if (!mounted) return;

    switch (result) {
      case Success(data: final expense):
        Navigator.of(context).pop(true);
        _showFeedback('تم تسجيل مصروف ${expense.category} بقيمة ${expense.amount.formatArabic()} بنجاح');
      case FailureResult(failure: final failure):
        setState(() => _isSubmitting = false);
        _showFeedback(failure.message, isError: true);
    }
  }

  void _showFeedback(String message, {bool isError = false}) {
    final colors = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? colors.danger : colors.success,
        behavior: SnackBarBehavior.floating,
        width: 480,
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
            ),
            AppSpacing.horizontalSm,
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      helpText: 'اختر تاريخ المصروف',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: colors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 660),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colors.danger.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              border: Border.all(color: colors.danger.withValues(alpha: 0.25)),
                            ),
                            child: Icon(
                              Icons.receipt_long_rounded,
                              color: colors.danger,
                              size: 24,
                            ),
                          ),
                          AppSpacing.horizontalMd,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تسجيل مصروف نقدي',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'سيتم خصم المبلغ من رصيد الخزينة فورياً وتوثيق الحركة',
                                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                      icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                      tooltip: AppStrings.cancel,
                    ),
                  ],
                ),
                Divider(height: 24, thickness: 1, color: colors.border),

                // 2. Form Fields
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Quick category chips
                        Text(
                          'بند المصروف *',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        AppSpacing.verticalXs,
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ..._predefinedCategories.map((cat) {
                              final isSelected = !_isCustomCategory && _selectedCategory == cat;
                              return ChoiceChip(
                                label: Text(cat),
                                selected: isSelected,
                                selectedColor: colors.primary,
                                backgroundColor: colors.surfaceElevated,
                                side: BorderSide(
                                  color: isSelected ? colors.primary : colors.border,
                                ),
                                labelStyle: TextStyle(
                                  color: isSelected ? colors.onPrimary : colors.textPrimary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12,
                                ),
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(() {
                                      _isCustomCategory = false;
                                      _selectedCategory = cat;
                                    });
                                    _amountFocusNode.requestFocus();
                                  }
                                },
                              );
                            }),
                            ChoiceChip(
                              label: const Text('بند آخر...'),
                              selected: _isCustomCategory,
                              selectedColor: colors.primary,
                              backgroundColor: colors.surfaceElevated,
                              side: BorderSide(
                                color: _isCustomCategory ? colors.primary : colors.border,
                              ),
                              labelStyle: TextStyle(
                                color: _isCustomCategory ? colors.onPrimary : colors.textPrimary,
                                fontWeight: _isCustomCategory ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                              onSelected: (sel) {
                                setState(() {
                                  _isCustomCategory = true;
                                });
                                _customCategoryFocusNode.requestFocus();
                              },
                            ),
                          ],
                        ),
                        if (_isCustomCategory) ...[
                          AppSpacing.verticalSm,
                          TextFormField(
                            controller: _customCategoryController,
                            focusNode: _customCategoryFocusNode,
                            style: TextStyle(color: colors.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'اكتب اسم البند المخصص *',
                              hintText: 'مثال: رسوم تجديد رخصة، ضيافة وفد...',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => _amountFocusNode.requestFocus(),
                            validator: (val) {
                              if (_isCustomCategory && (val == null || val.trim().isEmpty)) {
                                return 'يرجى كتابة اسم البند المخصص';
                              }
                              return null;
                            },
                          ),
                        ],
                        AppSpacing.verticalMd,

                        // Amount field
                        TextFormField(
                          controller: _amountController,
                          focusNode: _amountFocusNode,
                          autofocus: true,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            labelText: 'مبلغ المصروف (ج.م) *',
                            hintText: '0.00',
                            prefixIcon: Icon(Icons.money_rounded),
                            suffixText: 'ج.م',
                          ),
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => _noteFocusNode.requestFocus(),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'يرجى إدخال مبلغ المصروف';
                            }
                            final money = Money.tryParse(val);
                            if (money == null || money.piastres <= 0) {
                              return 'المبلغ يجب أن يكون رقماً موجباً أكبر من الصفر';
                            }
                            return null;
                          },
                        ),
                        AppSpacing.verticalMd,

                        // Date picker row
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: colors.border),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  alignment: Alignment.centerRight,
                                ),
                                icon: Icon(Icons.calendar_month_rounded, size: 20, color: colors.primary),
                                label: Text(
                                  'تاريخ المصروف: ${dateFormat.format(_selectedDate)}',
                                  style: TextStyle(fontSize: 13, color: colors.textPrimary),
                                ),
                                onPressed: _pickDate,
                              ),
                            ),
                            AppSpacing.horizontalSm,
                            TextButton(
                              style: TextButton.styleFrom(foregroundColor: colors.primary),
                              onPressed: () {
                                setState(() => _selectedDate = DateTime.now());
                              },
                              child: const Text('اليوم'),
                            ),
                          ],
                        ),
                        AppSpacing.verticalMd,

                        // Note / Details
                        TextFormField(
                          controller: _noteController,
                          focusNode: _noteFocusNode,
                          maxLines: 2,
                          style: TextStyle(color: colors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'البيان / ملاحظات توضيحية (اختياري)',
                            hintText: 'مثال: شراء شاي وسكر للبوفيه، فاتورة صيانة تكييف المحل...',
                            prefixIcon: Icon(Icons.edit_note_rounded),
                          ),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                      ],
                    ),
                  ),
                ),
                AppSpacing.verticalLg,

                // 3. Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colors.border),
                        foregroundColor: colors.textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Text(AppStrings.cancel),
                    ),
                    AppSpacing.horizontalMd,
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(_isSubmitting ? 'جاري الحفظ والخصم...' : 'تسجيل المصروف'),
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
