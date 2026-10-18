import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/shortcuts/app_shortcuts.dart';
import '../../core/shortcuts/universal_search_dialog.dart';
import '../../core/strings/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_cubit.dart';

/// الشريط الجانبي لتطبيق سطح المكتب
/// بتصميم حديث وعريض، وخطوط كبيرة وواضحة جداً وقابلة للقراءة بسهولة ومصنفة بعناية
class AppDesktopSidebar extends StatelessWidget {
  final String currentLocation;

  const AppDesktopSidebar({
    super.key,
    required this.currentLocation,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDarkMode;

    return Container(
      width: 280,
      color: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // رأس الشريط الجانبي: الهوية وشريط البحث السريع بخطوط واضحة
          _SidebarHeader(isDark: isDark),

          Divider(height: 1, thickness: 1, color: colors.border),

          // قائمة الأقسام والتنقل القابلة للتمرير بسلاسة
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. نظرة عامة
                  const _SidebarSectionHeader(title: 'نظرة عامة'),
                  _SidebarItem(
                    title: AppStrings.dashboard,
                    icon: Icons.dashboard_outlined,
                    selectedIcon: Icons.dashboard_rounded,
                    isSelected: currentLocation == '/',
                    onTap: () => context.go('/'),
                  ),

                  // 2. العمليات التجارية
                  const _SidebarSectionHeader(title: 'العمليات التجارية'),
                  _SidebarItem(
                    title: AppStrings.sales,
                    icon: Icons.shopping_cart_outlined,
                    selectedIcon: Icons.shopping_cart_rounded,
                    isSelected: currentLocation.startsWith('/sales'),
                    onTap: () => context.go('/sales'),
                  ),
                  _SidebarItem(
                    title: AppStrings.purchases,
                    icon: Icons.shopping_bag_outlined,
                    selectedIcon: Icons.shopping_bag_rounded,
                    isSelected: currentLocation.startsWith('/purchases'),
                    onTap: () => context.go('/purchases'),
                  ),
                  _SidebarItem(
                    title: AppStrings.returns,
                    icon: Icons.assignment_return_outlined,
                    selectedIcon: Icons.assignment_return_rounded,
                    isSelected: currentLocation.startsWith('/returns'),
                    onTap: () => context.go('/returns'),
                  ),

                  // 3. المخزون والمنتجات
                  const _SidebarSectionHeader(title: 'المخزون والمنتجات'),
                  _SidebarItem(
                    title: AppStrings.products,
                    icon: Icons.inventory_2_outlined,
                    selectedIcon: Icons.inventory_2_rounded,
                    isSelected: currentLocation.startsWith('/products'),
                    onTap: () => context.go('/products'),
                  ),
                  _SidebarItem(
                    title: AppStrings.inventory,
                    icon: Icons.warehouse_outlined,
                    selectedIcon: Icons.warehouse_rounded,
                    isSelected: currentLocation.startsWith('/inventory') ||
                        currentLocation.startsWith('/opening-balance'),
                    onTap: () => context.go('/inventory'),
                  ),

                  // 4. جهات التعامل
                  const _SidebarSectionHeader(title: 'جهات التعامل'),
                  _SidebarItem(
                    title: AppStrings.customers,
                    icon: Icons.people_outline_rounded,
                    selectedIcon: Icons.people_rounded,
                    isSelected: currentLocation.startsWith('/customers') ||
                        currentLocation.startsWith('/customer-payments') ||
                        currentLocation.startsWith('/payments/customers'),
                    onTap: () => context.go('/customers'),
                  ),
                  _SidebarItem(
                    title: AppStrings.suppliers,
                    icon: Icons.local_shipping_outlined,
                    selectedIcon: Icons.local_shipping_rounded,
                    isSelected: currentLocation.startsWith('/suppliers') ||
                        currentLocation.startsWith('/supplier-payments') ||
                        currentLocation.startsWith('/payments/suppliers'),
                    onTap: () => context.go('/suppliers'),
                  ),

                  // 5. المالية والتحليلات
                  const _SidebarSectionHeader(title: 'المالية والتقارير'),
                  _SidebarItem(
                    title: AppStrings.cashbox,
                    icon: Icons.account_balance_wallet_outlined,
                    selectedIcon: Icons.account_balance_wallet_rounded,
                    isSelected: currentLocation.startsWith('/cashbox'),
                    onTap: () => context.go('/cashbox'),
                  ),
                  _SidebarItem(
                    title: AppStrings.expenses,
                    icon: Icons.receipt_long_outlined,
                    selectedIcon: Icons.receipt_long_rounded,
                    isSelected: currentLocation.startsWith('/expenses'),
                    onTap: () => context.go('/expenses'),
                  ),
                  _SidebarItem(
                    title: AppStrings.reports,
                    icon: Icons.bar_chart_outlined,
                    selectedIcon: Icons.bar_chart_rounded,
                    isSelected: currentLocation.startsWith('/reports'),
                    onTap: () => context.go('/reports'),
                  ),

                  // 6. النظام والإعدادات
                  const _SidebarSectionHeader(title: 'النظام'),
                  _SidebarItem(
                    title: AppStrings.settings,
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings_rounded,
                    isSelected: currentLocation.startsWith('/settings'),
                    onTap: () => context.go('/settings'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          Divider(height: 1, thickness: 1, color: colors.border),

          // أسفل الشريط الجانبي: التبديل بين الأوضاع وحالة النظام
          _SidebarFooter(isDark: isDark),
        ],
      ),
    );
  }
}

/// ترويسة الشريط الجانبي مع الشعار وزر البحث السريع بخطوط عريضة
class _SidebarHeader extends StatelessWidget {
  final bool isDark;

