import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/money/money.dart';
import '../../../../core/money/quantity.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/usecases/get_products_usecase.dart';
import '../../../suppliers/domain/entities/supplier.dart';
import '../../../suppliers/domain/usecases/get_suppliers_usecase.dart';
import '../../domain/repositories/return_repository.dart';
import '../cubit/returns_cubit.dart';

class SupplierReturnDialog extends StatefulWidget {
  final ReturnsCubit cubit;

  const SupplierReturnDialog({super.key, required this.cubit});

  static Future<void> show(BuildContext context, ReturnsCubit cubit) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SupplierReturnDialog(cubit: cubit),
    );
  }

  @override
  State<SupplierReturnDialog> createState() => _SupplierReturnDialogState();
}

class _SupplierReturnDialogState extends State<SupplierReturnDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController(text: '0.00');
  final _noteController = TextEditingController();

  List<Supplier> _suppliers = [];
  List<Product> _products = [];
  bool _isLoadingLookups = true;
  bool _isSubmitting = false;

  int? _selectedSupplierId;
  Product? _selectedProduct;
  final DateTime _returnDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    final supRes = await getIt<GetSuppliersUseCase>()(isActiveOnly: true);
    final prodRes = await getIt<GetProductsUseCase>()(isActiveOnly: true);

    if (mounted) {
      setState(() {
        _suppliers = supRes.dataOrNull ?? [];
        _products = prodRes.dataOrNull ?? [];
        _isLoadingLookups = false;
      });
    }
  }

  Money get _lineTotal {
    final qty = Decimal.tryParse(_quantityController.text) ?? Decimal.zero;
    final price = Money.tryParse(_priceController.text) ?? Money.zero;
    return price.multiplyByQuantity(qty);
  }

  bool get _isOverselling {
    if (_selectedProduct == null) return false;
    final qty = Decimal.tryParse(_quantityController.text) ?? Decimal.zero;
    return qty > _selectedProduct!.currentQuantity;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.assignment_return_outlined, color: colors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Text(AppStrings.newSupplierReturn, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
        ],
      ),
      content: _isLoadingLookups
          ? SizedBox(
              height: 150,
              width: 450,
              child: Center(child: CircularProgressIndicator(color: colors.primary)),
            )
          : SizedBox(
              width: 500,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Supplier Dropdown
                      DropdownButtonFormField<int>(
                        value: _selectedSupplierId,
                        dropdownColor: colors.surface,
                        style: TextStyle(color: colors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'المورد *',
                          labelStyle: TextStyle(color: colors.textSecondary),
                          prefixIcon: Icon(Icons.business_outlined, color: colors.primary),
                          filled: true,
                          fillColor: colors.surfaceElevated,
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
                        items: _suppliers.map((s) {
                          return DropdownMenuItem<int>(
                            value: s.id,
                            child: Text(
                              '${s.name} (${s.currentBalance.formatArabic()})',
                              style: TextStyle(color: colors.textPrimary),
                            ),
                          );
                        }).toList(),
                        validator: (val) => val == null ? 'يرجى اختيار المورد' : null,
                        onChanged: (val) => setState(() => _selectedSupplierId = val),
                      ),
                      AppSpacing.verticalMd,

                      // Product Autocomplete
                      Autocomplete<Product>(
                        displayStringForOption: (p) =>
                            '${p.name} - متاح: ${QuantityHelper.format(p.currentQuantity, unit: p.unit)} - ${p.currentPurchasePrice.formatArabic()}',
                        optionsBuilder: (textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<Product>.empty();
                          }
                          final q = textEditingValue.text.toLowerCase();
                          return _products.where((p) =>
                              p.name.toLowerCase().contains(q) ||
                              (p.code?.toLowerCase().contains(q) ?? false));
                        },
                        onSelected: (p) {
                          setState(() {
                            _selectedProduct = p;
                            _priceController.text =
                                (p.currentPurchasePrice.piastres / 100.0).toStringAsFixed(2);
                          });
                        },
                        fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            style: TextStyle(color: colors.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'ابحث عن المنتج المراد إرجاعه *',
                              labelStyle: TextStyle(color: colors.textSecondary),
                              prefixIcon: Icon(Icons.inventory_2_outlined, color: colors.primary),
                              filled: true,
                              fillColor: colors.surfaceElevated,
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
                            validator: (_) =>
                                _selectedProduct == null ? 'يرجى اختيار المنتج' : null,
                          );
                        },
                      ),
                      AppSpacing.verticalMd,

                      // Quantity and Price Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _quantityController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: TextStyle(color: colors.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'الكمية المرتجعة *',
                                labelStyle: TextStyle(color: colors.textSecondary),
                                filled: true,
                                fillColor: colors.surfaceElevated,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: colors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: colors.primary),
                                ),
                                isDense: true,
                                errorText: _isOverselling ? 'تتجاوز الرصيد المتاح بالمخزن!' : null,
                              ),
                              validator: (val) {
                                final d = Decimal.tryParse(val ?? '');
                                if (d == null || d <= Decimal.zero) return 'كمية غير صحيحة';
                                if (_selectedProduct != null && d > _selectedProduct!.currentQuantity) {
                                  return 'تتجاوز الرصيد المتاح بالمخزن';
                                }
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          AppSpacing.horizontalMd,
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: TextStyle(color: colors.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'سعر الوحدة (ج.م) *',
                                labelStyle: TextStyle(color: colors.textSecondary),
                                filled: true,
                                fillColor: colors.surfaceElevated,
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
                              validator: (val) {
                                final m = Money.tryParse(val ?? '');
                                if (m == null || m.piastres < 0) return 'سعر غير صحيح';
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.verticalMd,

                      // Note field
                      TextFormField(
                        controller: _noteController,
                        style: TextStyle(color: colors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'سبب الإرجاع / ملاحظات (اختياري)',
                          labelStyle: TextStyle(color: colors.textSecondary),
                          filled: true,
                          fillColor: colors.surfaceElevated,
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
                      ),
                      AppSpacing.verticalMd,

                      // Zero-Surprise Live Preview
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: colors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('قيمة المرتجع للمورد:', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                                Text(
                                  _lineTotal.formatArabic(),
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colors.primary),
                                ),
                              ],
                            ),
                            AppSpacing.verticalXs,
                            Text(
                              '• سيتم خصم الكمية من المخزون فورياً.',
                              style: TextStyle(fontSize: 12, color: colors.danger),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '• سيتم تخفيض مستحقات المورد بمبلغ ${_lineTotal.formatArabic()}.',
                              style: TextStyle(fontSize: 12, color: colors.success, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.textPrimary,
            side: BorderSide(color: colors.border),
          ),
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
          ),
          onPressed: _isSubmitting || _isOverselling ? null : _submit,
          child: _isSubmitting
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: colors.onPrimary),
                )
              : const Text(AppStrings.save),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplierId == null || _selectedProduct == null || _isOverselling) return;

    setState(() => _isSubmitting = true);

    final qty = Decimal.parse(_quantityController.text.trim());
    final price = Money.tryParse(_priceController.text.trim()) ?? Money.zero;

    final params = CreateSupplierReturnParams(
      supplierId: _selectedSupplierId!,
      returnDate: _returnDate,
      items: [
        ReturnItemParam(
          productId: _selectedProduct!.id,
          quantity: qty,
          unitPrice: price,
        ),
      ],
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    final result = await widget.cubit.submitSupplierReturn(params);

    if (mounted) {
      final colors = context.colors;
      setState(() => _isSubmitting = false);
      result.fold(
        onSuccess: (ret) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم تسجيل مرتجع المورد بنجاح (#${ret.id})'),
              backgroundColor: colors.success,
            ),
          );
        },
        onFailure: (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: colors.danger,
            ),
          );
        },
      );
    }
  }
}
