import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';

/// Theme Mode Provider
/// - Stores theme mode in SharedPreferences
/// - Supports legacy `dark_mode` bool for backward compatibility
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _themeModeKey = 'theme_mode'; // 'system' | 'light' | 'dark'
  static const _legacyDarkModeKey = 'dark_mode';

  @override
  ThemeMode build() {
    final prefs = ref.read(sharedPreferencesProvider).prefs;

    final stored = prefs.getString(_themeModeKey);
    if (stored != null) {
      switch (stored) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        case 'system':
        default:
          return ThemeMode.system;
      }
    }

    // Legacy bool: if present, prefer it.
    final legacy = prefs.getBool(_legacyDarkModeKey);
    if (legacy == true) return ThemeMode.dark;
    if (legacy == false) return ThemeMode.light;

    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider).prefs;

    state = mode;
    await prefs.setString(_themeModeKey, mode.name);

    // Keep legacy key in sync for older screens.
    if (mode == ThemeMode.dark) {
      await prefs.setBool(_legacyDarkModeKey, true);
    } else if (mode == ThemeMode.light) {
      await prefs.setBool(_legacyDarkModeKey, false);
    } else {
      await prefs.remove(_legacyDarkModeKey);
    }
  }

  Future<void> toggleDarkMode() async {
    // Toggle between explicit light/dark (not system), matching current UX.
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }
}

