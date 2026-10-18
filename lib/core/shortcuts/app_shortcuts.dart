import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// اختصارات لوحة المفاتيح الموحدة للنظام
/// تدعم كلاً من لوحات المفاتيح القياسية (F1-F10) واختصارات اللابتوب البديلة (Ctrl + ...)
class AppShortcuts {
  AppShortcuts._();

  // 1. الدليل الإرشادي
  static const SingleActivator help = SingleActivator(LogicalKeyboardKey.f1);
  static const SingleActivator helpAlt =
      SingleActivator(LogicalKeyboardKey.keyH, control: true);
  static const SingleActivator helpSlash =
      SingleActivator(LogicalKeyboardKey.slash, control: true);

  // 2. البحث والتنقل السريع الشامل
  static const SingleActivator search =
      SingleActivator(LogicalKeyboardKey.keyF, control: true);
  static const SingleActivator searchAlt =
      SingleActivator(LogicalKeyboardKey.keyK, control: true);

  // 3. فاتورة بيع جديدة
  static const SingleActivator newSale = SingleActivator(LogicalKeyboardKey.f2);
  static const SingleActivator newSaleAlt =
      SingleActivator(LogicalKeyboardKey.keyN, control: true);

  // 4. فاتورة شراء وتوريد جديدة
  static const SingleActivator newPurchase =
      SingleActivator(LogicalKeyboardKey.f3);
  static const SingleActivator newPurchaseAlt =
      SingleActivator(LogicalKeyboardKey.keyN, control: true, shift: true);
  static const SingleActivator newPurchaseAlt2 =
      SingleActivator(LogicalKeyboardKey.keyP, control: true, shift: true);

  // 5. حفظ واعتماد الفاتورة / العملية
  static const SingleActivator submitAction =
      SingleActivator(LogicalKeyboardKey.f10);
  static const SingleActivator ctrlEnterSubmit =
      SingleActivator(LogicalKeyboardKey.enter, control: true);
  static const SingleActivator saveAlt =
      SingleActivator(LogicalKeyboardKey.keyS, control: true);

  // 6. خيارات السداد في الفواتير
  static const SingleActivator payFully =
      SingleActivator(LogicalKeyboardKey.keyC, alt: true);
  static const SingleActivator payFullyAlt =
      SingleActivator(LogicalKeyboardKey.keyC, control: true, shift: true);
  static const SingleActivator payZero =
      SingleActivator(LogicalKeyboardKey.keyD, alt: true);
  static const SingleActivator payZeroAlt =
      SingleActivator(LogicalKeyboardKey.keyD, control: true, shift: true);

  // 7. إغلاق / رجوع
  static const SingleActivator closeOrBack =
      SingleActivator(LogicalKeyboardKey.escape);

  /// عرض نافذة إرشادية منسقة بجميع اختصارات لوحة المفاتيح
  static void showHelpDialog(BuildContext context) {
    final colors = context.colors;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.keyboard_outlined, color: colors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'دليل اختصارات لوحة المفاتيح',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 540,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Laptop Fn Tip Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.info.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.laptop_chromebook_rounded, color: colors.info, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'لمستخدمي أجهزة اللابتوب (Laptop Keys):',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'إذا كانت أزرار F1-F12 تقوم بوظائف اللابتوب (مثل النوم أو الصوت)، يمكنك استخدام اختصارات Ctrl الموضحة أدناه مباشرة، أو تفعيل زر Fn Lock عبر الضغط على (Fn + Esc) بلوحة المفاتيح.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Table of shortcuts
                _buildShortcutRow(
                  context: context,
                  desktopKey: 'F1',
                  laptopKey: 'Ctrl + H',
                  description: 'فتح هذا الدليل الإرشادي للاختصارات',
                ),
                _buildShortcutRow(
                  context: context,
                  desktopKey: 'Ctrl + F',
                  laptopKey: 'Ctrl + K',
                  description: 'فتح شريط البحث الشامل والتنقل السريع بين الشاشات',
                ),
                _buildShortcutRow(
                  context: context,
                  desktopKey: 'F2',
                  laptopKey: 'Ctrl + N',
                  description: 'إنشاء فاتورة بيع جديدة فوراً من أي مكان',
                ),
                _buildShortcutRow(
                  context: context,
                  desktopKey: 'F3',
                  laptopKey: 'Ctrl + Shift + N',
                  description: 'إنشاء فاتورة شراء وتوريد جديدة',
                ),
                _buildShortcutRow(
                  context: context,
                  desktopKey: 'F10',
                  laptopKey: 'Ctrl + S / Ctrl + Enter',
                  description: 'حفظ وإتمام الفاتورة أو العملية الحالية',
                ),
                _buildShortcutRow(
                  context: context,
                  desktopKey: 'Alt + C',
                  laptopKey: 'Ctrl + Shift + C',
                  description: 'تحديد المبلغ كـ "سداد نقدي كامل" بالفاتورة',
                ),
                _buildShortcutRow(
                  context: context,
                  desktopKey: 'Alt + D',
                  laptopKey: 'Ctrl + Shift + D',
                  description: 'تحديد المبلغ كـ "آجل كامل على الحساب" بالفاتورة',
                ),
                _buildShortcutRow(
                  context: context,
                  desktopKey: 'Enter',
                  laptopKey: 'Tab',
                  description: 'التنقل السلس والذكي بين حقول الأصناف والكميات',
                ),
                _buildShortcutRow(
                  context: context,
                  desktopKey: 'Esc',
                  laptopKey: 'Esc',
                  description: 'إغلاق النوافذ المنبثقة أو الرجوع للشاشة السابقة',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: colors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('تم الفهم (Esc)', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  static Widget _buildShortcutRow({
    required BuildContext context,
    required String desktopKey,
    required String laptopKey,
    required String description,
  }) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            // Keys badge
            Wrap(
              spacing: 6,
              children: [
                _buildKeyChip(context, desktopKey),
                if (desktopKey != laptopKey) ...[
                  Text('أو', style: TextStyle(fontSize: 11, color: colors.textMuted)),
                  _buildKeyChip(context, laptopKey),
                ],
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildKeyChip(BuildContext context, String keyText) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        keyText,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11.5,
          color: colors.primary,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
