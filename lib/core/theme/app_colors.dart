import 'package:flutter/material.dart';

/// Design tokens for Sales Manager application.
/// Supports both 🌙 Dark Mode (#0A0A0A / #CBFA3A) and ☀️ Light Mode (#FFFFFF / #556F01).
abstract final class AppColors {
  // 🌙 Dark Mode Tokens
  static const darkBackground = Color(0xFF0A0A0A);
  static const darkSurface = Color(0xFF141414);
  static const darkSurfaceElevated = Color(0xFF1E1E1E);
  static const darkPrimary = Color(0xFFCBFA3A);
  static const darkOnPrimary = Color(0xFF0A0A0A);
  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFFA0A0A0);
  static const darkTextMuted = Color(0xFF666666);
  static const darkBorder = Color(0xFF222222);

  // ☀️ Light Mode Tokens
  static const lightBackground = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceElevated = Color(0xFFF8F9FA);
  static const lightPrimary = Color(0xFF556F01);
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightTextPrimary = Color(0xFF0A0A0A);
  static const lightTextSecondary = Color(0xFF666666);
  static const lightTextMuted = Color(0xFF999999);
  static const lightBorder = Color(0xFFE5E5E5);

  // Common Semantic Status Tokens
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // Fallback / legacy constants pointing to dark tokens for immediate UI upgrade
  static const primary = darkPrimary;
  static const primaryDark = Color(0xFFB0DF28);
  static const primaryLight = Color(0xFFE3FFA1);
  static const onPrimary = darkOnPrimary;

  static const secondary = Color(0xFF10B981);
  static const secondaryLight = Color(0xFF1A2E22);

  static const background = darkBackground;
  static const surface = darkSurface;
  static const surfaceElevated = darkSurfaceElevated;
  static const border = darkBorder;

  static const textPrimary = darkTextPrimary;
  static const textSecondary = darkTextSecondary;
  static const textMuted = darkTextMuted;
}

/// Custom [ThemeExtension] to provide reactive, typed palette access via [BuildContext.colors].
class AppPalette extends ThemeExtension<AppPalette> {
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color primary;
  final Color onPrimary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  /// Convenience tints
  Color get primaryLight => primary.withValues(alpha: 0.15);
  Color get accent => primary;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.primary,
    required this.onPrimary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
  });

  static const dark = AppPalette(
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceElevated: AppColors.darkSurfaceElevated,
    primary: AppColors.darkPrimary,
    onPrimary: AppColors.darkOnPrimary,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textMuted: AppColors.darkTextMuted,
    border: AppColors.darkBorder,
    success: AppColors.success,
    warning: AppColors.warning,
    danger: AppColors.danger,
    info: AppColors.info,
  );

  static const light = AppPalette(
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    surfaceElevated: AppColors.lightSurfaceElevated,
    primary: AppColors.lightPrimary,
    onPrimary: AppColors.lightOnPrimary,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textMuted: AppColors.lightTextMuted,
    border: AppColors.lightBorder,
    success: AppColors.success,
    warning: AppColors.warning,
    danger: AppColors.danger,
    info: AppColors.info,
  );

  @override
  ThemeExtension<AppPalette> copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? primary,
    Color? onPrimary,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? border,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
    );
  }

  @override
  ThemeExtension<AppPalette> lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}

/// Convenience extensions on [BuildContext] to access design tokens easily.
extension ThemeContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  AppPalette get colors =>
      Theme.of(this).extension<AppPalette>() ??
      (isDarkMode ? AppPalette.dark : AppPalette.light);
}
