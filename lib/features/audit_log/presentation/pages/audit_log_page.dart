import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/states/empty_view.dart';
import '../../../../core/widgets/states/error_view.dart';
import '../../../../core/widgets/states/loading_view.dart';
import '../../domain/entities/audit_entry.dart';
import '../cubit/audit_log_cubit.dart';
import '../cubit/audit_log_state.dart';
import '../widgets/audit_detail_dialog.dart';

class AuditLogPage extends StatelessWidget {
  const AuditLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuditLogCubit(
        getAuditLogsUseCase: getIt(),
      )..loadAuditLogs(),
      child: const _AuditLogView(),
    );
  }
}

class _AuditLogView extends StatefulWidget {
  const _AuditLogView();

  @override
  State<_AuditLogView> createState() => _AuditLogViewState();
}

class _AuditLogViewState extends State<_AuditLogView> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar
            _buildTopBar(context),
            AppSpacing.verticalMd,

            // Filter Bar
            _buildFilterBar(context),
            AppSpacing.verticalMd,

            // Main Content Area (4 Mandatory States)
            Expanded(
              child: BlocBuilder<AuditLogCubit, AuditLogState>(
                builder: (context, state) {
                  return switch (state) {
                    AuditLogInitial() || AuditLogLoading() => const LoadingView(
                        message: 'جاري تحميل سجل التتبع والعمليات...',
                      ),
                    AuditLogEmpty(:final message) => EmptyView(
                        title: message,
                        icon: Icons.history_toggle_off_rounded,
                        actionLabel: 'إعادة ضبط الفلاتر',
                        onAction: () {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                          });
                          context.read<AuditLogCubit>().clearFilters();
                        },
                      ),
                    AuditLogError(:final message) => ErrorView(
                        message: message,
                        onRetry: () => context.read<AuditLogCubit>().loadAuditLogs(),
                      ),
                    AuditLogLoaded(:final entries) => _buildTable(context, entries),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.history_edu_rounded, color: colors.primary, size: 24),
                ),
                AppSpacing.horizontalMd,
                Text(
                  AppStrings.auditLog,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.auditLogSubtitle,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
        IconButton.filledTonal(
          onPressed: () => context.read<AuditLogCubit>().loadAuditLogs(),
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'تحديث السجل',
        ),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final colors = context.colors;
    return BlocBuilder<AuditLogCubit, AuditLogState>(
      builder: (context, state) {
        final currentEntity = state is AuditLogLoaded ? state.selectedEntityType : 'all';
        final currentAction = state is AuditLogLoaded ? state.selectedAction : 'all';

        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Entity Type Dropdown
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    value: currentEntity,
                    isDense: true,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: AppStrings.entityType,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('كافة الكيانات', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'product', child: Text('المنتجات', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'customer', child: Text('العملاء', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'supplier', child: Text('الموردون', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'sale', child: Text('المبيعات', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'purchase', child: Text('المشتريات', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'payment', child: Text('المدفوعات والتحصيلات', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'cashbox', child: Text('الخزينة', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'expense', child: Text('المصروفات', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'return', child: Text('المرتجعات', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'adjustment', child: Text('تسويات المخزون', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'opening_balance', child: Text('الأرصدة الافتتاحية', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        context.read<AuditLogCubit>().filterByEntityType(value);
                      }
                    },
                  ),
                ),

                // Action Dropdown
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    value: currentAction,
                    isDense: true,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: AppStrings.actionType,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('كافة الإجراءات', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'create', child: Text('إنشاء / إضافة', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'update', child: Text('تعديل', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'cancel', child: Text('إلغاء', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'reverse', child: Text('عكس عملية', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'activate', child: Text('تفعيل', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'deactivate', child: Text('تعطيل', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        context.read<AuditLogCubit>().filterByAction(value);
                      }
                    },
                  ),
                ),

                // Date From / To Button
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDateRange: _startDate != null && _endDate != null
                          ? DateTimeRange(start: _startDate!, end: _endDate!)
                          : null,
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked.start;
                        _endDate = picked.end.add(const Duration(hours: 23, minutes: 59, seconds: 59));
                      });
                      if (context.mounted) {
                        context.read<AuditLogCubit>().filterByDateRange(_startDate, _endDate);
                      }
                    }
                  },
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: Text(
                    _startDate != null && _endDate != null
                        ? '${_formatDateShort(_startDate!)} — ${_formatDateShort(_endDate!)}'
                        : 'تصفية بالتاريخ',
                  ),
                ),

                // Clear Filters
                if (currentEntity != 'all' || currentAction != 'all' || _startDate != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                      context.read<AuditLogCubit>().clearFilters();
                    },
                    icon: const Icon(Icons.clear_all_rounded, size: 18),
                    label: const Text('مسح الفلاتر'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTable(BuildContext context, List<AuditEntry> entries) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    colors.surfaceElevated,
                  ),
                  showCheckboxColumn: false,
                  columns: const [
                    DataColumn(label: Text('المعرف')),
                    DataColumn(label: Text(AppStrings.performedAt)),
                    DataColumn(label: Text(AppStrings.entityType)),
                    DataColumn(label: Text(AppStrings.actionType)),
                    DataColumn(label: Text('رقم المعاملة')),
                    DataColumn(label: Text(AppStrings.performedBy)),
                    DataColumn(label: Text(AppStrings.notes)),
                    DataColumn(label: Text(AppStrings.actions)),
                  ],
                  rows: entries.map((entry) {
                    return DataRow(
                      onSelectChanged: (_) => AuditDetailDialog.show(context, entry),
                      cells: [
                        DataCell(Text('#${entry.id}', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary))),
                        DataCell(Text(_formatDateFull(entry.performedAt), style: TextStyle(color: colors.textSecondary))),
                        DataCell(_buildEntityBadge(context, entry.entityType)),
                        DataCell(_buildActionBadge(context, entry.action)),
                        DataCell(Text('#${entry.entityId}', style: TextStyle(color: colors.textPrimary))),
                        DataCell(Text(entry.userId, style: TextStyle(color: colors.textSecondary))),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Text(
                              entry.note ?? '—',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: colors.textMuted),
                            ),
                          ),
                        ),
                        DataCell(
                          IconButton(
                            icon: Icon(Icons.visibility_outlined, size: 18, color: colors.primary),
                            tooltip: 'عرض تفاصيل العملية',
                            onPressed: () => AuditDetailDialog.show(context, entry),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntityBadge(BuildContext context, String entityType) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.primaryLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        entityType,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colors.primary,
        ),
      ),
    );
  }

  Widget _buildActionBadge(BuildContext context, String action) {
    final colors = context.colors;
    Color bg;
    Color text;
    String label;

    switch (action.toLowerCase()) {
      case 'create':
        bg = colors.success.withValues(alpha: 0.15);
        text = colors.success;
        label = 'إنشاء';
        break;
      case 'update':
        bg = colors.warning.withValues(alpha: 0.15);
        text = colors.warning;
        label = 'تعديل';
        break;
      case 'cancel':
      case 'reverse':
        bg = colors.danger.withValues(alpha: 0.15);
        text = colors.danger;
        label = 'إلغاء / عكس';
        break;
      default:
        bg = colors.surfaceElevated;
        text = colors.textSecondary;
        label = action;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: text.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }

  String _formatDateShort(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }

  String _formatDateFull(DateTime dt) {
    return '${_formatDateShort(dt)} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
