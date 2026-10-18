import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:window_manager/window_manager.dart';
import '../shortcuts/universal_search_dialog.dart';
import '../theme/app_colors.dart';
import '../theme/theme_cubit.dart';
import 'sync_status_badge.dart';

/// شريط عنوان نافذة ويندوز المخصص والعصري (Custom Windows Title Bar)
/// يوفر تجربة سطح مكتب احترافية:
/// - مدمج تماماً مع ألوان وهوية التطبيق (Dark / Light)
/// - منطقة سحب لنقل النافذة (Drag to move)
/// - نقر مزدوج للتكبير/الاستعادة (Double-click to maximize/restore)
/// - أزرار تحكم النافذة (تصغير، تكبير، إغلاق مع تأثير هوفر أحمر ويندوز)
/// - زر البحث السريع وشعار التطبيق وزر التبديل السريع للمظهر
class AppTitleBar extends StatefulWidget {
  final double height;

  const AppTitleBar({
    super.key,
    this.height = 38.0,
  });

  @override
  State<AppTitleBar> createState() => _AppTitleBarState();
}

class _AppTitleBarState extends State<AppTitleBar> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _checkMaximizedState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _checkMaximizedState() async {
    final max = await windowManager.isMaximized();
    if (mounted && max != _isMaximized) {
      setState(() => _isMaximized = max);
    }
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isMaximized = false);
  }

  Future<void> _toggleMaximize() async {
    final isMax = await windowManager.isMaximized();
    if (isMax) {
      await windowManager.restore();
    } else {
      await windowManager.maximize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDarkMode;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(
            color: colors.border,
            width: 1.0,
          ),
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            // 1. هوية التطبيق والشعار (في اليسار الآن مع LTR)
            GestureDetector(
              onDoubleTap: _toggleMaximize,
              child: const DragToMoveArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image(
                          image: AssetImage('assets/images/app_logo.png'),
                          width: 20,
                          height: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'نظام إدارة المبيعات والمخزون',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 2. المنطقة الوسطى القابلة للسحب والبحث السريع
          Expanded(
            child: GestureDetector(
              onDoubleTap: _toggleMaximize,
              child: DragToMoveArea(
                child: Container(
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => UniversalSearchDialog.show(context),
                      hoverColor: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? colors.surfaceElevated
                              : colors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: colors.border,
                            width: 0.8,
                          ),
                        ),
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_rounded,
                                size: 14,
                                color: colors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'بحث شامل وسريع...',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: colors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.border,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Ctrl+F',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2.5. مؤشر حالة المزامنة السحابية (Sync Status Badge)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: SyncStatusBadge(),
            ),

            // 3. زر التبديل السريع للمظهر (Dark / Light Mode)
            Tooltip(
              message: isDark ? 'التبديل إلى الوضع الفاتح' : 'التبديل إلى الوضع الداكن',
              child: InkWell(
                onTap: () => context.read<ThemeCubit>().toggleTheme(),
                hoverColor: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                child: SizedBox(
                  width: 36,
                  height: widget.height,
                  child: Icon(
                    isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 4),

            // 4. أزرار التحكم بالنافذة (تصغير، تكبير/استعادة، إغلاق)
            _WindowCaptionButton(
              icon: Icons.remove_rounded,
              tooltip: 'تصغير',
              height: widget.height,
              onPressed: () => windowManager.minimize(),
            ),
            _WindowCaptionButton(
              icon: _isMaximized
                  ? Icons.filter_none_rounded
                  : Icons.crop_square_rounded,
              iconSize: _isMaximized ? 12 : 14,
              tooltip: _isMaximized ? 'استعادة' : 'تكبير',
              height: widget.height,
              onPressed: _toggleMaximize,
            ),
            _WindowCaptionButton(
              icon: Icons.close_rounded,
              tooltip: 'إغلاق',
              height: widget.height,
              isCloseButton: true,
              onPressed: () => windowManager.close(),
            ),
          ],
        ),
      ),
    );
  }
}

/// زر تحكم ويندوز احترافي مع تأثير Hover أحمر للإغلاق وتأثير شفاف للأزرار الأخرى
class _WindowCaptionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double height;
  final double iconSize;
  final bool isCloseButton;

  const _WindowCaptionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.height,
    this.iconSize = 15,
    this.isCloseButton = false,
  });

  @override
  State<_WindowCaptionButton> createState() => _WindowCaptionButtonState();
}

class _WindowCaptionButtonState extends State<_WindowCaptionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDarkMode;

    Color backgroundColor = Colors.transparent;
    Color iconColor = colors.textSecondary;

    if (_isHovered) {
      if (widget.isCloseButton) {
        backgroundColor = const Color(0xFFE81123); // Windows native red
        iconColor = Colors.white;
      } else {
        backgroundColor = isDark
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.black.withValues(alpha: 0.07);
        iconColor = colors.textPrimary;
      }
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        waitDuration: const Duration(milliseconds: 600),
        child: GestureDetector(
          onTap: widget.onPressed,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 44,
            height: widget.height,
            color: backgroundColor,
            alignment: Alignment.center,
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
