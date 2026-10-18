import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/money/quantity.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../products/domain/entities/product.dart';
import '../cubit/stock_adjustment_cubit.dart';
import '../cubit/stock_adjustment_state.dart';

class StockAdjustmentDialog extends StatefulWidget {
  final Product? preselectedProduct;
  final List<Product>? availableProducts;
  final VoidCallback? onAdjustmentSuccess;

  const StockAdjustmentDialog({
    super.key,
    this.preselectedProduct,
    this.availableProducts,
    this.onAdjustmentSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    Product? preselectedProduct,
    List<Product>? availableProducts,
    VoidCallback? onAdjustmentSuccess,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BlocProvider(
        create: (context) => StockAdjustmentCubit(
          recordStockAdjustmentUseCase: getIt(),
        ),
        child: StockAdjustmentDialog(
          preselectedProduct: preselectedProduct,
          availableProducts: availableProducts,
          onAdjustmentSuccess: onAdjustmentSuccess,
        ),
      ),
    );
  }

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  final _reasonFocusNode = FocusNode();

  late Product? _selectedProduct;
  bool _isIncrease = false; // Default: decrease (more common in inventory adjustments for waste/deficit)
  Decimal _enteredQuantity = Decimal.zero;

  static const List<String> _decreaseReasons = [
    'عجز جرد دوري',
    'بضاعة تالفة / هالكة',
    'كسر أثناء النقل أو التخزين',
    'عينات ترويجية',
    'تعديل خطأ إدخال سابق',
  ];

  static const List<String> _increaseReasons = [
    'فائض جرد فعلي',
    'بضاعة مرتجعة بدون فاتورة',
    'تدارك خطأ إدخال سابق',
    'هدية ترويجية من المورد',
  ];

  @override
  void initState() {
    super.initState();
    _selectedProduct = widget.preselectedProduct ??
        (widget.availableProducts != null && widget.availableProducts!.isNotEmpty
            ? widget.availableProducts!.first
            : null);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    _reasonFocusNode.dispose();
    super.dispose();
  }

  void _onQuantityChanged(String value) {
    setState(() {
      _enteredQuantity = Decimal.tryParse(value.trim()) ?? Decimal.zero;
    });
  }

  Decimal get _currentStock => _selectedProduct?.currentQuantity ?? Decimal.zero;

  Decimal get _calculatedDelta {
    final absQty = _enteredQuantity.abs();
    return _isIncrease ? absQty : -absQty;
  }

  Decimal get _expectedStockAfter => _currentStock + _calculatedDelta;

  bool get _isNegativeStock => _expectedStockAfter < Decimal.zero;

  bool get _isFormValid {
    if (_selectedProduct == null) return false;
    if (_enteredQuantity <= Decimal.zero) return false;
    if (_isNegativeStock) return false;
    if (_reasonController.text.trim().isEmpty) return false;
    return true;
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || !_isFormValid) return;

