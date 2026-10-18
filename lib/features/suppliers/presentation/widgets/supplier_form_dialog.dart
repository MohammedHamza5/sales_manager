import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/money/money.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/supplier.dart';
import '../cubit/suppliers_cubit.dart';

class SupplierFormDialog extends StatefulWidget {
  final SuppliersCubit cubit;
  final Supplier? supplier;

  const SupplierFormDialog({
    super.key,
    required this.cubit,
    this.supplier,
  });

  static Future<void> show(
    BuildContext context,
    SuppliersCubit cubit, [
    Supplier? supplier,
  ]) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SupplierFormDialog(
        cubit: cubit,
        supplier: supplier,
      ),
    );
  }

  @override
  State<SupplierFormDialog> createState() => _SupplierFormDialogState();
}

class _SupplierFormDialogState extends State<SupplierFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;
  late final TextEditingController _initialBalanceController;

  final _phoneFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();
  final _balanceFocusNode = FocusNode();
  final _notesFocusNode = FocusNode();

  bool _isSubmitting = false;

  bool get _isEditing => widget.supplier != null;

  @override
  void initState() {
    super.initState();
    final s = widget.supplier;
    _nameController = TextEditingController(text: s?.name ?? '');
    _phoneController = TextEditingController(text: s?.phone ?? '');
    _addressController = TextEditingController(text: s?.address ?? '');
    _notesController = TextEditingController(text: s?.notes ?? '');
    _initialBalanceController = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _initialBalanceController.dispose();

    _phoneFocusNode.dispose();
    _addressFocusNode.dispose();
    _balanceFocusNode.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      if (_isEditing) {
        final updated = widget.supplier!.copyWith(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );

        final result = await widget.cubit.updateSupplier(updated);
        if (!mounted) return;

        if (result.isSuccess) {
          Navigator.of(context).pop();
          _showFeedback('تم تعديل بيانات المورد بنجاح', isError: false);
        } else {
          setState(() => _isSubmitting = false);
          _showFeedback(result.failureOrNull?.message ?? 'فشل في تعديل البيانات', isError: true);
        }
      } else {
        final parsedBalance = Money.tryParse(_initialBalanceController.text) ?? Money.zero;

        final result = await widget.cubit.addSupplier(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          initialBalance: parsedBalance,
        );

        if (!mounted) return;

        if (result.isSuccess) {
          Navigator.of(context).pop();
          _showFeedback('تم تسجيل المورد الجديد بنجاح', isError: false);
        } else {
          setState(() => _isSubmitting = false);
          _showFeedback(result.failureOrNull?.message ?? 'فشل في حفظ المورد', isError: true);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showFeedback('حدث خطأ غير متوقع: $e', isError: true);
    }
  }

  void _showFeedback(String message, {required bool isError}) {
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
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
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
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SizedBox(
            height: _isEditing ? 460 : 540,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _isEditing ? Icons.local_shipping_rounded : Icons.local_shipping_outlined,
                              color: colors.primary,
                              size: 24,
                            ),
                          ),
                          AppSpacing.horizontalMd,
                          Text(
                            _isEditing ? 'تعديل بيانات المورد' : 'تسجيل مورد جديد',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                        tooltip: AppStrings.cancel,
                      ),
                    ],
                  ),
                  Divider(height: 24, thickness: 1, color: colors.border),

                  // 2. Scrollable Inputs Body
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 2.1 Name Input
                          TextFormField(
                            controller: _nameController,
                            autofocus: true,
                            decoration: const InputDecoration(
                              labelText: 'اسم المورد أو الشركة *',
                              hintText: 'مثال: شركة النصر للتوريدات، الحاج محمد...',
                              prefixIcon: Icon(Icons.business_outlined),
                            ),
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => _phoneFocusNode.requestFocus(),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'اسم المورد مطلوب ولا يمكن تركه فارغاً';
                              }
                              return null;
                            },
                          ),
                          AppSpacing.verticalMd,

                          // 2.2 Phone Input
                          TextFormField(
                            controller: _phoneController,
                            focusNode: _phoneFocusNode,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'رقم الهاتف (اختياري)',
                              hintText: 'مثال: 01012345678',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => _addressFocusNode.requestFocus(),
                            validator: (val) {
                              if (val != null && val.trim().isNotEmpty) {
                                if (!RegExp(r'^[0-9+\-\s]{6,20}$').hasMatch(val.trim())) {
                                  return 'يرجى إدخال رقم هاتف صحيح';
                                }
                              }
                              return null;
                            },
                          ),
                          AppSpacing.verticalMd,

                          // 2.3 Address Input
                          TextFormField(
                            controller: _addressController,
                            focusNode: _addressFocusNode,
                            decoration: const InputDecoration(
                              labelText: 'العنوان / المركز الرئيسي (اختياري)',
                              hintText: 'مثال: المنطقة الصناعية، العبور',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                            textInputAction: _isEditing ? TextInputAction.next : TextInputAction.next,
                            onFieldSubmitted: (_) {
                              if (!_isEditing) {
                                _balanceFocusNode.requestFocus();
                              } else {
                                _notesFocusNode.requestFocus();
                              }
                            },
                          ),
                          AppSpacing.verticalMd,

                          // 2.4 Opening Balance (Only for new supplier)
                          if (!_isEditing) ...[
                            TextFormField(
                              controller: _initialBalanceController,
                              focusNode: _balanceFocusNode,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'رصيد المديونية الافتتاحي للمورد بالجنيه (اختياري)',
                                hintText: '0.00',
                                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                                helperText: 'المبلغ المستحق للمورد علينا قبل بدء العمل بالبرنامج إن وُجد',
                              ),
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => _notesFocusNode.requestFocus(),
                            ),
                            AppSpacing.verticalMd,
                          ],

                          // 2.5 Notes Input
                          TextFormField(
                            controller: _notesController,
                            focusNode: _notesFocusNode,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'ملاحظات إضافية (اختياري)',
                              hintText: 'طرق الدفع المفضلة، أرقام الحسابات البنكية، أو مواعيد التوريد...',
                              prefixIcon: Padding(
                                padding: EdgeInsets.only(bottom: 24),
                                child: Icon(Icons.note_alt_outlined),
                              ),
                            ),
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  AppSpacing.verticalMd,
                  Divider(height: 1, thickness: 1, color: colors.border),
                  AppSpacing.verticalMd,

                  // 3. Footer Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.textPrimary,
                          side: BorderSide(color: colors.border),
                        ),
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                        child: const Text(AppStrings.cancel),
                      ),
                      AppSpacing.horizontalMd,
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                            : const Icon(Icons.check_rounded),
                        label: Text(
                          _isSubmitting
                              ? 'جارٍ الحفظ...'
                              : (_isEditing ? 'حفظ التعديلات' : 'تسجيل المورد'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
