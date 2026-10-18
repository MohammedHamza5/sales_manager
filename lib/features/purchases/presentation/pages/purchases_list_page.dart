import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/states/empty_view.dart';
import '../../../../core/widgets/states/error_view.dart';
import '../../../../core/widgets/states/loading_view.dart';
import '../../../../core/widgets/app_kpi_card.dart';
import '../../domain/entities/purchase.dart';
import '../cubit/purchases_list_cubit.dart';
import '../cubit/purchases_list_state.dart';

class PurchasesListPage extends StatefulWidget {
  const PurchasesListPage({super.key});

  @override
  State<PurchasesListPage> createState() => _PurchasesListPageState();
}

class _PurchasesListPageState extends State<PurchasesListPage> {
  late final PurchasesListCubit _cubit;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _cubit = PurchasesListCubit(
      watchPurchasesUseCase: getIt(),
      reversePurchaseUseCase: getIt(),
    )..init();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _cubit.close();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: colors.background,
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(context),
              const SizedBox(height: 20),
              Expanded(
                child: BlocBuilder<PurchasesListCubit, PurchasesListState>(
                  builder: (context, state) {
                    return switch (state) {
                      PurchasesListInitial() ||
                      PurchasesListLoading() =>
                        const LoadingView(message: 'جاري تحميل فواتير المشتريات...'),
                      PurchasesListEmpty(:final message) => EmptyView(
                          title: message,
                          actionLabel: 'فاتورة شراء جديدة',
                          onAction: () => context.go('/purchases/create'),
                        ),
                      PurchasesListError(:final message) => ErrorView(
                          message: message,
                          onRetry: () => _cubit.init(),
                        ),
                      PurchasesListLoaded() => _buildLoadedView(context, state),
                    };
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final colors = context.colors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إدارة المشتريات',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'سجل فواتير الشراء من الموردين وتتبع الأثر المخزني والمالي',
                style: TextStyle(fontSize: 14, color: colors.textSecondary),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: () => context.go('/purchases/create'),
          icon: const Icon(Icons.add),
          label: const Text('فاتورة شراء جديدة (F2)'),
          style: FilledButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadedView(BuildContext context, PurchasesListLoaded state) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildKpisRow(context, state),
        const SizedBox(height: 16),
        _buildFiltersRow(context, state),
        const SizedBox(height: 16),
        Expanded(
          child: state.filteredPurchases.isEmpty
              ? Center(
                  child: Text(
                    'لا توجد فواتير مطابقة للبحث أو التصفية الحالية',
                    style: TextStyle(color: colors.textSecondary, fontSize: 16),
                  ),
                )
              : _buildPurchasesTable(context, state.filteredPurchases),
        ),
      ],
    );
  }

  Widget _buildKpisRow(BuildContext context, PurchasesListLoaded state) {
    final colors = context.colors;

    return Row(
      children: [
        Expanded(
          child: AppKpiCard(
            title: 'إجمالي المشتريات',
            value: state.totalPurchasesAmount.formatted,
            icon: Icons.shopping_bag_outlined,
            color: colors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AppKpiCard(
            title: 'المدفوع نقداً',
            value: state.totalPaidAmount.formatted,
            icon: Icons.payments_outlined,
            color: colors.success,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AppKpiCard(
            title: 'المستحقات المتبقية',
            value: state.totalRemainingAmount.formatted,
            icon: Icons.account_balance_wallet_outlined,
            color: colors.danger,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AppKpiCard(
            title: 'عدد الفواتير',
            value: '${state.confirmedCount} مؤكدة',
            icon: Icons.receipt_long_outlined,
            color: const Color(0xFF0284C7),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersRow(BuildContext context, PurchasesListLoaded state) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          // Search field
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'بحث برقم الفاتورة، اسم المورد...',
                hintStyle: TextStyle(color: colors.textMuted),
                prefixIcon: Icon(Icons.search, color: colors.textMuted),
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
                isDense: true,
              ),
              onChanged: (val) => _cubit.search(val),
            ),
          ),
          const SizedBox(width: 16),
          // Status filter chips
          _buildFilterChip(
            context: context,
            label: 'الكل',
            isSelected: state.statusFilter == null,
            onSelected: () => _cubit.filterByStatus(null),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context: context,
            label: 'مؤكدة',
            isSelected: state.statusFilter == PurchaseStatus.confirmed,
            onSelected: () => _cubit.filterByStatus(PurchaseStatus.confirmed),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context: context,
            label: 'معكوسة ومُلغاة',
            isSelected: state.statusFilter == PurchaseStatus.reversed,
            onSelected: () => _cubit.filterByStatus(PurchaseStatus.reversed),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    final colors = context.colors;

    return ChoiceChip(
      label: Text(label),
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
      onSelected: (_) => onSelected(),
    );
  }

  Widget _buildPurchasesTable(BuildContext context, List<Purchase> purchases) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.separated(
          itemCount: purchases.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: colors.border),
          itemBuilder: (context, index) {
            final p = purchases[index];
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: p.isConfirmed
                    ? colors.primary.withValues(alpha: 0.15)
                    : colors.danger.withValues(alpha: 0.12),
                child: Icon(
                  p.isConfirmed ? Icons.receipt : Icons.undo,
                  color: p.isConfirmed ? colors.primary : colors.danger,
                ),
              ),
              title: Row(
                children: [
                  Text(
                    'فاتورة #${p.invoiceNo}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'monospace'),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    p.supplierName,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    p.totalAmount.formatted,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              subtitle: Row(
                children: [
                  Text(
                    '${p.purchaseDate.year}/${p.purchaseDate.month.toString().padLeft(2, '0')}/${p.purchaseDate.day.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 12, color: colors.textMuted),
                  ),
                  const SizedBox(width: 16),
                  _buildPaymentBadge(context, p),
                  const Spacer(),
                  Text(
                    'المدفوع: ${p.paidAmountAtCreation.formatted} · المتبقي: ${p.remainingAmount.formatted}',
                    style: TextStyle(fontSize: 12, color: colors.textMuted),
                  ),
                ],
              ),
              trailing: Icon(Icons.chevron_left, color: colors.textSecondary),
              onTap: () => context.go('/purchases/${p.id}'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPaymentBadge(BuildContext context, Purchase p) {
    final colors = context.colors;

    if (p.isReversed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: colors.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.danger.withValues(alpha: 0.3)),
        ),
        child: Text(
          'ملغاة',
          style: TextStyle(
            color: colors.danger,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (p.isFullyPaid) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: colors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.success.withValues(alpha: 0.3)),
        ),
        child: Text(
          'نقدي كامل',
          style: TextStyle(
            color: colors.success,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (p.isPartial) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: colors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
        ),
        child: Text(
          'سداد جزئي',
          style: TextStyle(
            color: colors.warning,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.danger.withValues(alpha: 0.3)),
      ),
      child: Text(
        'آجل بالكامل',
        style: TextStyle(
          color: colors.danger,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
