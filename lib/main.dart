import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:window_manager/window_manager.dart';
import 'app/app.dart';
import 'core/di/injector.dart';
import 'features/backup_restore/domain/usecases/create_auto_backup_usecase.dart';
import 'features/backup_restore/domain/usecases/manage_backup_settings_usecase.dart';
import 'core/config/supabase_config.dart';
import 'core/sync/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1300, 800),
      minimumSize: Size(1020, 680),
      center: true,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      title: 'مدير المبيعات والمخزون - Sales Manager',
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  await initializeDateFormatting('ar');
  await initDependencies();

  // Initialize Supabase Cloud & Background Sync (non-blocking)
  try {
    await SupabaseConfig.initialize();
    await getIt<SyncService>().initialize();
  } catch (_) {
    // Non-blocking in completely offline cold start
  }

  // Automatic backup on launch (non-blocking)
  try {
    final manageSettings = getIt<ManageBackupSettingsUseCase>();
    final isEnabled = (await manageSettings.isAutoBackupEnabled()).dataOrNull ?? true;
    if (isEnabled) {
      final retention = (await manageSettings.getAutoBackupRetentionCount()).dataOrNull ?? 7;
      final createAutoBackup = getIt<CreateAutoBackupUseCase>();
      await createAutoBackup(retentionCount: retention);
    }
  } catch (_) {
    // Non-blocking auto backup failure
  }

  runApp(const SalesManagerApp());
}
