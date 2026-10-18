import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/states/error_view.dart';
import '../../../../core/widgets/states/loading_view.dart';
import '../cubit/backup_restore_cubit.dart';
import '../cubit/backup_restore_state.dart';

class BackupRestorePage extends StatelessWidget {
  const BackupRestorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BackupRestoreCubit(
        createManualBackupUseCase: getIt(),
        exportBackupUseCase: getIt(),
        createAutoBackupUseCase: getIt(),
        restoreBackupUseCase: getIt(),
        getBackupHistoryUseCase: getIt(),
        manageBackupSettingsUseCase: getIt(),
      )..load(),
      child: const _BackupRestoreView(),
    );
  }
}

class _BackupRestoreView extends StatelessWidget {
  const _BackupRestoreView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: BlocConsumer<BackupRestoreCubit, BackupRestoreState>(
        listener: (context, state) {
          if (state is BackupRestoreLoaded) {
            if (state.operationSuccessMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.operationSuccessMessage!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: colors.success,
                  duration: const Duration(seconds: 5),
                ),
              );
              context.read<BackupRestoreCubit>().clearOperationMessage();
            } else if (state.operationErrorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.operationErrorMessage!),
                  backgroundColor: colors.danger,
                  duration: const Duration(seconds: 5),
                ),
              );
              context.read<BackupRestoreCubit>().clearOperationMessage();
            }
          }
        },
        builder: (context, state) {
          return switch (state) {
            BackupRestoreInitial() || BackupRestoreLoading() => const LoadingView(
                message: 'جاري تحميل إعدادات وسجل النسخ الاحتياطي...',
              ),
            BackupRestoreError(:final message) => ErrorView(
                message: message,
                onRetry: () => context.read<BackupRestoreCubit>().load(),
              ),
            BackupRestoreLoaded() => _buildLoadedBody(context, state),
          };
        },
      ),
    );
  }

  Widget _buildLoadedBody(BuildContext context, BackupRestoreLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopBar(context),
          AppSpacing.verticalLg,

          // Row with Manual Actions & Auto Backup Settings
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildManualBackupCard(context, state)),
              AppSpacing.horizontalLg,
              Expanded(child: _buildAutoBackupCard(context, state)),
            ],
          ),
          AppSpacing.verticalLg,

          // Restore Section
          _buildRestoreSection(context, state),
          AppSpacing.verticalLg,

          // History Table
          _buildHistoryTable(context, state),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final colors = context.colors;
    return Row(
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
              child: Icon(Icons.settings_backup_restore_rounded, color: colors.primary, size: 28),
            ),
            AppSpacing.horizontalMd,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.backupRestore,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  'إدارة النسخ الاحتياطي لقاعدة البيانات، التصدير الخارجي، والاستعادة الآمنة',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        IconButton.filledTonal(
          onPressed: () => context.read<BackupRestoreCubit>().load(),
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'تحديث البيانات',
        ),
      ],
    );
  }

  Widget _buildManualBackupCard(BuildContext context, BackupRestoreLoaded state) {
    final colors = context.colors;
    return Container(
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
                Icon(Icons.backup_outlined, color: colors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  AppStrings.manualBackup,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'إنشاء نسخة احتياطية فورية وحفظها في أي مجلد تختاره على جهازك أو تصديرها لوحدة تخزين خارجية.',
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            AppSpacing.verticalLg,
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: state.isOperating
                      ? null
                      : () => context.read<BackupRestoreCubit>().createManualBackup(),
                  icon: state.isOperating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: const Text(AppStrings.createBackup),
                ),
                OutlinedButton.icon(
                  onPressed: state.isOperating
                      ? null
                      : () => context.read<BackupRestoreCubit>().exportBackupToUsb(),
                  icon: const Icon(Icons.usb_rounded, size: 18),
                  label: const Text(AppStrings.exportToUsb),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoBackupCard(BuildContext context, BackupRestoreLoaded state) {
    final colors = context.colors;
    return Container(
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
                Icon(Icons.schedule_rounded, color: colors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  AppStrings.autoBackup,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                AppStrings.enableAutoBackup,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'يتم أخذ نسخة احتياطية تلقائياً في مجلد التطبيق الداخلي عند بدء التشغيل',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
              value: state.autoBackupEnabled,
              onChanged: (val) =>
                  context.read<BackupRestoreCubit>().toggleAutoBackup(val),
            ),
            const Divider(height: 16),
            Row(
              children: [
                Text(
                  '${AppStrings.autoBackupRetention}: ${state.retentionCount} نسخ',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Slider(
              value: state.retentionCount.toDouble(),
              min: 1,
              max: 30,
              divisions: 29,
              label: '${state.retentionCount} نسخ',
              onChanged: (val) =>
                  context.read<BackupRestoreCubit>().setRetentionCount(val.toInt()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestoreSection(BuildContext context, BackupRestoreLoaded state) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.warning.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.warning_amber_rounded, color: colors.warning, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                AppStrings.restoreBackup,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'تنبيه: استعادة نسخة احتياطية ستقوم باستبدال كافة البيانات الحالية. '
            'يتم أخذ نسخة أمان احترازية تلقائياً قبل البدء بالاستعادة لضمان عدم فقدان أي بيانات.',
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          AppSpacing.verticalMd,
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.warning,
              foregroundColor: Colors.white,
            ),
            onPressed: state.isOperating
                ? null
                : () async {
                    final result = await FilePicker.pickFiles(
                      dialogTitle: AppStrings.chooseBackupFile,
                      type: FileType.custom,
                      allowedExtensions: ['sqlite', 'db'],
                    );
                    if (result != null && result.files.single.path != null) {
                      final selectedPath = result.files.single.path!;
                      if (context.mounted) {
                        _showRestoreConfirmationDialog(context, selectedPath);
                      }
                    }
                  },
            icon: const Icon(Icons.restore_page_rounded, size: 18),
            label: const Text(AppStrings.chooseBackupFile),
          ),
        ],
      ),
    );
  }

  void _showRestoreConfirmationDialog(BuildContext context, String backupPath) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        final colors = dialogCtx.colors;
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Row(
            children: [
              Icon(Icons.warning_rounded, color: colors.danger),
              const SizedBox(width: 8),
              const Text(AppStrings.restoreWarningTitle),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(AppStrings.restoreWarningMessage),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'الملف المختار: $backupPath',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text(AppStrings.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                context.read<BackupRestoreCubit>().restoreBackup(backupPath);
              },
              child: const Text('تأكيد الاستعادة والاستبدال'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistoryTable(BuildContext context, BackupRestoreLoaded state) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.table_rows_rounded, color: colors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  AppStrings.backupHistory,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            AppSpacing.verticalMd,
            if (state.history.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'لا يوجد سجل نسخ احتياطية مسجل حتى الآن',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(colors.surfaceElevated),
                  columns: const [
                    DataColumn(label: Text('المعرف')),
                    DataColumn(label: Text(AppStrings.performedAt)),
                    DataColumn(label: Text(AppStrings.backupType)),
                    DataColumn(label: Text(AppStrings.backupSize)),
                    DataColumn(label: Text(AppStrings.backupPath)),
                    DataColumn(label: Text(AppStrings.actions)),
                  ],
                  rows: state.history.map((item) {
                    return DataRow(
                      cells: [
                        DataCell(Text('#${item.id}')),
                        DataCell(Text(_formatDate(item.createdAt))),
                        DataCell(_buildTypeBadge(context, item.type)),
                        DataCell(Text(item.formattedSize)),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 320),
                            child: Text(
                              item.filePath,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        DataCell(
                          TextButton.icon(
                            onPressed: state.isOperating
                                ? null
                                : () => _showRestoreConfirmationDialog(
                                      context,
                                      item.filePath,
                                    ),
                            icon: const Icon(Icons.restore_rounded, size: 16),
                            label: const Text('استعادة هذه النسخة'),
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
    );
  }

  Widget _buildTypeBadge(BuildContext context, String type) {
    final colors = context.colors;
    Color bg;
    Color text;
    String label;

    switch (type.toLowerCase()) {
      case 'manual':
        bg = colors.primaryLight;
        text = colors.primary;
        label = AppStrings.backupManual;
        break;
      case 'auto':
        bg = colors.success.withValues(alpha: 0.15);
        text = colors.success;
        label = AppStrings.backupAuto;
        break;
      case 'export':
        bg = colors.info.withValues(alpha: 0.15);
        text = colors.info;
        label = AppStrings.backupExport;
        break;
      case 'safety':
        bg = colors.warning.withValues(alpha: 0.15);
        text = colors.warning;
        label = 'نسخة أمان احترازية';
        break;
      default:
        bg = colors.surfaceElevated;
        text = colors.textSecondary;
        label = type;
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
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
