import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/update_cubit.dart';
import '../cubit/update_state.dart';

class UpdateDialog extends StatelessWidget {
  const UpdateDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocConsumer<UpdateCubit, UpdateState>(
      listener: (context, state) {
        // If dismissed or reset from outside
        if (state.status == UpdateStatus.initial) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      },
      builder: (context, state) {
        final updateInfo = state.updateInfo;
        final isRequired = updateInfo?.isRequired ?? false;
        final isDownloading = state.status == UpdateStatus.downloading;
        final isReady = state.status == UpdateStatus.readyToInstall;
        final isError = state.status == UpdateStatus.error;

        return PopScope(
          canPop: !isRequired && !isDownloading,
          child: Dialog(
            backgroundColor: colors.surface,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              side: BorderSide(color: colors.border, width: 1.5),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520, minWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header with Icon & Title
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(
                              color: colors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Icon(
                            Icons.system_update_rounded,
                            color: colors.primary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.updateAvailableTitle,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'تحديث هوائي فوري للنظام',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isRequired && !isDownloading)
                          IconButton(
                            icon: Icon(Icons.close_rounded, color: colors.textMuted),
                            onPressed: () {
                              context.read<UpdateCubit>().dismissDialog();
                              Navigator.of(context).pop();
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Version Compare Badges
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: colors.surfaceElevated,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildVersionBadge(
                            label: AppStrings.currentVersion,
                            version: state.currentVersion.isNotEmpty
                                ? state.currentVersion
                                : '1.0.0',
                            isNew: false,
                            colors: colors,
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
                            color: colors.textMuted,
                          ),
                          _buildVersionBadge(
                            label: AppStrings.newVersion,
                            version: updateInfo?.version ?? '',
                            isNew: true,
                            colors: colors,
                          ),
                        ],
                      ),
                    ),

                    if (isRequired) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.error_outline_rounded,
                                color: AppColors.danger, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppStrings.updateRequiredNotice,
                                style: TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.md),

                    // Release notes
                    if (updateInfo?.releaseNotes != null &&
                        updateInfo!.releaseNotes!.trim().isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          AppStrings.releaseNotes,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 140),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.background,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(color: colors.border),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            updateInfo.releaseNotes!,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Downloading state progress bar
                    if (isDownloading) ...[
                      Text(
                        AppStrings.downloadingUpdate,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        child: LinearProgressIndicator(
                          value: state.downloadProgress > 0 ? state.downloadProgress : null,
                          minHeight: 10,
                          backgroundColor: colors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          state.downloadProgress > 0
                              ? '${(state.downloadProgress * 100).toStringAsFixed(1)}%'
                              : 'جاري التجهيز...',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],

                    // Ready to install message
                    if (isReady) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: AppColors.success, size: 22),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                AppStrings.updateReadyToInstall,
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],

                    // Error state message
                    if (isError) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppColors.danger, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.errorMessage ?? AppStrings.updateDownloadFailed,
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],

                    const SizedBox(height: AppSpacing.md),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!isRequired && !isDownloading && !isReady)
                          TextButton(
                            onPressed: () {
                              context.read<UpdateCubit>().dismissDialog();
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              AppStrings.later,
                              style: TextStyle(color: colors.textSecondary),
                            ),
                          ),
                        if (!isRequired && !isDownloading && !isReady)
                          const SizedBox(width: AppSpacing.sm),
                        if (state.status == UpdateStatus.available || isError)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: colors.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              ),
                            ),
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: const Text(
                              AppStrings.downloadUpdate,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              context.read<UpdateCubit>().downloadUpdate();
                            },
                          ),
                        if (isReady)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              ),
                            ),
                            icon: const Icon(Icons.restart_alt_rounded, size: 18),
                            label: const Text(
                              AppStrings.installNow,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              context.read<UpdateCubit>().installUpdate();
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVersionBadge({
    required String label,
    required String version,
    required bool isNew,
    required AppPalette colors,
  }) {
    return Column(
      crossAxisAlignment: isNew ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isNew
                ? colors.primary.withValues(alpha: 0.2)
                : colors.border.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: isNew
                  ? colors.primary.withValues(alpha: 0.4)
                  : colors.border,
            ),
          ),
          child: Text(
            version,
            style: TextStyle(
              color: isNew ? colors.primary : colors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