  const _SidebarHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: colors.primary.withValues(alpha: 0.15),
                      child: Icon(Icons.point_of_sale_rounded, color: colors.primary, size: 24),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.appName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'نظام إدارة المبيعات',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.keyboard_outlined,
                  size: 21,
                  color: colors.textSecondary,
                ),
                tooltip: 'اختصارات لوحة المفاتيح (F1 أو Ctrl+H)',
                splashRadius: 20,
                onPressed: () => AppShortcuts.showHelpDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // زر تفعيل البحث الشامل
          InkWell(
            onTap: () => UniversalSearchDialog.show(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: colors.textMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'بحث شامل في النظام...',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: colors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: colors.border),
                    ),
                    child: Text(
                      'Ctrl+F',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// عنوان فرعي لتصنيف أقسام الشريط الجانبي بخط عريض وواضح
class _SidebarSectionHeader extends StatelessWidget {
  final String title;

  const _SidebarSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8, right: 10, left: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// عنصر تنقل فردي بخط كبير 16px وتأثيرات بصرية واضحة ومريحة للعين
class _SidebarItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDarkMode;

    final isSelected = widget.isSelected;
    final isHovered = _isHovered && !isSelected;

    Color backgroundColor;
    Color borderColor;

    if (isSelected) {
      backgroundColor = colors.primary.withValues(alpha: isDark ? 0.18 : 0.12);
      borderColor = colors.primary.withValues(alpha: isDark ? 0.40 : 0.28);
    } else if (isHovered) {
      backgroundColor = colors.surfaceElevated.withValues(alpha: 0.9);
      borderColor = colors.border.withValues(alpha: 0.7);
    } else {
      backgroundColor = Colors.transparent;
      borderColor = Colors.transparent;
    }

    final Color contentColor = isSelected
        ? (isDark ? colors.primary : colors.textPrimary)
        : (isHovered ? colors.textPrimary : colors.textPrimary.withValues(alpha: 0.88));

    final Color iconColor = isSelected
        ? colors.primary
        : (isHovered ? colors.textPrimary : colors.textPrimary.withValues(alpha: 0.78));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.5),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Row(
              children: [
                // مؤشر مرئي عمودي للصفحة النشطة
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 4,
                  height: isSelected ? 22 : 0,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: isSelected ? 10 : 4),
                Icon(
                  isSelected ? widget.selectedIcon : widget.icon,
                  size: 23,
                  color: iconColor,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: isSelected ? FontWeight.w800 : (isHovered ? FontWeight.w700 : FontWeight.w600),
                      color: contentColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// تذييل الشريط الجانبي مع مفتاح تبديل المظهر وحالة النظام
class _SidebarFooter extends StatelessWidget {
  final bool isDark;

  const _SidebarFooter({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // زر تبديل الوضع النهاري / الليلي بخط ورمز أوضح
          InkWell(
            onTap: () => context.read<ThemeCubit>().toggleTheme(),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    size: 20,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isDark ? 'الوضع النهاري' : 'الوضع الليلي',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // مؤشر حالة قاعدة البيانات المحلية
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981), // أخضر نشط
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'قاعدة بيانات محلية نشطة (Offline)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
