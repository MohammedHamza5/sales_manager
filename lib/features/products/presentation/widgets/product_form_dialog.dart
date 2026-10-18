import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../core/money/money.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/product.dart';
import '../cubit/products_cubit.dart';

class ProductFormDialog extends StatefulWidget {
  final ProductsCubit cubit;
  final Product? productToEdit;

  const ProductFormDialog({
    super.key,
    required this.cubit,
    this.productToEdit,
  });

  static Future<void> show(BuildContext context, ProductsCubit cubit, [Product? productToEdit]) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProductFormDialog(
        cubit: cubit,
        productToEdit: productToEdit,
      ),
    );
  }

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _unitController;
  late final TextEditingController _salePriceController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _initialQuantityController;
  late final TextEditingController _lowStockThresholdController;

  bool _isSubmitting = false;
  String? _errorMessage;

  static const List<String> _quickUnits = [
    'قطعة',
    'كيلو',
    'جرام',
    'علبة',
    'كرتونة',
    'لتر',
    'متر',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;

    _nameController = TextEditingController(text: p?.name ?? '');
    _codeController = TextEditingController(text: p?.code ?? '');
    _unitController = TextEditingController(text: p?.unit ?? 'قطعة');
    _salePriceController = TextEditingController(
      text: p != null ? (p.currentSalePrice.piastres / 100.0).toStringAsFixed(2) : '',
    );
    _purchasePriceController = TextEditingController(
      text: p != null ? (p.currentPurchasePrice.piastres / 100.0).toStringAsFixed(2) : '',
    );
    _initialQuantityController = TextEditingController(text: '0');
    _lowStockThresholdController = TextEditingController(
      text: p?.lowStockThreshold?.toString() ?? '5',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _unitController.dispose();
    _salePriceController.dispose();
    _purchasePriceController.dispose();
    _initialQuantityController.dispose();
    _lowStockThresholdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final colors = context.colors;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final saleMoney = Money.tryParse(_salePriceController.text) ?? Money.zero;
    final purchaseMoney = Money.tryParse(_purchasePriceController.text) ?? Money.zero;
    final lowStock = Decimal.tryParse(_lowStockThresholdController.text.trim());

    if (widget.productToEdit == null) {
      // Adding new product
      final initialQty = Decimal.tryParse(_initialQuantityController.text.trim()) ?? Decimal.zero;

      final result = await widget.cubit.addProduct(
        name: _nameController.text.trim(),
        code: _codeController.text.trim().isEmpty ? null : _codeController.text.trim(),
        unit: _unitController.text.trim(),
        salePrice: saleMoney,
        purchasePrice: purchaseMoney,
        initialQuantity: initialQty,
        lowStockThreshold: lowStock,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.successOperation),
            backgroundColor: colors.success,
          ),
        );
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = result.failureOrNull?.message ?? AppStrings.failureOperation;
        });
      }
    } else {
      // Updating existing product
      final updatedProduct = widget.productToEdit!.copyWith(
        name: _nameController.text.trim(),
        code: _codeController.text.trim().isEmpty ? null : _codeController.text.trim(),
        unit: _unitController.text.trim(),
        currentSalePrice: saleMoney,
        currentPurchasePrice: purchaseMoney,
        lowStockThreshold: lowStock,
      );

      final result = await widget.cubit.updateProduct(updatedProduct);

      if (!mounted) return;

      if (result.isSuccess) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.successOperation),
            backgroundColor: colors.success,
          ),
        );
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = result.failureOrNull?.message ?? AppStrings.failureOperation;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productToEdit != null;
    final colors = context.colors;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dialog Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isEditing ? Icons.edit_note_rounded : Icons.add_box_rounded,
                              color: colors.primary,
                              size: 24,
                            ),
                          ),
                          AppSpacing.horizontalSm,
                          Text(
                            isEditing ? 'تعديل بيانات المنتج' : 'إضافة منتج جديد',
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

                  // Error Banner
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        border: Border.all(color: colors.danger.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: colors.danger, size: 20),
                          AppSpacing.horizontalSm,
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: colors.danger, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.verticalMd,
                  ],

                  // Product Name Field
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'اسم المنتج *',
                      labelStyle: TextStyle(color: colors.textSecondary),
                      hintText: 'مثال: سكر أبيض فاخر 1 كجم',
                      hintStyle: TextStyle(color: colors.textMuted),
                      prefixIcon: Icon(Icons.shopping_bag_outlined, color: colors.primary),
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
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return AppStrings.requiredField;
                      }
                      return null;
                    },
                  ),
                  AppSpacing.verticalMd,

                  // Product Code & Unit
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _codeController,
                          style: TextStyle(color: colors.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'كود / باركود المنتج (اختياري)',
                            labelStyle: TextStyle(color: colors.textSecondary),
                            hintText: 'مثال: 622100123456',
                            hintStyle: TextStyle(color: colors.textMuted),
                            prefixIcon: Icon(Icons.qr_code_2_rounded, color: colors.primary),
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
                      ),
                      AppSpacing.horizontalMd,
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _unitController,
                          style: TextStyle(color: colors.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'وحدة القياس *',
                            labelStyle: TextStyle(color: colors.textSecondary),
                            hintText: 'قطعة',
                            hintStyle: TextStyle(color: colors.textMuted),
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
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return AppStrings.requiredField;
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.verticalXs,

                  // Quick unit selectors
                  Wrap(
                    spacing: 6,
                    children: _quickUnits.map((unit) {
                      return ActionChip(
                        label: Text(
                          unit,
                          style: TextStyle(fontSize: 12, color: colors.textPrimary),
                        ),
                        backgroundColor: colors.surfaceElevated,
                        side: BorderSide(color: colors.border),
                        onPressed: () {
                          setState(() {
                            _unitController.text = unit;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  AppSpacing.verticalMd,

                  // Pricing Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _purchasePriceController,
                          style: TextStyle(color: colors.textPrimary),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'سعر الشراء (ج.م) *',
                            labelStyle: TextStyle(color: colors.textSecondary),
                            hintText: '0.00',
                            hintStyle: TextStyle(color: colors.textMuted),
                            prefixIcon: Icon(Icons.price_change_outlined, color: colors.primary),
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
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return AppStrings.requiredField;
                            final m = Money.tryParse(val);
                            if (m == null || m.piastres < 0) return AppStrings.invalidNumber;
                            return null;
                          },
                        ),
                      ),
                      AppSpacing.horizontalMd,
                      Expanded(
                        child: TextFormField(
                          controller: _salePriceController,
                          style: TextStyle(color: colors.textPrimary),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'سعر البيع (ج.م) *',
                            labelStyle: TextStyle(color: colors.textSecondary),
                            hintText: '0.00',
                            hintStyle: TextStyle(color: colors.textMuted),
                            prefixIcon: Icon(Icons.sell_outlined, color: colors.primary),
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
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return AppStrings.requiredField;
                            final m = Money.tryParse(val);
                            if (m == null || m.piastres < 0) return AppStrings.invalidNumber;
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.verticalMd,

                  // Initial stock (only on create) & Low Stock Alert
                  Row(
                    children: [
                      if (!isEditing) ...[
                        Expanded(
                          child: TextFormField(
                            controller: _initialQuantityController,
                            style: TextStyle(color: colors.textPrimary),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'الرصيد الافتتاحي بالمخزن',
                              labelStyle: TextStyle(color: colors.textSecondary),
                              hintText: '0',
                              hintStyle: TextStyle(color: colors.textMuted),
                              prefixIcon: Icon(Icons.warehouse_outlined, color: colors.primary),
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
                            validator: (val) {
                              if (val != null && val.trim().isNotEmpty) {
                                final d = Decimal.tryParse(val.trim());
                                if (d == null || d < Decimal.zero) return AppStrings.invalidNumber;
                              }
                              return null;
                            },
                          ),
                        ),
                        AppSpacing.horizontalMd,
                      ],
                      Expanded(
                        child: TextFormField(
                          controller: _lowStockThresholdController,
                          style: TextStyle(color: colors.textPrimary),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'حد تنبيه نقص المخزون',
                            labelStyle: TextStyle(color: colors.textSecondary),
                            hintText: '5',
                            hintStyle: TextStyle(color: colors.textMuted),
                            prefixIcon: Icon(Icons.notification_important_outlined, color: colors.warning),
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
                          validator: (val) {
                            if (val != null && val.trim().isNotEmpty) {
                              final d = Decimal.tryParse(val.trim());
                              if (d == null || d < Decimal.zero) return AppStrings.invalidNumber;
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.verticalLg,

                  // Actions Buttons
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
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(colors.onPrimary),
                                ),
                              )
                            : Text(isEditing ? 'حفظ التعديلات' : 'إضافة المنتج'),
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
