import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/money/money.dart';
import '../../../../core/money/quantity.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../customers/domain/usecases/get_customers_usecase.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/usecases/get_products_usecase.dart';
import '../../../sales/domain/entities/sale.dart';
import '../../../sales/domain/entities/sale_item.dart';
import '../../../sales/domain/usecases/get_sale_by_id_usecase.dart';
import '../../../sales/domain/usecases/get_sales_usecase.dart';
import '../../domain/repositories/return_repository.dart';
import '../cubit/returns_cubit.dart';

enum ReturnSettlementOption {
  creditToAccount('تنزيل في حساب العميل (خصم دين / رصيد دائن)', 'لا يؤثر على نقدية الخزينة'),
  settleDebtAndCashRest('تسوية دين العميل وصرف المتبقي نقداً', 'يسوي المديونية أولاً ويصرف الباقي كاش'),
  cashRefund('صرف نقدي فوري كامل من الخزينة', 'يخرج كامل المبلغ كاش من الدرج');

  final String title;
  final String subtitle;
  const ReturnSettlementOption(this.title, this.subtitle);
}

class CustomerReturnDialog extends StatefulWidget {
  final ReturnsCubit cubit;

  const CustomerReturnDialog({super.key, required this.cubit});

  static Future<void> show(BuildContext context, ReturnsCubit cubit) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CustomerReturnDialog(cubit: cubit),
    );
  }

  @override
  State<CustomerReturnDialog> createState() => _CustomerReturnDialogState();
}

