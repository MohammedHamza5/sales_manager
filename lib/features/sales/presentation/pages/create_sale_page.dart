import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/money/money.dart';
import '../../../../core/money/quantity.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../customers/domain/usecases/get_customers_usecase.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/usecases/get_products_usecase.dart';
import '../cubit/create_sale_cubit.dart';
import '../cubit/create_sale_state.dart';
import '../widgets/sale_items_table.dart';
import '../../../../core/shortcuts/app_shortcuts.dart';

class CreateSalePage extends StatelessWidget {
  const CreateSalePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CreateSaleCubit(getIt()),
      child: const _CreateSaleView(),
    );
  }
}

class _CreateSaleView extends StatefulWidget {
  const _CreateSaleView();

  @override
  State<_CreateSaleView> createState() => _CreateSaleViewState();
}

class _CreateSaleViewState extends State<_CreateSaleView> {
  final TextEditingController _paidController = TextEditingController(text: '0.00');
  final TextEditingController _noteController = TextEditingController();

  List<Customer> _customers = [];
  List<Product> _products = [];
  bool _isLoadingLookups = true;

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  @override
  void dispose() {
    _paidController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    final customersResult = await getIt<GetCustomersUseCase>()(isActiveOnly: true);
    final productsResult = await getIt<GetProductsUseCase>()(isActiveOnly: true);

    if (mounted) {
      setState(() {
        _customers = customersResult.dataOrNull ?? [];
        _products = productsResult.dataOrNull ?? [];
        _isLoadingLookups = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreateSaleCubit, CreateSaleState>(
      listener: (context, state) {
        if (state is CreateSaleSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم حفظ فاتورة البيع رقم #${state.sale.invoiceNo} بنجاح'),
              backgroundColor: context.colors.success,
            ),
          );
          context.pop();
        } else if (state is CreateSaleEditing && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: context.colors.danger,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is! CreateSaleEditing) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final cubit = context.read<CreateSaleCubit>();

        final colors = context.colors;

        return CallbackShortcuts(
          bindings: {
            AppShortcuts.help: () => AppShortcuts.showHelpDialog(context),
            AppShortcuts.helpAlt: () => AppShortcuts.showHelpDialog(context),
            AppShortcuts.helpSlash: () => AppShortcuts.showHelpDialog(context),
            AppShortcuts.submitAction: () {
              if (state.canSubmit && !state.isSubmitting) {
                cubit.submitSale();
              }
            },
            AppShortcuts.ctrlEnterSubmit: () {
              if (state.canSubmit && !state.isSubmitting) {
                cubit.submitSale();
              }
            },
            AppShortcuts.saveAlt: () {
              if (state.canSubmit && !state.isSubmitting) {
                cubit.submitSale();
              }
            },
            AppShortcuts.payFully: () {
              cubit.setPaidFully();
              _paidController.text =
                  (state.totalAmount.piastres / 100.0).toStringAsFixed(2);
            },
            AppShortcuts.payFullyAlt: () {
              cubit.setPaidFully();
              _paidController.text =
                  (state.totalAmount.piastres / 100.0).toStringAsFixed(2);
            },
            AppShortcuts.payZero: () {
              cubit.setPaidZero();
              _paidController.text = '0.00';
            },
            AppShortcuts.payZeroAlt: () {
              cubit.setPaidZero();
              _paidController.text = '0.00';
            },
            AppShortcuts.closeOrBack: () {
              context.pop();
            },
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              backgroundColor: colors.background,
              appBar: AppBar(
                title: Text('إنشاء فاتورة بيع جديدة', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
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
                    tooltip: 'اختصارات لوحة المفاتيح (F1)',
                    icon: Icon(Icons.keyboard_outlined, color: colors.textSecondary),
                    onPressed: () => AppShortcuts.showHelpDialog(context),
                  ),
                ],
              ),
          body: _isLoadingLookups
              ? const Center(child: CircularProgressIndicator())
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Section: Customer, Products Search, Items Table
                    Expanded(
                      flex: 7,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Customer & Date Container
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                border: Border.all(color: colors.border),
                              ),
                              child: Row(
                                children: [
                                  // Customer Dropdown
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<int>(
                                      value: state.customerId,
                                      dropdownColor: colors.surfaceElevated,
                                      style: TextStyle(color: colors.textPrimary, fontSize: 13),
                                      decoration: InputDecoration(
                                        labelText: 'العميل *',
                                        prefixIcon: Icon(Icons.person_outline, color: colors.primary),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(color: colors.border),
                                        ),
                                        isDense: true,
                                      ),
                                      items: _customers.map((c) {
                                        return DropdownMenuItem<int>(
                                          value: c.id,
                                          child: Text(
                                            '${c.name} (${c.currentBalance.formatArabic()})',
                                            style: TextStyle(color: colors.textPrimary),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          final c = _customers.firstWhere((x) => x.id == val);
                                          cubit.setCustomer(c.id, c.name);
                                        }
                                      },
                                    ),
                                  ),
                                  AppSpacing.horizontalMd,

                                  // Date Picker
                                  Expanded(
                                    child: InkWell(
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: state.saleDate,
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2100),
                                        );
                                        if (picked != null) {
                                          cubit.setSaleDate(picked);
                                        }
                                      },
                                      child: InputDecorator(
                                        decoration: InputDecoration(
                                          labelText: 'تاريخ الفاتورة',
                                          prefixIcon: Icon(Icons.calendar_today_outlined, color: colors.primary),
                                          border: OutlineInputBorder(
                                            borderSide: BorderSide(color: colors.border),
                                          ),
                                          isDense: true,
                                        ),
                                        child: Text(
                                          DateFormat('yyyy/MM/dd').format(state.saleDate),
                                          style: TextStyle(color: colors.textPrimary),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AppSpacing.verticalMd,

                            // Product Selection Card
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                border: Border.all(color: colors.border),
                              ),
                              child: Autocomplete<Product>(
                                displayStringForOption: (p) =>
                                    '${p.name} - متاح: ${QuantityHelper.format(p.currentQuantity, unit: p.unit)} - ${p.currentSalePrice.formatArabic()}',
                                optionsBuilder: (textEditingValue) {
                                  if (textEditingValue.text.isEmpty) {
                                    return const Iterable<Product>.empty();
                                  }
                                  final q = textEditingValue.text.toLowerCase();
                                  return _products.where((p) =>
                                      p.name.toLowerCase().contains(q) ||
                                      (p.code?.toLowerCase().contains(q) ?? false));
                                },
                                onSelected: (product) {
                                  cubit.addProduct(product);
                                },
                                fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                                  return TextField(
                                    controller: textController,
                                    focusNode: focusNode,
                                    autofocus: true,
                                    style: TextStyle(color: colors.textPrimary),
                                    decoration: InputDecoration(
                                      labelText: 'ابحث عن صنف لإضافته (بالاسم أو الكود)...',
                                      prefixIcon: Icon(Icons.search, color: colors.textMuted),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(color: colors.border),
                                      ),
                                      isDense: true,
                                    ),
                                  );
                                },
                              ),
                            ),
                            AppSpacing.verticalMd,

                            // Table of Draft Items
                            SaleItemsTable(
                              items: state.items,
                              onQuantityChanged: (idx, qty) => cubit.updateItemQuantity(idx, qty),
                              onPriceChanged: (idx, price) => cubit.updateItemPrice(idx, price),
                              onRemoveItem: (idx) => cubit.removeItem(idx),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Right Side: Summary, Payment & Live Preview
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          border: Border(right: BorderSide(color: colors.border)),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'ملخص الفاتورة والسداد',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                              AppSpacing.verticalMd,

                              // Total Amount Banner
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: colors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: colors.primary.withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'إجمالي الفاتورة',
                                      style: TextStyle(fontSize: 13, color: colors.textSecondary),
                                    ),
                                    AppSpacing.verticalXs,
                                    Text(
                                      state.totalAmount.formatArabic(),
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: colors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AppSpacing.verticalMd,

                              // Paid Amount Input
                              TextField(
                                controller: _paidController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  labelText: 'المبلغ المدفوع نقدياً (ج.م)',
                                  prefixIcon: Icon(Icons.payments_outlined, color: colors.primary),
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  final m = Money.tryParse(val);
                                  if (m != null && m.piastres >= 0) {
                                    cubit.setPaidAmount(m);
                                  }
                                },
                              ),
                              AppSpacing.verticalSm,

                              // Quick Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: colors.border),
                                        foregroundColor: colors.textPrimary,
                                      ),
                                      onPressed: () {
                                        cubit.setPaidFully();
                                        _paidController.text =
                                            (state.totalAmount.piastres / 100.0).toStringAsFixed(2);
                                      },
                                      child: const Text('نقدي كامل (Alt+C)'),
                                    ),
                                  ),
                                  AppSpacing.horizontalSm,
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: colors.border),
                                        foregroundColor: colors.textPrimary,
                                      ),
                                      onPressed: () {
                                        cubit.setPaidZero();
                                        _paidController.text = '0.00';
                                      },
                                      child: const Text('آجل كامل (Alt+D)'),
                                    ),
                                  ),
                                ],
                              ),
                              AppSpacing.verticalMd,

                              // Remaining / Debt
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: colors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: state.isFullyPaid
                                        ? colors.success.withValues(alpha: 0.5)
                                        : colors.border,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('المتبقي على العميل:', style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary)),
                                    Text(
                                      state.remainingAmount.formatArabic(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: state.isFullyPaid ? colors.success : colors.danger,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AppSpacing.verticalMd,

                              // Note Field
                              TextField(
                                controller: _noteController,
                                maxLines: 2,
                                style: TextStyle(color: colors.textPrimary),
                                decoration: const InputDecoration(
                                  labelText: 'ملاحظات الفاتورة (اختياري)',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onChanged: (val) => cubit.setNote(val),
                              ),
                              AppSpacing.verticalMd,

                              // ZERO-SURPRISE LIVE PREVIEW BOX
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: colors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: colors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.visibility_outlined, size: 16, color: colors.primary),
                                        const SizedBox(width: 6),
                                        Text(
                                          'معاينة الأثر المالي والمخزني:',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.textPrimary),
                                        ),
                                      ],
                                    ),
                                    AppSpacing.verticalXs,
                                    Text(
                                      '• سيتم خصم كميات ${state.items.length} أصناف من المخزن.',
                                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                                    ),
                                    Text(
                                      state.remainingAmount.piastres > 0
                                          ? '• سيُقيد دين على العميل بمبلغ ${state.remainingAmount.formatArabic()}.'
                                          : '• لا توجد ديون معلقة (تم السداد بالكامل).',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: state.remainingAmount.piastres > 0 ? colors.danger : colors.success,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (state.paidAmount.piastres > 0)
                                      Text(
                                        '• سيتم إيداع ${state.paidAmount.formatArabic()} في الخزينة فورياً.',
                                        style: TextStyle(fontSize: 12, color: colors.primary),
                                      ),
                                  ],
                                ),
                              ),
                              AppSpacing.verticalLg,

                              // Submit Button
                              ElevatedButton(
                                onPressed: state.canSubmit ? () => cubit.submitSale() : null,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: colors.primary,
                                  foregroundColor: colors.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                  ),
                                ),
                                child: state.isSubmitting
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(color: colors.onPrimary, strokeWidth: 2),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.check, size: 20),
                                          SizedBox(width: 8),
                                          Text('حفظ وإتمام الفاتورة (F10)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        ),
        );
      },
    );
  }
}
