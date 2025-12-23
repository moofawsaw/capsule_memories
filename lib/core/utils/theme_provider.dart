import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/theme_helper.dart';

/// Provider for theme mode state management
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

/// Notifier for managing theme mode state
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const String _themeKey = 'theme_mode';

  ThemeModeNotifier() : super(ThemeMode.dark) {
    _loadThemeMode();
  }

  /// Load saved theme mode from SharedPreferences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDarkMode = prefs.getBool(_themeKey) ?? true;
      state = isDarkMode ? ThemeMode.dark : ThemeMode.light;
      _updateThemeHelper();
    } catch (e) {
      debugPrint('Error loading theme mode: $e');
    }
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    try {
      final newMode =
          state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      state = newMode;
      _updateThemeHelper();

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, newMode == ThemeMode.dark);
    } catch (e) {
      debugPrint('Error toggling theme: $e');
    }
  }

  /// Set specific theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      state = mode;
      _updateThemeHelper();

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, mode == ThemeMode.dark);
    } catch (e) {
      debugPrint('Error setting theme mode: $e');
    }
  }

  /// Update ThemeHelper with current mode
  void _updateThemeHelper() {
    ThemeHelper().setThemeMode(state);
  }

  /// Check if current mode is dark
  bool get isDarkMode => state == ThemeMode.dark;
}
