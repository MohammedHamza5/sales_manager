import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class SearchCommandItem {
  final String title;
  final String category;
  final IconData icon;
  final String? route;
  final VoidCallback? onSelect;
  final String? shortcut;

  const SearchCommandItem({
    required this.title,
    required this.category,
    required this.icon,
    this.route,
    this.onSelect,
    this.shortcut,
  });
}

class UniversalSearchDialog extends StatefulWidget {
  const UniversalSearchDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => const UniversalSearchDialog(),
    );
  }

  @override
  State<UniversalSearchDialog> createState() => _UniversalSearchDialogState();
}

class _UniversalSearchDialogState extends State<UniversalSearchDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _selectedIndex = 0;

  final List<SearchCommandItem> _allCommands = [
    // التنقل والصفحات
    const SearchCommandItem(
      title: 'لوحة التحكم والمؤشرات الحية',
      category: 'الشاشات الرئيسية',
      icon: Icons.dashboard_outlined,
      route: '/',
    ),
    const SearchCommandItem(
      title: 'المنتجات وقائمة الأصناف',
      category: 'المخزون والمنتجات',
      icon: Icons.inventory_2_outlined,
      route: '/products',
    ),
    const SearchCommandItem(
      title: 'حركات المخزون والتسويات الجردية',
      category: 'المخزون والمنتجات',
      icon: Icons.warehouse_outlined,
      route: '/inventory/adjustments',
    ),
    const SearchCommandItem(
      title: 'العملاء وكشوف الحسابات',
      category: 'العملاء والموردين',
      icon: Icons.people_outline,
      route: '/customers',
    ),
    const SearchCommandItem(
      title: 'الموردون ومستحقات الشراء',
      category: 'العملاء والموردين',
      icon: Icons.local_shipping_outlined,
      route: '/suppliers',
    ),
    const SearchCommandItem(
      title: 'فواتير المبيعات المسجلة',
      category: 'المبيعات',
      icon: Icons.point_of_sale_outlined,
      route: '/sales',
    ),
    const SearchCommandItem(
      title: 'إنشاء فاتورة بيع جديدة',
      category: 'المبيعات',
      icon: Icons.add_shopping_cart,
      route: '/sales/create',
      shortcut: 'F2',
    ),
    const SearchCommandItem(
      title: 'فواتير المشتريات والتوريدات',
      category: 'المشتريات',
      icon: Icons.shopping_bag_outlined,
      route: '/purchases',
    ),
    const SearchCommandItem(
      title: 'إنشاء فاتورة شراء جديدة',
      category: 'المشتريات',
      icon: Icons.add_business_outlined,
      route: '/purchases/create',
      shortcut: 'F3',
    ),
    const SearchCommandItem(
      title: 'سندات تحصيل العملاء',
      category: 'المدفوعات والتحصيلات',
      icon: Icons.payments_outlined,
      route: '/payments/customers',
    ),
    const SearchCommandItem(
      title: 'سندات سداد الموردين',
      category: 'المدفوعات والتحصيلات',
      icon: Icons.payment_outlined,
      route: '/payments/suppliers',
    ),
    const SearchCommandItem(
      title: 'الخزينة وحركة النقدية اليومية',
      category: 'المالية والخزينة',
      icon: Icons.account_balance_wallet_outlined,
      route: '/cashbox',
    ),
    const SearchCommandItem(
      title: 'المصروفات والبنود التشغيلية',
      category: 'المالية والخزينة',
      icon: Icons.receipt_long_outlined,
      route: '/expenses',
    ),
    const SearchCommandItem(
      title: 'مرتجعات المبيعات والمشتريات',
      category: 'العمليات',
      icon: Icons.assignment_return_outlined,
      route: '/returns',
    ),
    const SearchCommandItem(
      title: 'التقارير التحليلية والمالية الشاملة',
      category: 'التقارير',
      icon: Icons.analytics_outlined,
      route: '/reports',
    ),
    const SearchCommandItem(
      title: 'إعداد الأرصدة الافتتاحية للمؤسسة',
      category: 'النظام والإعدادات',
      icon: Icons.balance_outlined,
      route: '/opening-balance',
    ),
    const SearchCommandItem(
      title: 'النسخ الاحتياطي والاستعادة',
      category: 'النظام والإعدادات',
      icon: Icons.settings_backup_restore_outlined,
      route: '/settings/backup',
    ),
    const SearchCommandItem(
      title: 'سجل العمليات والتدقيق الأمني',
      category: 'النظام والإعدادات',
      icon: Icons.security_outlined,
      route: '/settings/audit-log',
    ),
  ];

  List<SearchCommandItem> _filteredCommands = [];

  @override
  void initState() {
    super.initState();
    _filteredCommands = List.from(_allCommands);
    _controller.addListener(_filter);
  }

  void _filter() {
    final query = _controller.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCommands = List.from(_allCommands);
      } else {
        _filteredCommands = _allCommands.where((cmd) {
          final titleMatch = cmd.title.toLowerCase().contains(query);
          final catMatch = cmd.category.toLowerCase().contains(query);
          final shortcutMatch = cmd.shortcut?.toLowerCase().contains(query) ?? false;
          return titleMatch || catMatch || shortcutMatch;
        }).toList();
      }
      _selectedIndex = 0;
    });
  }

  void _execute(SearchCommandItem item) {
    Navigator.of(context).pop();
    if (item.onSelect != null) {
      item.onSelect!();
    } else if (item.route != null) {
      context.go(item.route!);
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_filteredCommands.isNotEmpty) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % _filteredCommands.length;
        });
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_filteredCommands.isNotEmpty) {
        setState(() {
          _selectedIndex =
              (_selectedIndex - 1 + _filteredCommands.length) % _filteredCommands.length;
        });
      }
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_filteredCommands.isNotEmpty &&
          _selectedIndex >= 0 &&
          _selectedIndex < _filteredCommands.length) {
        _execute(_filteredCommands[_selectedIndex]);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 600,
            constraints: const BoxConstraints(maxHeight: 520),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search Input Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: colors.primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'ابحث عن شاشة، أمر، فاتورة، أو تقرير (Ctrl + F)...',
                            hintStyle: TextStyle(
                              color: colors.textMuted,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_controller.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => _controller.clear(),
                          tooltip: 'مسح',
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: colors.border),
                        ),
                        child: Text(
                          'Esc',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1),

                // Results List
                Flexible(
                  child: _filteredCommands.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 40,
                                color: colors.textMuted,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'لا توجد نتائج مطابقة لبحثك',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shrinkWrap: true,
                          itemCount: _filteredCommands.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 2),
                          itemBuilder: (context, index) {
                            final item = _filteredCommands[index];
                            final isSelected = index == _selectedIndex;

                            return InkWell(
                              onTap: () => _execute(item),
                              onHover: (hovering) {
                                if (hovering) {
                                  setState(() => _selectedIndex = index);
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colors.primary.withValues(alpha: 0.12)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: isSelected
                                      ? Border.all(
                                          color: colors.primary.withValues(alpha: 0.3),
                                        )
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? colors.primary
                                            : colors.surfaceElevated,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        item.icon,
                                        size: 18,
                                        color: isSelected
                                            ? Colors.white
                                            : colors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            item.title,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                              color: colors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            item.category,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: colors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (item.shortcut != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colors.surfaceElevated,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: colors.border),
                                        ),
                                        child: Text(
                                          item.shortcut!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: colors.primary,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Footer Hints
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                    border: Border(top: BorderSide(color: colors.border)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.keyboard_outlined, size: 16, color: colors.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            '↑ ↓ للتنقل | Enter للاختيار | Esc للإغلاق',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'بحث موحد وسريع',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
