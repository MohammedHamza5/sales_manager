import 'package:flutter/material.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../audit_log/presentation/pages/audit_log_page.dart';
import '../../../backup_restore/presentation/pages/backup_restore_page.dart';
import '../../../update/presentation/widgets/update_settings_tab.dart';

class SettingsPage extends StatefulWidget {
  final int initialTabIndex;

  const SettingsPage({super.key, this.initialTabIndex = 0});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(bottom: BorderSide(color: colors.border)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: colors.primary,
                    unselectedLabelColor: colors.textSecondary,
                    indicatorColor: colors.primary,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.settings_backup_restore_rounded, size: 20),
                        text: AppStrings.backupRestore,
                      ),
                      Tab(
                        icon: Icon(Icons.history_edu_rounded, size: 20),
                        text: AppStrings.auditLog,
                      ),
                      Tab(
                        icon: Icon(Icons.system_update_rounded, size: 20),
                        text: AppStrings.systemUpdates,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          BackupRestorePage(),
          AuditLogPage(),
          UpdateSettingsTab(),
        ],
      ),
    );
  }
}

