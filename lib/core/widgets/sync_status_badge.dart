import 'package:flutter/material.dart';
import '../di/injector.dart';
import '../sync/sync_service.dart';
import '../theme/app_colors.dart';

class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final syncService = getIt<SyncService>();

    return StreamBuilder<SyncState>(
      stream: syncService.syncStateStream,
      initialData: syncService.currentState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? syncService.currentState;
        final colors = context.colors;

        IconData icon;
        Color color;
        String text;

        switch (state.status) {
          case SyncStatus.syncing:
            icon = Icons.sync_rounded;
            color = Colors.amber;
            text = 'جاري المزامنة...';
            break;
          case SyncStatus.offline:
            icon = Icons.cloud_off_rounded;
            color = Colors.grey;
            text = state.pendingCount > 0
                ? 'أوفلاين (${state.pendingCount} معلق)'
                : 'بدون إنترنت';
            break;
          case SyncStatus.error:
            icon = Icons.sync_problem_rounded;
            color = Colors.redAccent;
            text = 'خطأ بالمزامنة';
            break;
          case SyncStatus.success:
          case SyncStatus.idle:
            if (state.pendingCount > 0) {
              icon = Icons.cloud_upload_outlined;
              color = Colors.amber;
              text = '${state.pendingCount} بانتظار الرفع';
            } else {
              icon = Icons.cloud_done_rounded;
              color = colors.primary;
              text = 'متصل (تحديث فوري)';
            }
            break;
        }

        return Tooltip(
          message: state.errorMessage != null
              ? 'السبب: ${state.errorMessage}\nاضغط للمحاولة يدوياً'
              : (state.status == SyncStatus.offline 
                  ? 'بانتظار عودة الإنترنت للرفع التلقائي...' 
                  : 'النظام يرفع التحديثات تلقائياً'),
          child: InkWell(
            onTap: () => syncService.syncNow(),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.status == SyncStatus.syncing)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    )
                  else
                    Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
