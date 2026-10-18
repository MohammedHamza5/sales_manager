import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/money/money.dart';
import '../../../../core/result/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../suppliers/domain/entities/supplier.dart';
import '../../../suppliers/domain/usecases/get_suppliers_usecase.dart';
import '../cubit/create_purchase_cubit.dart';
import '../cubit/create_purchase_state.dart';
import '../widgets/product_selector_dialog.dart';
import '../widgets/purchase_item_row.dart';
import '../../../../core/shortcuts/app_shortcuts.dart';

class CreatePurchasePage extends StatefulWidget {
  final int? preselectedSupplierId;
  final String? preselectedSupplierName;

  const CreatePurchasePage({
    super.key,
    this.preselectedSupplierId,
    this.preselectedSupplierName,
  });

  @override
  State<CreatePurchasePage> createState() => _CreatePurchasePageState();
}

class _CreatePurchasePageState extends State<CreatePurchasePage> {
  late final CreatePurchaseCubit _cubit;
  late final TextEditingController _paidController;
  late final TextEditingController _noteController;
  List<Supplier> _suppliers = [];
  bool _isLoadingSuppliers = true;

  @override
  void initState() {
    super.initState();
    _cubit = CreatePurchaseCubit(createPurchaseUseCase: getIt())
      ..init(
        preselectedSupplierId: widget.preselectedSupplierId,
        preselectedSupplierName: widget.preselectedSupplierName,
      );
    _paidController = TextEditingController(text: '0');
    _noteController = TextEditingController();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _cubit.close();
    _paidController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    final getSuppliers = getIt<GetSuppliersUseCase>();
    final result = await getSuppliers(isActiveOnly: true);
    if (!mounted) return;
    if (result case Success(:final data)) {
      setState(() {
        _suppliers = data;
        _isLoadingSuppliers = false;
      });
      // If preselected was passed and we found it
      if (widget.preselectedSupplierId != null) {
        final s = _suppliers.where((it) => it.id == widget.preselectedSupplierId).firstOrNull;
        if (s != null) {
          _cubit.selectSupplier(s.id, s.name);
        }
      }
    } else {
      setState(() {
        _isLoadingSuppliers = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<CreatePurchaseCubit, CreatePurchaseState>(
        listener: (context, state) {
          if (state is CreatePurchaseSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'تم حفظ فاتورة الشراء رقم ${state.purchase.invoiceNo} بنجاح',
                ),
                backgroundColor: context.colors.success,
              ),
            );
            context.go('/purchases');
          }
        },
        builder: (context, state) {
          if (state is! CreatePurchaseEditing) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final colors = context.colors;

          return CallbackShortcuts(
            bindings: {
              AppShortcuts.help: () => AppShortcuts.showHelpDialog(context),
              AppShortcuts.helpAlt: () => AppShortcuts.showHelpDialog(context),
              AppShortcuts.helpSlash: () => AppShortcuts.showHelpDialog(context),
              AppShortcuts.submitAction: () {
                if (state.canSubmit && !state.isSubmitting) {
                  _cubit.submitPurchase();
                }
              },
              AppShortcuts.ctrlEnterSubmit: () {
                if (state.canSubmit && !state.isSubmitting) {
                  _cubit.submitPurchase();
                }
              },
              AppShortcuts.saveAlt: () {
                if (state.canSubmit && !state.isSubmitting) {
                  _cubit.submitPurchase();
                }
              },
              AppShortcuts.payFully: () {
                _paidController.text =
                    state.totalAmount.formattedWithoutCurrency;
                _cubit.setPaidAmount(state.totalAmount);
              },
              AppShortcuts.payFullyAlt: () {
                _paidController.text =
                    state.totalAmount.formattedWithoutCurrency;
                _cubit.setPaidAmount(state.totalAmount);
              },
              AppShortcuts.payZero: () {
                _paidController.text = '0';
                _cubit.setPaidAmount(Money.zero);
              },
              AppShortcuts.payZeroAlt: () {
                _paidController.text = '0';
                _cubit.setPaidAmount(Money.zero);
              },
              AppShortcuts.closeOrBack: () => context.go('/purchases'),
            },
            child: Focus(
              autofocus: true,
              child: Scaffold(
                backgroundColor: colors.background,
                appBar: AppBar(
                  title: Text(
                    'فاتورة شراء جديدة',
                    style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: colors.surface,
                  elevation: 0,
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Container(color: colors.border, height: 1),
                  ),
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                    onPressed: () => context.go('/purchases'),
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'اختصارات لوحة المفاتيح (F1 أو Ctrl+H)',
                      icon: Icon(Icons.keyboard_outlined, color: colors.textSecondary),
                      onPressed: () => AppShortcuts.showHelpDialog(context),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: FilledButton.icon(
                        onPressed: state.canSubmit
                            ? () => _cubit.submitPurchase()
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: state.isSubmitting
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.onPrimary,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: const Text('حفظ الفاتورة (F10)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Items and Selection (flex 7)
                Expanded(
                  flex: 7,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeaderControls(state),
                        Divider(height: 1, color: colors.border),
                        _buildTableHeader(),
                        Expanded(
                          child: state.items.isEmpty
                              ? _buildEmptyItemsPrompt()
                              : ListView.builder(
                                  itemCount: state.items.length,
                                  itemBuilder: (context, index) {
                                    final item = state.items[index];
                                    return PurchaseItemRow(
                                      index: index,
                                      item: item,
                                      onQuantityChanged: (q) =>
                                          _cubit.updateItemQuantity(index, q),
                                      onUnitCostChanged: (c) =>
                                          _cubit.updateItemUnitCost(index, c),
                                      onRemove: () =>
                                          _cubit.removeItem(index),
                                    );
                                  },
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final product =
                                  await ProductSelectorDialog.show(context);
                              if (product != null) {
                                _cubit.addItem(product);
                              }
                            },
                            icon: Icon(Icons.add_shopping_cart, color: colors.primary),
                            label: Text('إضافة صنف للفاتورة (F3)', style: TextStyle(color: colors.textPrimary)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: colors.border),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Right Column: Financial Summary & Live Preview (flex 4)
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildFinancialSummaryCard(state),
                        const SizedBox(height: 16),
                        _buildLivePreviewCard(state),
                        if (state.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.danger.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: colors.danger),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: colors.danger),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    state.errorMessage!,
                                    style: TextStyle(
                                      color: colors.danger,
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
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  ),
);
}

  Widget _buildHeaderControls(CreatePurchaseEditing state) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Supplier dropdown
          Expanded(
            flex: 2,
            child: _isLoadingSuppliers
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<int>(
                    value: state.supplierId,
                    dropdownColor: colors.surfaceElevated,
                    style: TextStyle(color: colors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'المورد *',
                      prefixIcon: Icon(Icons.business_outlined, color: colors.primary),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: colors.border),
                      ),
                      isDense: true,
                    ),
                    hint: Text('اختر المورد...', style: TextStyle(color: colors.textMuted)),
                    items: _suppliers
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name, style: TextStyle(color: colors.textPrimary)),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final s = _suppliers.firstWhere((it) => it.id == val);
                        _cubit.selectSupplier(s.id, s.name);
                      }
                    },
                  ),
          ),
          const SizedBox(width: 16),
          // Purchase Date
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: state.purchaseDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  _cubit.setPurchaseDate(picked);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'تاريخ الفاتورة',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: colors.border),
                  ),
                  isDense: true,
                  suffixIcon: Icon(Icons.calendar_today, size: 18, color: colors.primary),
                ),
                child: Text(
                  '${state.purchaseDate.year}/${state.purchaseDate.month.toString().padLeft(2, '0')}/${state.purchaseDate.day.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 14, color: colors.textPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    final colors = context.colors;

    return Container(
      color: colors.surfaceElevated,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 32, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary))),
          Expanded(flex: 3, child: Text('اسم المنتج', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary))),
          const SizedBox(width: 12),
          SizedBox(width: 100, child: Text('الكمية', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary))),
          const SizedBox(width: 12),
          SizedBox(width: 120, child: Text('سعر الشراء', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary))),
          const SizedBox(width: 16),
          SizedBox(width: 120, child: Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary))),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildEmptyItemsPrompt() {
    final colors = context.colors;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: colors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'لم يتم إضافة أي أصناف للفاتورة بعد',
            style: TextStyle(
              fontSize: 16,
              color: colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على زر "إضافة صنف" أدناه لاختيار المنتجات',
            style: TextStyle(fontSize: 13, color: colors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummaryCard(CreatePurchaseEditing state) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'الملخص المالي',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'إجمالي الفاتورة:',
            state.totalAmount.formatted,
            isBold: true,
            valueColor: colors.primary,
          ),
          Divider(height: 24, color: colors.border),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _paidController,
                  style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'المبلغ المدفوع نقداً (ج.م)',
                    filled: true,
                    fillColor: colors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: colors.border),
                    ),
                    isDense: true,
                  ),
                  onChanged: (val) {
                    final m = Money.tryParse(val) ?? Money.zero;
                    _cubit.setPaidAmount(m);
                  },
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: colors.primary),
                onPressed: () {
                  _paidController.text =
                      state.totalAmount.formattedWithoutCurrency;
                  _cubit.setPaidAmount(state.totalAmount);
                },
                child: const Text('سداد كامل (Alt+C)'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: colors.textSecondary),
                onPressed: () {
                  _paidController.text = '0';
                  _cubit.setPaidAmount(Money.zero);
                },
                child: const Text('آجل كامل (Alt+D)'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'المتبقي على الفاتورة (دين للمورد):',
            state.remainingAmount.formatted,
            isBold: true,
            valueColor: state.remainingAmount.piastres > 0
                ? colors.danger
                : colors.success,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              labelText: 'ملاحظات الفاتورة (اختياري)',
              filled: true,
              fillColor: colors.surfaceElevated,
              border: OutlineInputBorder(
                borderSide: BorderSide(color: colors.border),
              ),
              isDense: true,
            ),
            onChanged: (val) => _cubit.setNote(val),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String title,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    final colors = context.colors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: colors.textPrimary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor ?? colors.textPrimary,
            fontSize: isBold ? 15 : 13,
          ),
        ),
      ],
    );
  }

  Widget _buildLivePreviewCard(CreatePurchaseEditing state) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.remove_red_eye_outlined,
                  size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                'المعاينة الفورية للأثر (Zero-Surprise)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stock impact
          Row(
            children: [
              Icon(Icons.add_circle, color: colors.success, size: 16),
              const SizedBox(width: 8),
              Text(
                'سيُضاف للمخزون ${state.items.length} أصناف.',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Cashbox impact
          Row(
            children: [
              Icon(
                state.paidAmount.piastres > 0
                    ? Icons.arrow_downward
                    : Icons.remove,
                color: state.paidAmount.piastres > 0
                    ? colors.danger
                    : colors.textMuted,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                state.paidAmount.piastres > 0
                    ? 'ستنقص الخزينة فورياً بمبلغ ${state.paidAmount.formatted}.'
                    : 'لا أثر على الخزينة (لم يتم سداد نقدية).',
                style: TextStyle(
                  fontSize: 13,
                  color: state.paidAmount.piastres > 0
                      ? colors.danger
                      : colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Supplier Debt impact
          Row(
            children: [
              Icon(
                state.remainingAmount.piastres > 0
                    ? Icons.arrow_upward
                    : Icons.check_circle,
                color: state.remainingAmount.piastres > 0
                    ? colors.warning
                    : colors.success,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.remainingAmount.piastres > 0
                      ? 'سيزيد دين المورد (${state.supplierName ?? "المحدد"}) بمبلغ ${state.remainingAmount.formatted}.'
                      : 'لا متبقٍ على الفاتورة (مسددة بالكامل).',
                  style: TextStyle(
                    fontSize: 13,
                    color: state.remainingAmount.piastres > 0
                        ? colors.warning
                        : colors.success,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
