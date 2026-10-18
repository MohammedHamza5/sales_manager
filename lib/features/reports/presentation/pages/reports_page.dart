import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:decimal/decimal.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/money/money.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/states/empty_view.dart';
import '../../../../core/widgets/states/error_view.dart';
import '../../../../core/widgets/states/loading_view.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../customers/domain/usecases/get_customers_usecase.dart';
import '../../../suppliers/domain/entities/supplier.dart';
import '../../../suppliers/domain/usecases/get_suppliers_usecase.dart';
import '../../domain/entities/cashbox_report.dart';
import '../../domain/entities/collections_report.dart';
import '../../domain/entities/inventory_report.dart';
import '../../domain/entities/profit_report.dart';
import '../../domain/entities/sales_report.dart';
import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';
import '../widgets/report_kpi_card.dart';

enum DatePreset { today, yesterday, thisWeek, thisMonth, thisYear, custom }

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  DatePreset _selectedPreset = DatePreset.thisMonth;

  List<Customer> _customers = [];
  List<Supplier> _suppliers = [];
  int? _selectedCustomerId;
  int? _selectedSupplierId;
  String? _selectedSaleStatus;
  String? _selectedMovementType;

  final DateFormat _dateFormat = DateFormat('yyyy/MM/dd');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadMetadata();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMetadata() async {
    final customersResult = await getIt<GetCustomersUseCase>()();
    final suppliersResult = await getIt<GetSuppliersUseCase>()();

    if (mounted) {
      setState(() {
        _customers = customersResult.dataOrNull ?? [];
        _suppliers = suppliersResult.dataOrNull ?? [];
      });
      _refreshCurrentTab();
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _refreshCurrentTab();
  }

  void _refreshCurrentTab() {
    final cubit = context.read<ReportsCubit>();
    switch (_tabController.index) {
      case 0:
        cubit.loadSalesReport(
          from: _startDate,
          to: _endDate,
          customerId: _selectedCustomerId,
          status: _selectedSaleStatus,
        );
        break;
      case 1:
        cubit.loadCollectionsReport(
          from: _startDate,
          to: _endDate,
          customerId: _selectedCustomerId,
        );
        break;
      case 2:
        cubit.loadCustomerReport(
          customerId: _selectedCustomerId,
          from: _startDate,
          to: _endDate,
        );
        break;
      case 3:
        cubit.loadSupplierReport(
          supplierId: _selectedSupplierId,
          from: _startDate,
          to: _endDate,
        );
        break;
      case 4:
        cubit.loadInventoryReport(
          movementType: _selectedMovementType,
          from: _startDate,
          to: _endDate,
        );
        break;
      case 5:
        cubit.loadCashboxReport(
          from: _startDate,
          to: _endDate,
        );
        break;
      case 6:
        cubit.loadProfitReport(
          from: _startDate,
          to: _endDate,
        );
        break;
    }
  }

  void _applyPreset(DatePreset preset) {
    final now = DateTime.now();
    setState(() {
      _selectedPreset = preset;
      switch (preset) {
        case DatePreset.today:
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case DatePreset.yesterday:
          final y = now.subtract(const Duration(days: 1));
          _startDate = DateTime(y.year, y.month, y.day);
          _endDate = DateTime(y.year, y.month, y.day, 23, 59, 59);
          break;
        case DatePreset.thisWeek:
          _startDate = now.subtract(const Duration(days: 7));
          _endDate = now;
          break;
        case DatePreset.thisMonth:
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
          break;
        case DatePreset.thisYear:
          _startDate = DateTime(now.year, 1, 1);
          _endDate = now;
          break;
        case DatePreset.custom:
          break;
      }
    });
    if (preset != DatePreset.custom) {
      _refreshCurrentTab();
    } else {
      _pickDateRange();
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      locale: const Locale('ar'),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedPreset = DatePreset.custom;
      });
      _refreshCurrentTab();
    }
  }

  Widget _buildPresetChip(String label, DatePreset preset) {
    final colors = context.colors;
    final isSelected = _selectedPreset == preset;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: colors.primaryLight,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? colors.primary : colors.textSecondary,
      ),
      onSelected: (_) => _applyPreset(preset),
    );
  }

  void _exportCurrentStateToCsv() {
    final state = context.read<ReportsCubit>().state;
    String csvContent = '';
    String fileName = 'report';

    if (state is SalesReportLoaded) {
      fileName = 'تقرير_المبيعات';
      final buffer = StringBuffer();
      buffer.writeln('\uFEFFالتاريخ,رقم الفاتورة,العميل,الإجمالي,المدفوع,المتبقي,الحالة');
      for (final sale in state.report.items) {
        buffer.writeln(
          '${_dateFormat.format(sale.saleDate)},${sale.invoiceNo},${sale.customerName},${sale.totalAmount.formatted},${sale.paidAmount.formatted},${sale.remainingAmount.formatted},${sale.status}',
        );
      }
      csvContent = buffer.toString();
    } else if (state is ProfitReportLoaded) {
      fileName = 'تقرير_الأرباح_والهوامش';
      final buffer = StringBuffer();
      buffer.writeln('\uFEFFاسم المنتج,الوحدة,الكمية المباعة,إجمالي المبيعات,تكلفة البضاعة,مجمل الربح,نسبة الهامش %');
      for (final item in state.report.items) {
        buffer.writeln(
          '${item.productName},${item.unit},${item.soldQuantity},${item.totalRevenue.formatted},${item.totalCost.formatted},${item.grossProfit.formatted},${item.marginPercentage.toStringAsFixed(2)}%',
        );
      }
      csvContent = buffer.toString();
    } else if (state is CollectionsReportLoaded) {
      fileName = 'تقرير_التحصيلات';
      final buffer = StringBuffer();
      buffer.writeln('\uFEFFالتاريخ,العميل,المبلغ,فاتورة البيع,ملاحظات');
      for (final item in state.report.items) {
        buffer.writeln(
          '${_dateFormat.format(item.paymentDate)},${item.customerName},${item.amount.formatted},${item.linkedSaleInvoiceNo ?? "-"},${item.note ?? ""}',
        );
      }
      csvContent = buffer.toString();
    } else if (state is CustomerReportLoaded) {
      if (state.accountReport != null) {
        fileName = 'كشف_حساب_${state.accountReport!.customerName}';
        final buffer = StringBuffer();
        buffer.writeln('\uFEFFالتاريخ,البيان,النوع,مدين,دائن,الرصيد');
        for (final item in state.accountReport!.entries) {
          buffer.writeln(
            '${_dateFormat.format(item.date)},${item.description},${item.entryType},${item.debit.formatted},${item.credit.formatted},${item.balanceAfter.formatted}',
          );
        }
        csvContent = buffer.toString();
      } else {
        fileName = 'أرصدة_جميع_العملاء';
        final buffer = StringBuffer();
        buffer.writeln('\uFEFFاسم العميل,الهاتف,الرصيد الحالي');
        for (final item in state.allBalances) {
          buffer.writeln('${item.customerName},${item.phone ?? "-"},${item.balance.formatted}');
        }
        csvContent = buffer.toString();
      }
    } else if (state is SupplierReportLoaded) {
      if (state.accountReport != null) {
        fileName = 'كشف_حساب_${state.accountReport!.supplierName}';
        final buffer = StringBuffer();
        buffer.writeln('\uFEFFالتاريخ,البيان,النوع,مدين,دائن,الرصيد');
        for (final item in state.accountReport!.entries) {
          buffer.writeln(
            '${_dateFormat.format(item.date)},${item.description},${item.entryType},${item.debit.formatted},${item.credit.formatted},${item.balanceAfter.formatted}',
          );
        }
        csvContent = buffer.toString();
      } else {
        fileName = 'أرصدة_جميع_الموردين';
        final buffer = StringBuffer();
        buffer.writeln('\uFEFFاسم المورد,الهاتف,الرصيد الحالي');
        for (final item in state.allBalances) {
          buffer.writeln('${item.supplierName},${item.phone ?? "-"},${item.balance.formatted}');
        }
        csvContent = buffer.toString();
      }
    } else if (state is InventoryReportLoaded) {
      fileName = 'تقرير_المخزون';
      final buffer = StringBuffer();
      buffer.writeln('\uFEFFاسم المنتج,الكود,الكمية الحالية,سعر الشراء,سعر البيع,إجمالي القيمة');
      for (final item in state.report.products) {
        buffer.writeln(
          '${item.productName},${item.code ?? ""},${item.currentQuantity},${item.currentPurchasePrice.formatted},${item.currentSalePrice.formatted},${item.totalValuationAtCost.formatted}',
        );
      }
      csvContent = buffer.toString();
    } else if (state is CashboxReportLoaded) {
      fileName = 'تقرير_الخزينة';
      final buffer = StringBuffer();
      buffer.writeln('\uFEFFالتاريخ,نوع الحركة,وارد,صادر,الرصيد,ملاحظات');
      for (final item in state.report.transactions) {
        final isIn = item.direction == 'in';
        buffer.writeln(
          '${_dateFormat.format(item.date)},${item.transactionType},${isIn ? item.amount.formatted : "-"},${!isIn ? item.amount.formatted : "-"},${item.balanceAfter.formatted},${item.note ?? ""}',
        );
      }
      csvContent = buffer.toString();
    }

    if (csvContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد بيانات متاحة للتصدير حالياً')),
      );
      return;
    }

    Clipboard.setData(ClipboardData(text: csvContent));
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final colors = ctx.colors;
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Row(
            children: [
              Icon(Icons.table_chart, color: colors.success),
              const SizedBox(width: 8),
              Text('تم تصدير $fileName بنجاح', style: TextStyle(color: colors.textPrimary)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تم نسخ بيانات التقرير بتنسيق CSV (المتوافق مع Excel والعربية) إلى الحافظة.',
                style: TextStyle(height: 1.5, color: colors.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  csvContent.split('\n').take(6).join('\n'),
                  style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: colors.textMuted),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إغلاق', style: TextStyle(color: colors.textSecondary)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: csvContent));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إعادة نسخ محتوى CSV')),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('نسخ مجدداً'),
            ),
          ],
        );
      },
    );
  }

  void _onPrintRequested(String reportTitle) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تجهيز $reportTitle للطباعة والتصدير'),
        backgroundColor: context.colors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterBar(),
          Expanded(
            child: BlocBuilder<ReportsCubit, ReportsState>(
              builder: (context, state) {
                if (state is ReportsLoading) {
                  return const LoadingView(message: 'جاري تجميع وتحليل بيانات التقرير...');
                }
                if (state is ReportsError) {
                  return ErrorView(
                    message: state.message,
                    onRetry: _refreshCurrentTab,
                  );
                }
                if (state is ReportsEmpty) {
                  return EmptyView(
                    title: state.message,
                    actionLabel: 'إعادة التحديث',
                    onAction: _refreshCurrentTab,
                  );
                }
                if (state is SalesReportLoaded) {
                  return _buildSalesReportView(state.report);
                }
                if (state is CollectionsReportLoaded) {
                  return _buildCollectionsReportView(state.report);
                }
                if (state is CustomerReportLoaded) {
                  return _buildCustomerReportView(state);
                }
                if (state is SupplierReportLoaded) {
                  return _buildSupplierReportView(state);
                }
                if (state is InventoryReportLoaded) {
                  return _buildInventoryReportView(state.report);
                }
                if (state is CashboxReportLoaded) {
                  return _buildCashboxReportView(state.report);
                }
                if (state is ProfitReportLoaded) {
                  return _buildProfitReportView(state.report);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final colors = context.colors;
    return Container(
      color: colors.surface,
      padding: const EdgeInsets.only(top: AppSpacing.md, right: AppSpacing.lg, left: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics_outlined, color: colors.primary, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'مركز التقارير والتحليلات الشاملة',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _exportCurrentStateToCsv,
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: const Text('تصدير CSV'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.success,
                      side: BorderSide(color: colors.success),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () => _onPrintRequested('التقرير الحالي'),
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: const Text('طباعة التقرير'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.primary,
                      side: BorderSide(color: colors.primary),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: colors.primary,
            unselectedLabelColor: colors.textSecondary,
            indicatorColor: colors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [
              Tab(icon: Icon(Icons.point_of_sale), text: 'المبيعات'),
              Tab(icon: Icon(Icons.payments_outlined), text: 'التحصيلات'),
              Tab(icon: Icon(Icons.people_alt_outlined), text: 'العملاء وكشوف الحساب'),
              Tab(icon: Icon(Icons.local_shipping_outlined), text: 'الموردون والمستحقات'),
              Tab(icon: Icon(Icons.inventory_2_outlined), text: 'المخزون والتقييم'),
              Tab(icon: Icon(Icons.account_balance_wallet_outlined), text: 'الخزينة والنقدية'),
              Tab(icon: Icon(Icons.trending_up), text: 'الأرباح وهوامش الربح'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildPresetChip('اليوم', DatePreset.today),
              _buildPresetChip('أمس', DatePreset.yesterday),
              _buildPresetChip('هذا الأسبوع', DatePreset.thisWeek),
              _buildPresetChip('هذا الشهر', DatePreset.thisMonth),
              _buildPresetChip('هذا العام', DatePreset.thisYear),
              _buildPresetChip('فترة مخصصة...', DatePreset.custom),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const Divider(height: 12),
          Row(
            children: [
              // Date Range Picker
              OutlinedButton.icon(
                onPressed: _pickDateRange,
                icon: const Icon(Icons.calendar_month_outlined, size: 18),
                label: Text(
                  'الفترة: ${_dateFormat.format(_startDate)} - ${_dateFormat.format(_endDate)}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

          // Contextual Filter based on active tab
          if (_tabController.index == 0 || _tabController.index == 1 || _tabController.index == 2) ...[
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<int?>(
                value: _selectedCustomerId,
                decoration: const InputDecoration(
                  labelText: 'تصفية حسب العميل',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('جميع العملاء')),
                  ..._customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                ],
                onChanged: (val) {
                  setState(() => _selectedCustomerId = val);
                  _refreshCurrentTab();
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],

          if (_tabController.index == 3) ...[
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<int?>(
                value: _selectedSupplierId,
                decoration: const InputDecoration(
                  labelText: 'تصفية حسب المورد',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('جميع الموردين')),
                  ..._suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                ],
                onChanged: (val) {
                  setState(() => _selectedSupplierId = val);
                  _refreshCurrentTab();
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],

          if (_tabController.index == 0) ...[
            SizedBox(
              width: 170,
              child: DropdownButtonFormField<String?>(
                value: _selectedSaleStatus,
                decoration: const InputDecoration(
                  labelText: 'حالة الفاتورة',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('كل الحالات')),
                  DropdownMenuItem(value: 'confirmed', child: Text('مؤكدة')),
                  DropdownMenuItem(value: 'reversed', child: Text('ملغاة / معكوسة')),
                ],
                onChanged: (val) {
                  setState(() => _selectedSaleStatus = val);
                  _refreshCurrentTab();
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],

          if (_tabController.index == 4) ...[
            SizedBox(
              width: 190,
              child: DropdownButtonFormField<String?>(
                value: _selectedMovementType,
                decoration: const InputDecoration(
                  labelText: 'نوع الحركة',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('جميع الحركات')),
                  DropdownMenuItem(value: 'sale', child: Text('مبيعات')),
                  DropdownMenuItem(value: 'purchase', child: Text('مشتريات')),
                  DropdownMenuItem(value: 'customer_return', child: Text('مرتجع مبيعات')),
                  DropdownMenuItem(value: 'supplier_return', child: Text('مرتجع مشتريات')),
                  DropdownMenuItem(value: 'adjustment', child: Text('تسوية مخزنية')),
                ],
                onChanged: (val) {
                  setState(() => _selectedMovementType = val);
                  _refreshCurrentTab();
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],

          const Spacer(),
          IconButton(
            tooltip: 'إعادة التحديث',
            icon: Icon(Icons.refresh, color: colors.primary),
            onPressed: _refreshCurrentTab,
          ),
        ],
      ),
    ],
  ),
);
  }

  // 1. Sales Report
  Widget _buildSalesReportView(SalesReport report) {
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      children: [
        Row(
          children: [
            Expanded(
              child: ReportKpiCard(
                title: 'إجمالي المبيعات المؤكدة',
                value: report.totalSales.formatted,
                icon: Icons.monetization_on_outlined,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ReportKpiCard(
                title: 'إجمالي المدفوع فوراً',
                value: report.totalPaid.formatted,
                icon: Icons.check_circle_outline,
                color: colors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ReportKpiCard(
                title: 'إجمالي الآجل المتبقي',
                value: report.totalRemaining.formatted,
                icon: Icons.pending_actions_outlined,
                color: colors.warning,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ReportKpiCard(
                title: 'عدد الفواتير',
                value: '${report.salesCount}',
                icon: Icons.receipt_long_outlined,
                color: colors.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(colors.surfaceElevated),
            columns: const [
              DataColumn(label: Text('رقم الفاتورة')),
              DataColumn(label: Text('التاريخ')),
              DataColumn(label: Text('اسم العميل')),
              DataColumn(label: Text('الإجمالي')),
              DataColumn(label: Text('المدفوع')),
              DataColumn(label: Text('المتبقي')),
              DataColumn(label: Text('الحالة')),
            ],
            rows: report.items.map((item) {
              final isReversed = item.status == 'reversed';
              return DataRow(
                cells: [
                  DataCell(Text('#${item.invoiceNo}', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary))),
                  DataCell(Text(_dateFormat.format(item.saleDate), style: TextStyle(color: colors.textSecondary))),
                  DataCell(Text(item.customerName, style: TextStyle(color: colors.textPrimary))),
                  DataCell(Text(item.totalAmount.formatted, style: TextStyle(color: colors.textPrimary))),
                  DataCell(Text(item.paidAmount.formatted, style: TextStyle(color: colors.textPrimary))),
                  DataCell(Text(
                    item.remainingAmount.formatted,
                    style: TextStyle(
                      color: item.remainingAmount.piastres > 0 ? colors.warning : colors.textSecondary,
                    ),
                  )),
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isReversed ? colors.surfaceElevated : colors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isReversed ? 'ملغاة' : 'مؤكدة',
                      style: TextStyle(
                        fontSize: 12,
                        color: isReversed ? colors.textMuted : colors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  // 2. Collections Report
  Widget _buildCollectionsReportView(CollectionsReport report) {
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      children: [
        Row(
          children: [
            Expanded(
              child: ReportKpiCard(
                title: 'إجمالي المبالغ المحصلة',
                value: report.totalCollected.formatted,
                icon: Icons.payments_outlined,
                color: colors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ReportKpiCard(
                title: 'عدد عمليات التحصيل',
                value: '${report.paymentsCount}',
                icon: Icons.receipt_outlined,
                color: colors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(colors.surfaceElevated),
            columns: const [
              DataColumn(label: Text('التاريخ')),
              DataColumn(label: Text('اسم العميل')),
              DataColumn(label: Text('المبلغ المحصل')),
              DataColumn(label: Text('رقم الفاتورة المرتبطة')),
              DataColumn(label: Text('ملاحظات')),
            ],
            rows: report.items.map((item) {
              return DataRow(
                cells: [
                  DataCell(Text(_dateFormat.format(item.paymentDate), style: TextStyle(color: colors.textSecondary))),
                  DataCell(Text(item.customerName, style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary))),
                  DataCell(Text(
                    item.amount.formatted,
                    style: TextStyle(fontWeight: FontWeight.bold, color: colors.success),
                  )),
                  DataCell(Text(item.linkedSaleInvoiceNo != null ? '#${item.linkedSaleInvoiceNo}' : 'دفعة عامة على الحساب', style: TextStyle(color: colors.textSecondary))),
                  DataCell(Text(item.note ?? '-', style: TextStyle(color: colors.textMuted))),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  // 3. Customer Account Report
  Widget _buildCustomerReportView(CustomerReportLoaded state) {
    final colors = context.colors;
    if (state.accountReport != null) {
      final report = state.accountReport!;
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          Row(
            children: [
              Expanded(
                child: ReportKpiCard(
                  title: 'الرصيد الافتتاحي قبل الفترة',
                  value: report.openingBalance.formatted,
                  icon: Icons.account_balance_outlined,
                  color: colors.info,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ReportKpiCard(
                  title: 'إجمالي المسحوبات (مدين +)',
                  value: report.totalDebit.formatted,
                  icon: Icons.arrow_upward,
                  color: colors.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ReportKpiCard(
                  title: 'إجمالي المسدد (دائن -)',
                  value: report.totalCredit.formatted,
                  icon: Icons.arrow_downward,
                  color: colors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ReportKpiCard(
                  title: 'الرصيد الختامي الحالي',
                  value: report.closingBalance.formatted,
                  icon: Icons.account_balance_wallet,
                  color: report.closingBalance.piastres > 0 ? colors.danger : colors.primary,
                  subtitle: report.closingBalance.piastres > 0 ? 'مستحق على العميل' : 'خالص أو دائن',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(colors.surfaceElevated),
              columns: const [
                DataColumn(label: Text('التاريخ')),
                DataColumn(label: Text('بيان العملية')),
                DataColumn(label: Text('مدين (+)')),
                DataColumn(label: Text('دائن (-)')),
                DataColumn(label: Text('الرصيد بعدها')),
              ],
              rows: report.entries.map((e) {
                return DataRow(
                  cells: [
                    DataCell(Text(_dateFormat.format(e.date), style: TextStyle(color: colors.textSecondary))),
                    DataCell(Text(e.description, style: TextStyle(color: colors.textPrimary))),
                    DataCell(Text(
                      e.debit.piastres > 0 ? e.debit.formatted : '-',
                      style: TextStyle(color: e.debit.piastres > 0 ? colors.warning : colors.textMuted),
                    )),
                    DataCell(Text(
                      e.credit.piastres > 0 ? e.credit.formatted : '-',
                      style: TextStyle(color: e.credit.piastres > 0 ? colors.success : colors.textMuted),
                    )),
                    DataCell(Text(
                      e.balanceAfter.formatted,
                      style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      );
    }

    // List of all customer balances
    final totalDebts = state.allBalances.fold(
      0,
      (sum, c) => sum + (c.hasDebt ? c.balance.piastres : 0),
    );

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      children: [
        Row(
          children: [
            Expanded(
              child: ReportKpiCard(
                title: 'إجمالي الديون المستحقة على العملاء',
                value: Money.fromPiastres(totalDebts).formatted,
                icon: Icons.money_off_outlined,
                color: colors.danger,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ReportKpiCard(
                title: 'عدد العملاء النشطين',
                value: '${state.allBalances.length}',
                icon: Icons.people_outline,
                color: colors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(colors.surfaceElevated),
            columns: const [
              DataColumn(label: Text('العميل')),
              DataColumn(label: Text('رقم الهاتف')),
              DataColumn(label: Text('الرصيد الحسابي')),
              DataColumn(label: Text('الحالة')),
              DataColumn(label: Text('إجراء')),
            ],
            rows: state.allBalances.map((c) {
              return DataRow(
                cells: [
                  DataCell(Text(c.customerName, style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary))),
                  DataCell(Text(c.phone ?? '-', style: TextStyle(color: colors.textSecondary))),
                  DataCell(Text(
                    c.balance.formatted,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: c.hasDebt ? colors.danger : (c.isCreditor ? colors.success : colors.textPrimary),
                    ),
                  )),
                  DataCell(Text(
                    c.hasDebt ? 'مدين (عليه دين)' : (c.isCreditor ? 'دائن (له رصيد)' : 'خالص الحساب'),
                    style: TextStyle(
                      fontSize: 12,
                      color: c.hasDebt ? colors.danger : (c.isCreditor ? colors.success : colors.textMuted),
                    ),
                  )),
                  DataCell(TextButton(
                    onPressed: () {
                      setState(() => _selectedCustomerId = c.customerId);
                      _refreshCurrentTab();
                    },
                    child: Text('عرض كشف الحساب', style: TextStyle(color: colors.primary)),
                  )),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  // 4. Supplier Account Report
  Widget _buildSupplierReportView(SupplierReportLoaded state) {
    final colors = context.colors;
    if (state.accountReport != null) {
      final report = state.accountReport!;
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          Row(
            children: [
              Expanded(
                child: ReportKpiCard(
                  title: 'الرصيد الافتتاحي للمورد',
                  value: report.openingBalance.formatted,
                  icon: Icons.account_balance_outlined,
                  color: colors.info,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ReportKpiCard(
                  title: 'إجمالي المشتريات (دائن +)',
                  value: report.totalCredit.formatted,
                  icon: Icons.arrow_upward,
                  color: colors.danger,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ReportKpiCard(
                  title: 'إجمالي المسدد له (مدين -)',
                  value: report.totalDebit.formatted,
                  icon: Icons.arrow_downward,
                  color: colors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ReportKpiCard(
                  title: 'الرصيد الختامي المستحق للمورد',
                  value: report.closingBalance.formatted,
                  icon: Icons.account_balance_wallet,
                  color: report.closingBalance.piastres > 0 ? colors.danger : colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(colors.surfaceElevated),
              columns: const [
                DataColumn(label: Text('التاريخ')),
                DataColumn(label: Text('بيان العملية')),
                DataColumn(label: Text('مسدد له (مدين -)')),
                DataColumn(label: Text('مشتريات منه (دائن +)')),
                DataColumn(label: Text('الرصيد بعدها')),
              ],
              rows: report.entries.map((e) {
                return DataRow(
                  cells: [
                    DataCell(Text(_dateFormat.format(e.date), style: TextStyle(color: colors.textSecondary))),
                    DataCell(Text(e.description, style: TextStyle(color: colors.textPrimary))),
                    DataCell(Text(
                      e.debit.piastres > 0 ? e.debit.formatted : '-',
                      style: TextStyle(color: e.debit.piastres > 0 ? colors.success : colors.textMuted),
                    )),
                    DataCell(Text(
                      e.credit.piastres > 0 ? e.credit.formatted : '-',
                      style: TextStyle(color: e.credit.piastres > 0 ? colors.danger : colors.textMuted),
                    )),
                    DataCell(Text(
                      e.balanceAfter.formatted,
                      style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      );
    }

    final totalPayables = state.allBalances.fold(
      0,
      (sum, s) => sum + (s.hasBalanceDue ? s.balance.piastres : 0),
    );

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      children: [
        Row(
          children: [
            Expanded(
              child: ReportKpiCard(
                title: 'إجمالي المستحقات للموردين',
                value: Money.fromPiastres(totalPayables).formatted,
                icon: Icons.local_shipping_outlined,
                color: colors.danger,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ReportKpiCard(
                title: 'عدد الموردين النشطين',
                value: '${state.allBalances.length}',
                icon: Icons.business_outlined,
                color: colors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(colors.surfaceElevated),
            columns: const [
              DataColumn(label: Text('المورد')),
              DataColumn(label: Text('رقم الهاتف')),
              DataColumn(label: Text('الرصيد المستحق')),
              DataColumn(label: Text('الحالة')),
              DataColumn(label: Text('إجراء')),
            ],
            rows: state.allBalances.map((s) {
              return DataRow(
                cells: [
                  DataCell(Text(s.supplierName, style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary))),
                  DataCell(Text(s.phone ?? '-', style: TextStyle(color: colors.textSecondary))),
                  DataCell(Text(
                    s.balance.formatted,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: s.hasBalanceDue ? colors.danger : colors.textPrimary,
                    ),
                  )),
                  DataCell(Text(
                    s.hasBalanceDue ? 'مستحق له مبالغ' : 'خالص الحساب',
                    style: TextStyle(
                      fontSize: 12,
                      color: s.hasBalanceDue ? colors.danger : colors.textMuted,
                    ),
                  )),
                  DataCell(TextButton(
                    onPressed: () {
                      setState(() => _selectedSupplierId = s.supplierId);
                      _refreshCurrentTab();
                    },
                    child: Text('عرض كشف الحساب', style: TextStyle(color: colors.primary)),
                  )),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  // 5. Inventory Report
  Widget _buildInventoryReportView(InventoryReport report) {
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      children: [
        Row(
          children: [
            Expanded(
              child: ReportKpiCard(
                title: 'إجمالي القيمة التقديرية للمخزون (بسعر الشراء)',
                value: report.totalValuationAtCost.formatted,
                icon: Icons.inventory_2,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ReportKpiCard(
                title: 'عدد الأصناف في النظام',
                value: '${report.totalProductsCount}',
                icon: Icons.category_outlined,
                color: colors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ReportKpiCard(
                title: 'أصناف بلغت حد الطلب / النواقص',
                value: '${report.lowStockProductsCount}',
                icon: Icons.warning_amber_rounded,
                color: report.lowStockProductsCount > 0 ? colors.danger : colors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'أرصدة وتقييم المنتجات',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(colors.surfaceElevated),
            columns: const [
              DataColumn(label: Text('المنتج')),
              DataColumn(label: Text('الوحدة')),
              DataColumn(label: Text('الرصيد الحالي')),
              DataColumn(label: Text('سعر الشراء')),
              DataColumn(label: Text('سعر البيع')),
              DataColumn(label: Text('إجمالي القيمة')),
              DataColumn(label: Text('الحالة')),
            ],
            rows: report.products.map((p) {
              return DataRow(
                cells: [
                  DataCell(Text(p.productName, style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary))),
                  DataCell(Text(p.unit, style: TextStyle(color: colors.textSecondary))),
                  DataCell(Text(p.currentQuantity.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary))),
                  DataCell(Text(p.currentPurchasePrice.formatted, style: TextStyle(color: colors.textSecondary))),
                  DataCell(Text(p.currentSalePrice.formatted, style: TextStyle(color: colors.textSecondary))),
                  DataCell(Text(p.totalValuationAtCost.formatted, style: TextStyle(color: colors.textPrimary))),
                  DataCell(p.isLowStock
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: colors.danger.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                          child: Text('مخزون منخفض', style: TextStyle(color: colors.danger, fontSize: 11)),
                        )
                      : Text('آمن', style: TextStyle(color: colors.success, fontSize: 12))),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'سجل حركات المخزون الأخيرة',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(colors.surfaceElevated),
            columns: const [
              DataColumn(label: Text('التاريخ')),
              DataColumn(label: Text('المنتج')),
              DataColumn(label: Text('نوع الحركة')),
              DataColumn(label: Text('الكمية (+/-)')),
              DataColumn(label: Text('الرصيد بعدها')),
              DataColumn(label: Text('ملاحظات')),
            ],
            rows: report.movements.map((m) {
              final isPositive = m.quantityDelta > Decimal.zero;
              return DataRow(
                cells: [
                  DataCell(Text(_dateFormat.format(m.date), style: TextStyle(color: colors.textSecondary))),
                  DataCell(Text(m.productName, style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary))),
                  DataCell(Text(m.movementType, style: TextStyle(color: colors.textSecondary))),
                  DataCell(Text(
                    '${isPositive ? '+' : ''}${m.quantityDelta}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPositive ? colors.success : colors.danger,
                    ),
                  )),
                  DataCell(Text(m.balanceAfter.toString(), style: TextStyle(color: colors.textPrimary))),
                  DataCell(Text(m.note ?? '-', style: TextStyle(color: colors.textMuted))),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  // 6. Cashbox Report
  Widget _buildCashboxReportView(CashboxReport report) {
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      children: [
        Row(
          children: [
            Expanded(
              child: ReportKpiCard(
                title: 'رصيد البداية للفترة',
                value: report.openingBalance.formatted,
                icon: Icons.account_balance,
                color: colors.info,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ReportKpiCard(
                title: 'إجمالي المقبوضات (وارد +)',
                value: report.totalIn.formatted,
                icon: Icons.arrow_downward,
                color: colors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ReportKpiCard(
                title: 'إجمالي المدفوعات (صادر -)',
                value: report.totalOut.formatted,
                icon: Icons.arrow_upward,
                color: colors.danger,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ReportKpiCard(
                title: 'صافي التدفق النقدي',
                value: report.netCashflow.formatted,
                icon: Icons.swap_horiz,
                color: report.netCashflow.piastres >= 0 ? colors.success : colors.danger,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ReportKpiCard(
                title: 'الرصيد الختامي للخزينة',
                value: report.closingBalance.formatted,
                icon: Icons.savings_outlined,
                color: colors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(colors.surfaceElevated),
            columns: const [
              DataColumn(label: Text('التاريخ')),
              DataColumn(label: Text('نوع الحركة')),
              DataColumn(label: Text('وارد (+)')),
              DataColumn(label: Text('صادر (-)')),
              DataColumn(label: Text('الرصيد بعدها')),
              DataColumn(label: Text('ملاحظات')),
            ],
            rows: report.transactions.map((t) {
              final isIn = t.direction == 'in';
              return DataRow(
                cells: [
                  DataCell(Text(_dateFormat.format(t.date), style: TextStyle(color: colors.textSecondary))),
                  DataCell(Text(t.transactionType, style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary))),
                  DataCell(Text(
                    isIn ? t.amount.formatted : '-',
                    style: TextStyle(color: colors.success, fontWeight: FontWeight.bold),
                  )),
                  DataCell(Text(
                    !isIn ? t.amount.formatted : '-',
                    style: TextStyle(color: colors.danger, fontWeight: FontWeight.bold),
                  )),
                  DataCell(Text(
                    t.balanceAfter.formatted,
                    style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
                  )),
                  DataCell(Text(t.note ?? '-', style: TextStyle(color: colors.textMuted))),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  // 7. Profit & Gross Margin Report
  Widget _buildProfitReportView(ProfitReport report) {
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      children: [
        Row(
          children: [
            Expanded(
              child: ReportKpiCard(
                title: 'إجمالي المبيعات (الإيراد)',
                value: report.totalRevenue.formatted,
                icon: Icons.monetization_on_outlined,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ReportKpiCard(
                title: 'تكلفة البضاعة المباعة (COGS)',
                value: report.totalCost.formatted,
                icon: Icons.inventory_outlined,
                color: colors.info,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ReportKpiCard(
                title: 'مجمل أرباح النشاط',
                value: report.totalGrossProfit.formatted,
                icon: Icons.savings_outlined,
                color: report.totalGrossProfit.piastres >= 0 ? colors.success : colors.danger,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ReportKpiCard(
                title: 'نسبة هامش الربح الإجمالي',
                value: '${report.overallMarginPercentage.toStringAsFixed(1)}%',
                icon: Icons.trending_up,
                color: report.overallMarginPercentage >= 0 ? colors.success : colors.danger,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ReportKpiCard(
                title: 'عدد الأصناف المباعة',
                value: '${report.items.length}',
                icon: Icons.category_outlined,
                color: colors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.leaderboard_outlined, color: colors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'تحليل أرباح ومساهمة كل منتج مباع',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (report.items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: Text(
                        'لا توجد مبيعات مؤكدة في الفترة المحددة لحساب الأرباح والهوامش',
                        style: TextStyle(color: colors.textSecondary, fontSize: 14),
                      ),
                    ),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(colors.surfaceElevated),
                      columns: const [
                        DataColumn(label: Text('#')),
                        DataColumn(label: Text('اسم المنتج')),
                        DataColumn(label: Text('الوحدة')),
                        DataColumn(label: Text('الكمية المباعة')),
                        DataColumn(label: Text('إجمالي المبيعات')),
                        DataColumn(label: Text('إجمالي التكلفة')),
                        DataColumn(label: Text('مجمل الربح')),
                        DataColumn(label: Text('هامش الربح %')),
                      ],
                      rows: report.items.asMap().entries.map((entry) {
                        final index = entry.key + 1;
                        final item = entry.value;
                        final isProfitable = item.grossProfit.piastres >= 0;
                        return DataRow(
                          cells: [
                            DataCell(Text('$index', style: TextStyle(color: colors.textSecondary))),
                            DataCell(Text(item.productName, style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary))),
                            DataCell(Text(item.unit, style: TextStyle(color: colors.textSecondary))),
                            DataCell(Text(item.soldQuantity.toString(), style: TextStyle(color: colors.textPrimary))),
                            DataCell(Text(item.totalRevenue.formatted, style: TextStyle(color: colors.textPrimary))),
                            DataCell(Text(item.totalCost.formatted, style: TextStyle(color: colors.textPrimary))),
                            DataCell(
                              Text(
                                item.grossProfit.formatted,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isProfitable ? colors.success : colors.danger,
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (isProfitable ? colors.success : colors.danger).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${item.marginPercentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isProfitable ? colors.success : colors.danger,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
