import 'package:flutter/material.dart';
import '../../strings/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class LoadingView extends StatelessWidget {
  final String message;

  const LoadingView({
    super.key,
    this.message = AppStrings.loading,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
          ),
          AppSpacing.verticalMd,
          Text(
            message,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
