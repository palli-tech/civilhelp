import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app_theme_mode.dart';

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  static const String _boxName = 'settings_box';
  static const String _themeModeKey = 'theme_mode_index';

  ThemeNotifier() : super(AppThemeMode.system) {
    _loadThemeMode();
  }

  void _loadThemeMode() {
    try {
      final box = Hive.box(_boxName);
      final index = box.get(_themeModeKey, defaultValue: AppThemeMode.system.index) as int;
      if (index >= 0 && index < AppThemeMode.values.length) {
        state = AppThemeMode.values[index];
      } else {
        state = AppThemeMode.system;
      }
    } catch (_) {
      // Box may not be opened or Hive not initialized in tests/initial setup
      state = AppThemeMode.system;
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = mode;
    try {
      final box = Hive.box(_boxName);
      await box.put(_themeModeKey, mode.index);
    } catch (_) {
      // Catch errors during async write if box is closed
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier();
});
