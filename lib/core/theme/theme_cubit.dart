import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../database/app_database.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final AppDatabase? _database;

  ThemeCubit([this._database]) : super(ThemeMode.dark) {
    _loadThemePreference();
  }

  bool get isDarkMode => state == ThemeMode.dark;

  Future<void> _loadThemePreference() async {
    if (_database == null) return;
    try {
      final entry = await (_database.select(_database.settings)
            ..where((tbl) => tbl.key.equals('app_theme_mode')))
          .getSingleOrNull();

      if (entry != null) {
        if (entry.value == 'light') {
          emit(ThemeMode.light);
        } else if (entry.value == 'dark') {
          emit(ThemeMode.dark);
        } else if (entry.value == 'system') {
          emit(ThemeMode.system);
        }
      }
    } catch (_) {
      // In tests or if DB is not ready, keep current state
    }
  }

  Future<void> toggleTheme() async {
    final nextMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(mode);
    if (_database == null) return;
    try {
      await _database.into(_database.settings).insertOnConflictUpdate(
            SettingEntry(
              key: 'app_theme_mode',
              value: mode.name,
              updatedAt: DateTime.now(),
            ),
          );
    } catch (_) {
      // Silently ignore DB errors during persistence
    }
  }
}