class _CustomerReturnDialogState extends State<CustomerReturnDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController(text: '0.00');
  final _noteController = TextEditingController();

  List<Customer> _customers = [];
  List<Product> _products = [];
  List<Sale> _customerSales = [];
  bool _isLoadingLookups = true;
  bool _isLoadingSales = false;
  bool _isSubmitting = false;

  int? _selectedCustomerId;
  int? _selectedSaleId;
  Sale? _selectedSale;
  List<SaleItem> _selectedSaleItems = [];
  SaleItem? _selectedSaleItem;
  bool _isLoadingSaleDetails = false;
  Product? _selectedProduct;
  final DateTime _returnDate = DateTime.now();

  ReturnSettlementOption _settlementOption = ReturnSettlementOption.creditToAccount;

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
    final custRes = await getIt<GetCustomersUseCase>()(isActiveOnly: true);
    final prodRes = await getIt<GetProductsUseCase>()(isActiveOnly: true);

    if (mounted) {
      setState(() {
        _customers = custRes.dataOrNull ?? [];
        _products = prodRes.dataOrNull ?? [];
        _isLoadingLookups = false;
      });
    }
  }

  Future<void> _onCustomerChanged(int? customerId) async {
    setState(() {
      _selectedCustomerId = customerId;
      _selectedSaleId = null;
      _selectedSale = null;
      _selectedSaleItems = [];
      _selectedSaleItem = null;
      _selectedProduct = null;
      _priceController.text = '0.00';
      _quantityController.text = '1';
      _customerSales = [];
      _isLoadingSales = customerId != null;
      _isLoadingSaleDetails = false;
    });

    if (customerId != null) {
      final salesRes = await getIt<GetSalesUseCase>()(
        customerId: customerId,
        status: 'confirmed',
      );
      if (mounted && _selectedCustomerId == customerId) {
        setState(() {
          _customerSales = salesRes.dataOrNull ?? [];
          _isLoadingSales = false;
        });
      }
    }
  }

  Future<void> _onSaleChanged(int? saleId) async {
    setState(() {
      _selectedSaleId = saleId;
      _selectedSale = null;
      _selectedSaleItems = [];
      _selectedSaleItem = null;
      _selectedProduct = null;
      _priceController.text = '0.00';
      _quantityController.text = '1';
      _isLoadingSaleDetails = saleId != null;
    });

    if (saleId != null) {
      final saleRes = await getIt<GetSaleByIdUseCase>()(saleId);
      if (mounted && _selectedSaleId == saleId) {
        final sale = saleRes.dataOrNull;
        setState(() {
          _selectedSale = sale;
          _selectedSaleItems = sale?.items ?? [];
          _isLoadingSaleDetails = false;
        });
      }
    }
  }

  List<Product> get _availableProducts {
    if (_selectedSaleId != null) {
      final list = <Product>[];
      for (final item in _selectedSaleItems) {
        final p = _products.where((prod) => prod.id == item.productId).firstOrNull;
        if (p != null) {
          list.add(p);
        } else {
          list.add(Product(
            id: item.productId,
            name: item.productName,
            code: item.productCode.isNotEmpty ? item.productCode : null,
            unit: item.productUnit.isNotEmpty ? item.productUnit : 'قطعة',
            currentSalePrice: item.unitPriceAtSale,
            currentPurchasePrice: Money.zero,
            currentQuantity: item.quantity,
            createdAt: item.createdAt,
          ));
        }
      }
      return list;
    }
    return _products;
  }

  Customer? get _currentCustomer {
    if (_selectedCustomerId == null) return null;
    return _customers.where((c) => c.id == _selectedCustomerId).firstOrNull;
  }

  Money get _lineTotal {
    final qty = Decimal.tryParse(_quantityController.text) ?? Decimal.zero;
    final price = Money.tryParse(_priceController.text) ?? Money.zero;
    return price.multiplyByQuantity(qty);
  }

  Money get _cashRefundAmount {
    final total = _lineTotal;
    final cust = _currentCustomer;

    switch (_settlementOption) {
      case ReturnSettlementOption.creditToAccount:
        return Money.zero;
      case ReturnSettlementOption.cashRefund:
        return total;
      case ReturnSettlementOption.settleDebtAndCashRest:
        if (cust == null || !cust.hasDebt) {
          return total;
        }
        final debt = cust.currentBalance;
        if (total > debt) {
          return total - debt;
        } else {
          return Money.zero;
        }
    }
  }

  Money get _creditToAccountAmount {
    final total = _lineTotal;
    final cash = _cashRefundAmount;
    final diff = total.piastres - cash.piastres;
    return diff > 0 ? Money.fromPiastres(diff) : Money.zero;
  }

  Money get _projectedCustomerBalance {
    final cust = _currentCustomer;
    if (cust == null) return Money.zero;
    final credit = _creditToAccountAmount;
    return Money.fromPiastres(cust.currentBalance.piastres - credit.piastres);
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
          Text(AppStrings.newCustomerReturn, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
        ],
      ),
      content: _isLoadingLookups
          ? SizedBox(
              height: 150,
              width: 520,
              child: Center(child: CircularProgressIndicator(color: colors.primary)),
            )
          : SizedBox(
              width: 540,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Customer Dropdown
                      DropdownButtonFormField<int>(
                        value: _selectedCustomerId,
                        dropdownColor: colors.surface,
                        style: TextStyle(color: colors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'العميل *',
                          labelStyle: TextStyle(color: colors.textSecondary),
                          prefixIcon: Icon(Icons.person_outline, color: colors.primary),
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
                        items: _customers.map((c) {
                          final balanceText = c.hasDebt
                              ? 'مدين: ${c.currentBalance.formatArabic()}'
                              : (c.isCreditor
                                  ? 'دائن له: ${c.currentBalance.abs().formatArabic()}'
                                  : 'خالص');
                          return DropdownMenuItem<int>(
                            value: c.id,
                            child: Text(
                              '${c.name} ($balanceText)',
                              style: TextStyle(color: colors.textPrimary),
                            ),
                          );
                        }).toList(),
                        validator: (val) => val == null ? 'يرجى اختيار العميل' : null,
                        onChanged: (val) => _onCustomerChanged(val),
                      ),
                      AppSpacing.verticalMd,

                      // Optional Link to Sale Invoice
                      if (_selectedCustomerId != null) ...[
                        DropdownButtonFormField<int?>(
                          value: _selectedSaleId,
                          dropdownColor: colors.surface,
                          style: TextStyle(color: colors.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'ربط بفاتورة مبيعات محددة (اختياري)',
                            labelStyle: TextStyle(color: colors.textSecondary),
                            prefixIcon: Icon(Icons.receipt_outlined, color: colors.primary),
                            helperText: _isLoadingSales
                                ? 'جاري جلب فواتير العميل...'
                                : (_customerSales.isEmpty
                                    ? 'لا توجد فواتير مؤكدة سابقة (مرتجع عام)'
                                    : 'اختياري: اختر الفاتورة لتسوية متبقيها وربط المرتجع بها'),
                            helperStyle: TextStyle(color: colors.textSecondary, fontSize: 11),
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
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('بدون ربط بفاتورة (مرتجع حر على حساب العميل)'),
                            ),
                            ..._customerSales.map((s) {
                              return DropdownMenuItem<int?>(
                                value: s.id,
                                child: Text(
                                  'فاتورة #${s.invoiceNo} — إجمالي: ${s.totalAmount.formatArabic()} — متبقي: ${s.remainingAmount.formatArabic()}',
                                  style: TextStyle(color: colors.textPrimary),
                                ),
                              );
                            }),
                          ],
                          onChanged: (val) => _onSaleChanged(val),
                        ),
                        AppSpacing.verticalMd,
                      ],

                      // Product Autocomplete
                      Autocomplete<Product>(
                        key: ValueKey('product_autocomplete_${_selectedSaleId ?? "none"}'),
                        displayStringForOption: (p) {
                          if (_selectedSaleId != null) {
                            final item = _selectedSaleItems
                                .where((i) => i.productId == p.id)
                                .firstOrNull;
                            if (item != null) {
                              final unitStr = item.productUnit.isNotEmpty
                                  ? item.productUnit
                                  : p.unit;
                              return '${p.name} (بالفاتورة: ${QuantityHelper.format(item.quantity, unit: unitStr)} — بسعر: ${item.unitPriceAtSale.formatArabic()})';
                            }
                          }
                          return '${p.name} - متاح بالمخزن: ${QuantityHelper.format(p.currentQuantity, unit: p.unit)} - ${p.currentSalePrice.formatArabic()}';
                        },
                        optionsBuilder: (textEditingValue) {
                          final list = _availableProducts;
                          if (textEditingValue.text.isEmpty) {
                            if (_selectedSaleId != null) {
                              return list;
                            }
                            return const Iterable<Product>.empty();
                          }
                          final q = textEditingValue.text.toLowerCase();
                          return list.where((p) =>
                              p.name.toLowerCase().contains(q) ||
                              (p.code?.toLowerCase().contains(q) ?? false));
                        },
                        onSelected: (p) {
                          setState(() {
                            _selectedProduct = p;
                            if (_selectedSaleId != null) {
                              final item = _selectedSaleItems
                                  .where((i) => i.productId == p.id)
                                  .firstOrNull;
                              _selectedSaleItem = item;
                              if (item != null) {
                                _priceController.text =
                                    (item.unitPriceAtSale.piastres / 100.0)
                                        .toStringAsFixed(2);
                                _quantityController.text = '1';
                              } else {
                                _priceController.text =
                                    (p.currentSalePrice.piastres / 100.0)
                                        .toStringAsFixed(2);
                              }
                            } else {
                              _selectedSaleItem = null;
                              _priceController.text =
                                  (p.currentSalePrice.piastres / 100.0)
                                      .toStringAsFixed(2);
                            }
                          });
                        },
                        fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            style: TextStyle(color: colors.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'ابحث عن المنتج المرتجع *',
                              labelStyle: TextStyle(color: colors.textSecondary),
                              prefixIcon: Icon(Icons.inventory_2_outlined, color: colors.primary),
                              helperText: _selectedSaleId != null
                                  ? (_isLoadingSaleDetails
                                      ? 'جاري جلب منتجات الفاتورة...'
                                      : (_selectedSaleItems.isEmpty
                                          ? 'لا توجد منتجات مسجلة في هذه الفاتورة'
                                          : 'معروض منتجات الفاتورة #${_selectedSale?.invoiceNo ?? ""} فقط (${_selectedSaleItems.length} صنف)'))
                                  : 'ابحث باسم المنتج أو الباركود',
                              helperStyle: TextStyle(
                                color: _selectedSaleId != null ? colors.primary : colors.textSecondary,
                                fontSize: 11,
                              ),
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
                                helperText: _selectedSaleItem != null
                                    ? 'الكمية المباعة بالفاتورة: ${QuantityHelper.format(_selectedSaleItem!.quantity)} ${(_selectedSaleItem!.productUnit.isNotEmpty ? _selectedSaleItem!.productUnit : _selectedProduct?.unit ?? "")}'
                                    : null,
                                helperStyle: TextStyle(color: colors.textSecondary, fontSize: 11),
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
                                final d = Decimal.tryParse(val ?? '');
                                if (d == null || d <= Decimal.zero) return 'كمية غير صحيحة';
                                if (_selectedSaleItem != null && d > _selectedSaleItem!.quantity) {
                                  return 'أكبر من المباع (${QuantityHelper.format(_selectedSaleItem!.quantity)})';
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
                                helperText: _selectedSaleItem != null
                                    ? 'سعر الفاتورة: ${_selectedSaleItem!.unitPriceAtSale.formatArabic()}'
                                    : null,
                                helperStyle: TextStyle(color: colors.textSecondary, fontSize: 11),
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

                      // Financial Settlement Method Selection
                      Text(
                        'طريقة التسوية المالية للمرتجع:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: colors.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.border),
                        ),
                        child: Column(
                          children: ReturnSettlementOption.values.map((opt) {
                            final isSelected = _settlementOption == opt;
                            return RadioListTile<ReturnSettlementOption>(
                              value: opt,
                              groupValue: _settlementOption,
                              activeColor: colors.primary,
                              dense: true,
                              title: Text(
                                opt.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? colors.primary : colors.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                opt.subtitle,
                                style: TextStyle(fontSize: 11, color: colors.textSecondary),
                              ),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _settlementOption = val);
                                }
                              },
                            );
                          }).toList(),
                        ),
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
                                Text('إجمالي قيمة المرتجع:', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                                Text(
                                  _lineTotal.formatArabic(),
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colors.primary),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Text(
                              '• سيتم زيادة المخزون فورياً بالكمية المرتجعة.',
                              style: TextStyle(fontSize: 12, color: colors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            if (_cashRefundAmount > Money.zero) ...[
                              Text(
                                '• سيتم صرف ${_cashRefundAmount.formatArabic()} نقداً من الخزينة للعميل.',
                                style: TextStyle(fontSize: 12, color: colors.warning, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                            ],
                            if (_creditToAccountAmount > Money.zero) ...[
                              Text(
                                '• سيتم خصم ${_creditToAccountAmount.formatArabic()} من حساب العميل.',
                                style: TextStyle(fontSize: 12, color: colors.success, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                            ],
                            if (_currentCustomer != null) ...[
                              Text(
                                '• رصيد العميل بعد العملية: ${_projectedCustomerBalance.piastres > 0 ? "مدين عليه: ${_projectedCustomerBalance.formatArabic()}" : (_projectedCustomerBalance.piastres < 0 ? "دائن له طرفنا: ${_projectedCustomerBalance.abs().formatArabic()}" : "خالص (0.00 ج.م)")}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _projectedCustomerBalance.piastres < 0 ? colors.primary : colors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
          onPressed: _isSubmitting ? null : _submit,
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
    if (_selectedCustomerId == null || _selectedProduct == null) return;

    setState(() => _isSubmitting = true);

    final qty = Decimal.parse(_quantityController.text.trim());
    final price = Money.tryParse(_priceController.text.trim()) ?? Money.zero;

    final params = CreateCustomerReturnParams(
      originalSaleId: _selectedSaleId,
      customerId: _selectedCustomerId!,
      returnDate: _returnDate,
      items: [
        ReturnItemParam(
          productId: _selectedProduct!.id,
          quantity: qty,
          unitPrice: price,
        ),
      ],
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      refundCashAmount: _cashRefundAmount,
    );

    final result = await widget.cubit.submitCustomerReturn(params);

    if (mounted) {
      final colors = context.colors;
      setState(() => _isSubmitting = false);
      result.fold(
        onSuccess: (ret) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم تسجيل مرتجع العميل بنجاح (#${ret.id})'),
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
