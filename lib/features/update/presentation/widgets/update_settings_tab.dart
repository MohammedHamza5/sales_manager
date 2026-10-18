import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/update_cubit.dart';
import '../cubit/update_state.dart';

class UpdateSettingsTab extends StatelessWidget {
  const UpdateSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocConsumer<UpdateCubit, UpdateState>(
      listener: (context, state) {
        if (state.isManualCheck && state.status == UpdateStatus.noUpdate) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.appUpToDate),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 3),
            ),
          );
        } else if (state.status == UpdateStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.danger,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      builder: (context, state) {
        final isChecking = state.status == UpdateStatus.checking;
        final isDownloading = state.status == UpdateStatus.downloading;
        final isReady = state.status == UpdateStatus.readyToInstall;
        final isAvailable = state.status == UpdateStatus.available;
        final isNoUpdate = state.status == UpdateStatus.noUpdate;
        final isError = state.status == UpdateStatus.error;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main Version Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
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
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.systemUpdates,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${AppStrings.currentVersion}: v${state.currentVersion.isNotEmpty ? state.currentVersion : '1.0.0'}',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                      icon: isChecking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            )
                          : const Icon(Icons.refresh_rounded, size: 20),
                      label: Text(
                        isChecking
                            ? AppStrings.checkingForUpdates
                            : AppStrings.checkForUpdates,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: isChecking || isDownloading
                          ? null
                          : () {
                              context.read<UpdateCubit>().checkForUpdates(isManual: true);
                            },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Status Card
              if (isChecking)
                _buildStatusContainer(
                  colors: colors,
                  icon: Icons.sync_rounded,
                  iconColor: colors.primary,
                  title: AppStrings.checkingForUpdates,
                  subtitle: 'يتم الاتصال بالسيرفر والتحقق من وجود إصدارات أحدث...',
                ),

              if (isNoUpdate)
                _buildStatusContainer(
                  colors: colors,
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: AppColors.success,
                  title: AppStrings.appUpToDate,
                  subtitle: 'النظام يعمل بأحدث نسخة رسمية مستقرة.',
                ),

              if (isError)
                _buildStatusContainer(
                  colors: colors,
                  icon: Icons.error_outline_rounded,
                  iconColor: AppColors.danger,
                  title: 'تعذر التحقق من التحديثات',
                  subtitle: state.errorMessage ?? 'تأكد من الاتصال بالإنترنت وحاول مرة أخرى.',
                  action: ElevatedButton(
                    onPressed: () {
                      context.read<UpdateCubit>().checkForUpdates(isManual: true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('إعادة المحاولة'),
                  ),
                ),

              if (isAvailable || isDownloading || isReady) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.new_releases_rounded, color: colors.primary, size: 24),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'إصدار جديد متاح: v${state.updateInfo?.version}',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (state.updateInfo?.isRequired ?? false)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                border: Border.all(color: AppColors.danger),
                              ),
                              child: const Text(
                                'تحديث إلزامي',
                                style: TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (state.updateInfo?.releaseNotes != null &&
                          state.updateInfo!.releaseNotes!.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          AppStrings.releaseNotes,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.surfaceElevated,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            border: Border.all(color: colors.border),
                          ),
                          child: Text(
                            state.updateInfo!.releaseNotes!,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),

                      if (isDownloading) ...[
                        Text(
                          AppStrings.downloadingUpdate,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
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
                        Text(
                          state.downloadProgress > 0
                              ? '${(state.downloadProgress * 100).toStringAsFixed(1)}%'
                              : 'جاري التجهيز...',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],

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
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                              vertical: AppSpacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                          ),
                          icon: const Icon(Icons.restart_alt_rounded),
                          label: const Text(
                            AppStrings.installNow,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            context.read<UpdateCubit>().installUpdate();
                          },
                        ),
                      ],

                      if (isAvailable) ...[
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                              vertical: AppSpacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                          ),
                          icon: const Icon(Icons.download_rounded),
                          label: const Text(
                            AppStrings.downloadUpdate,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            context.read<UpdateCubit>().downloadUpdate();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Educational / Information Notice
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: colors.textSecondary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'حول نظام التحديثات الهوائية (OTA Updates)',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'يتيح هذا النظام تنزيل أحدث المزايا والتحسينات وإصلاحات الأخطاء البرمجية تلقائياً دون الحاجة لإعادة تثبيت البرنامج يدوياً أو فقدان أي بيانات محلية. يتم التثبيت في الخلفية وإعادة تشغيل التطبيق بسلاسة.',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusContainer({
    required AppPalette colors,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }
}
