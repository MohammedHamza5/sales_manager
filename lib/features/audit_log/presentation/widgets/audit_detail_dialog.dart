import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/audit_entry.dart';

class AuditDetailDialog extends StatelessWidget {
  final AuditEntry entry;

  const AuditDetailDialog({super.key, required this.entry});

  static Future<void> show(BuildContext context, AuditEntry entry) {
    return showDialog(
      context: context,
      builder: (context) => AuditDetailDialog(entry: entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
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
                        child: Icon(Icons.history_rounded, color: colors.primary),
                      ),
                      AppSpacing.horizontalMd,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.auditDetails,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            '${entry.entityType} #${entry.entityId} — ${_formatAction(entry.action)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: AppStrings.cancel,
                  ),
                ],
              ),
              const Divider(height: 24),

              // Metadata grid
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.border),
                ),
                child: Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    _buildMetaItem(context, AppStrings.performedAt, _formatDate(entry.performedAt)),
                    _buildMetaItem(context, AppStrings.performedBy, entry.userId),
                    _buildMetaItem(context, AppStrings.entityType, entry.entityType),
                    _buildMetaItem(context, AppStrings.actionType, _formatAction(entry.action)),
                    if (entry.note != null && entry.note!.isNotEmpty)
                      _buildMetaItem(context, AppStrings.notes, entry.note!),
                  ],
                ),
              ),
              AppSpacing.verticalMd,

              // Payload Comparison
              Text(
                'مقارنة بيانات العملية:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary),
              ),
              AppSpacing.verticalSm,
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Before
                    Expanded(
                      child: _buildPayloadCard(
                        context: context,
                        title: AppStrings.payloadBefore,
                        content: entry.payloadBefore,
                        headerColor: colors.danger.withValues(alpha: 0.15),
                        icon: Icons.remove_circle_outline,
                        iconColor: colors.danger,
                      ),
                    ),
                    AppSpacing.horizontalMd,
                    // After
                    Expanded(
                      child: _buildPayloadCard(
                        context: context,
                        title: AppStrings.payloadAfter,
                        content: entry.payloadAfter,
                        headerColor: colors.success.withValues(alpha: 0.15),
                        icon: Icons.add_circle_outline,
                        iconColor: colors.success,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.verticalMd,

              // Close button
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('إغلاق'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaItem(BuildContext context, String label, String value) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildPayloadCard({
    required BuildContext context,
    required String title,
    required String? content,
    required Color headerColor,
    required IconData icon,
    required Color iconColor,
  }) {
    final colors = context.colors;
    final formattedContent = _prettifyJson(content);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SelectableText(
                formattedContent,
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 12,
                  height: 1.4,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _prettifyJson(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return '(لا توجد بيانات)';
    }
    try {
      final decoded = json.decode(raw);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(decoded);
    } catch (_) {
      return raw;
    }
  }

  String _formatAction(String action) {
    switch (action.toLowerCase()) {
      case 'create':
        return 'إضافة / إنشاء';
      case 'update':
        return 'تعديل';
      case 'cancel':
        return 'إلغاء';
      case 'reverse':
        return 'عكس عملية';
      case 'activate':
        return 'تفعيل';
      case 'deactivate':
        return 'تعطيل';
      default:
        return action;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
