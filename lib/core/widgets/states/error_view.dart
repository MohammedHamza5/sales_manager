import 'package:flutter/material.dart';
import '../../strings/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final String? technicalDetails;
  final VoidCallback? onRetry;

  const ErrorView({
    super.key,
    required this.message,
    this.technicalDetails,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: colors.danger,
            ),
            AppSpacing.verticalMd,
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            if (technicalDetails != null) ...[
              AppSpacing.verticalXs,
              Text(
                technicalDetails!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textMuted,
                  fontFamily: 'monospace',
                ),
              ),
            ],
            if (onRetry != null) ...[
              AppSpacing.verticalLg,
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(AppStrings.retry),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primary,
                  side: BorderSide(color: colors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