    context.read<StockAdjustmentCubit>().submitAdjustment(
          productId: _selectedProduct!.id,
          quantityDelta: _calculatedDelta,
          reason: _reasonController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocListener<StockAdjustmentCubit, StockAdjustmentState>(
      listener: (context, state) {
        if (state is StockAdjustmentSuccess) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: colors.success,
              behavior: SnackBarBehavior.floating,
              width: 500,
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  AppSpacing.horizontalSm,
                  Expanded(
                    child: Text(
                      'تم تسجيل التسوية بنجاح: الرصيد الجديد لـ (${state.movement.productName}) هو ${QuantityHelper.format(state.movement.balanceAfter)} ${state.movement.productUnit}',
                    ),
                  ),
                ],
              ),
            ),
          );
          widget.onAdjustmentSuccess?.call();
        } else if (state is StockAdjustmentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: colors.danger,
              behavior: SnackBarBehavior.floating,
              width: 500,
              content: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.white),
                  AppSpacing.horizontalSm,
                  Expanded(child: Text(state.message)),
                ],
              ),
            ),
          );
        }
      },
      child: Dialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SizedBox(
              height: 680,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                  color: (_isIncrease
                                          ? colors.success
                                          : colors.danger)
                                      .withValues(alpha: 0.15),
                                  borderRadius:
                                      BorderRadius.circular(AppSpacing.radiusSm),
                                ),
                                child: Icon(
                                  _isIncrease
                                      ? Icons.add_circle_outline_rounded
                                      : Icons.remove_circle_outline_rounded,
                                  color: _isIncrease
                                      ? colors.success
                                      : colors.danger,
                                  size: 24,
                                ),
                              ),
                              AppSpacing.horizontalMd,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'تسوية مخزنية يدوية',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'تعديل فوري للرصيد الفعلي مع التوثيق الكامل لسبب الحركة',
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
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                          tooltip: AppStrings.cancel,
                        ),
                      ],
                    ),
                    Divider(height: 24, thickness: 1, color: colors.border),

                    // 2. Scrollable Body
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 2.1 Product Selector or Preselected Info Card
                            if (widget.preselectedProduct != null)
                              _buildPreselectedProductCard(context, _selectedProduct!)
                            else
                              _buildProductDropdown(context),

                            AppSpacing.verticalMd,

                            // 2.2 Direction Toggle (Increase vs Decrease)
                            _buildDirectionSelector(context),

                            AppSpacing.verticalMd,

                            // 2.3 Quantity Input
                            TextFormField(
                              controller: _quantityController,
                              autofocus: true,
                              style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*')),
                              ],
                              decoration: InputDecoration(
                                labelText: 'كمية التسوية (${_selectedProduct?.unit ?? 'وحدة'})',
                                labelStyle: TextStyle(color: colors.textSecondary),
                                hintText: 'أدخل الكمية المراد تسويتها...',
                                hintStyle: TextStyle(color: colors.textMuted),
                                prefixIcon: Icon(
                                  _isIncrease ? Icons.add_rounded : Icons.remove_rounded,
                                  color: _isIncrease
                                      ? colors.success
                                      : colors.danger,
                                ),
                                helperText: 'أدخل القيمة موجبة وسيتكفل النظام باتجاه الحركة',
                                helperStyle: TextStyle(color: colors.textSecondary),
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
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) =>
                                  _reasonFocusNode.requestFocus(),
                              onChanged: _onQuantityChanged,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'يرجى إدخال كمية التسوية';
                                }
                                final dec = Decimal.tryParse(val.trim());
                                if (dec == null || dec <= Decimal.zero) {
                                  return 'يجب إدخال كمية أكبر من صفر';
                                }
                                if (_isNegativeStock) {
                                  return 'الكمية تتجاوز الرصيد الحالي المتاح!';
                                }
                                return null;
                              },
                            ),

                            AppSpacing.verticalMd,

                            // 2.4 Live Preview Card (Zero-Surprise)
                            _buildLivePreviewCard(context),

                            AppSpacing.verticalMd,

                            // 2.5 Reason Input & Quick Chips
                            Text(
                              'سبب التسوية (إلزامي)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                            AppSpacing.verticalXs,
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: (_isIncrease
                                      ? _increaseReasons
                                      : _decreaseReasons)
                                  .map((reason) {
                                return ActionChip(
                                  label: Text(reason,
                                      style: TextStyle(fontSize: 11, color: colors.textPrimary)),
                                  backgroundColor: colors.surfaceElevated,
                                  side: BorderSide(color: colors.border),
                                  avatar: Icon(Icons.bolt_rounded,
                                      size: 14, color: colors.primary),
                                  onPressed: () {
                                    _reasonController.text = reason;
                                    setState(() {});
                                  },
                                );
                              }).toList(),
                            ),
                            AppSpacing.verticalSm,
                            TextFormField(
                              controller: _reasonController,
                              focusNode: _reasonFocusNode,
                              maxLines: 2,
                              style: TextStyle(color: colors.textPrimary),
                              decoration: InputDecoration(
                                hintText:
                                    'اكتب سبب التسوية أو اختر من الأسباب السريعة أعلاه...',
                                hintStyle: TextStyle(color: colors.textMuted),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  child: Icon(Icons.edit_note_rounded, color: colors.textSecondary),
                                ),
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
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              onChanged: (_) => setState(() {}),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'سبب التسوية مطلوب لضمان دقة الرقابة والتدقيق';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    AppSpacing.verticalMd,
                    Divider(height: 1, thickness: 1, color: colors.border),
                    AppSpacing.verticalMd,

                    // 3. Footer Action Buttons
                    BlocBuilder<StockAdjustmentCubit, StockAdjustmentState>(
                      builder: (context, state) {
                        final isSubmitting = state is StockAdjustmentSubmitting;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colors.textPrimary,
                                side: BorderSide(color: colors.border),
                              ),
                              onPressed: isSubmitting
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              child: const Text(AppStrings.cancel),
                            ),
                            AppSpacing.horizontalMd,
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isIncrease
                                    ? colors.success
                                    : colors.danger,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed:
                                  (isSubmitting || !_isFormValid) ? null : _submit,
                              icon: isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check_rounded),
                              label: Text(
                                isSubmitting
                                    ? 'جارٍ الحفظ...'
                                    : (_isIncrease
                                        ? 'تأكيد إضافة الرصيد'
                                        : 'تأكيد خصم الرصيد'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreselectedProductCard(BuildContext context, Product product) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.primaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2_rounded,
              color: colors.primary, size: 28),
          AppSpacing.horizontalMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  'كود: ${product.code ?? "—"} · الرصيد الحالي المسجل: ${QuantityHelper.format(product.currentQuantity)} ${product.unit}',
                  style: TextStyle(
                      fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDropdown(BuildContext context) {
    final colors = context.colors;
    final products = widget.availableProducts ?? [];

    return DropdownButtonFormField<Product>(
      value: _selectedProduct,
      dropdownColor: colors.surfaceElevated,
      style: TextStyle(color: colors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'الصنف المراد تسويته',
        labelStyle: TextStyle(color: colors.textSecondary),
        prefixIcon: Icon(Icons.search_rounded, color: colors.primary),
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
      items: products.map((p) {
        return DropdownMenuItem<Product>(
          value: p,
          child: Text(
            '${p.name} (رصيده: ${QuantityHelper.format(p.currentQuantity)} ${p.unit})',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (product) {
        setState(() {
          _selectedProduct = product;
        });
      },
      validator: (val) => val == null ? 'يرجى اختيار الصنف' : null,
    );
  }

  Widget _buildDirectionSelector(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              onTap: () => setState(() => _isIncrease = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: !_isIncrease ? colors.danger : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.remove_circle_outline_rounded,
                      size: 18,
                      color: !_isIncrease ? Colors.white : colors.danger,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'خصم (عجز / تالف)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              !_isIncrease ? Colors.white : colors.textPrimary,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              onTap: () => setState(() => _isIncrease = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: _isIncrease ? colors.success : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline_rounded,
                      size: 18,
                      color: _isIncrease ? Colors.white : colors.success,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'إضافة (فائض جرد)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              _isIncrease ? Colors.white : colors.textPrimary,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreviewCard(BuildContext context) {
    final colors = context.colors;
    final unit = _selectedProduct?.unit ?? 'وحدة';
    final isNegative = _isNegativeStock;

    final containerColor = isNegative
        ? colors.danger.withValues(alpha: 0.12)
        : (_isIncrease
            ? colors.success.withValues(alpha: 0.12)
            : colors.primaryLight);
    final borderColor = isNegative
        ? colors.danger
        : (_isIncrease
            ? colors.success.withValues(alpha: 0.4)
            : colors.primary.withValues(alpha: 0.4));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'المعاينة الفورية للأثر على المخزون:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'الأثر بعد الحفظ',
                style: TextStyle(
                  fontSize: 11,
                  color: isNegative ? colors.danger : colors.textSecondary,
                  fontWeight: isNegative ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          AppSpacing.verticalSm,
          Row(
            children: [
              _buildPreviewItem(
                context: context,
                label: 'الرصيد الحالي',
                value: '${QuantityHelper.format(_currentStock)} $unit',
                color: colors.textPrimary,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 16, color: colors.textMuted),
              ),
              _buildPreviewItem(
                context: context,
                label: 'مقدار التسوية',
                value:
                    '${_isIncrease ? '+' : '-'} ${QuantityHelper.format(_enteredQuantity)} $unit',
                color: _isIncrease ? colors.success : colors.danger,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.double_arrow_rounded,
                    size: 16, color: colors.textMuted),
              ),
              _buildPreviewItem(
                context: context,
                label: 'الرصيد النهائي',
                value: '${QuantityHelper.format(_expectedStockAfter)} $unit',
                color: isNegative
                    ? colors.danger
                    : (_isIncrease ? colors.success : colors.primary),
                isHighlighted: true,
              ),
            ],
          ),
          if (isNegative) ...[
            AppSpacing.verticalSm,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colors.danger,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'حظر صارم: لا يمكن إنقاص المخزون بالسالب نهائياً وفق ميثاق النظام',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewItem({
    required BuildContext context,
    required String label,
    required String value,
    required Color color,
    bool isHighlighted = false,
  }) {
    final colors = context.colors;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: colors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isHighlighted ? 15 : 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
