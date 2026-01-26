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

  /// If [initialMode] is provided (e.g. during app bootstrap), we can skip
  /// async hydration to avoid a first-frame theme flash.
  ThemeModeNotifier({
    ThemeMode? initialMode,
    bool hydrateFromPrefs = true,
  }) : super(initialMode ?? ThemeMode.system) {
    if (hydrateFromPrefs && initialMode == null) {
      _loadThemeMode();
    } else {
      _updateThemeHelper();
    }
  }

  /// Load the initial theme mode for first paint.
  /// - If user has not chosen yet -> ThemeMode.system (device theme)
  /// - Backwards compatible with legacy bool storage (true=dark, false=light)
  static Future<ThemeMode> loadInitialThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final stored = prefs.getString(_themeKey);
      if (stored != null && stored.trim().isNotEmpty) {
        return _parseStoredThemeMode(stored);
      }

      // Legacy (older builds stored a bool at the same key)
      final legacy = prefs.getBool(_themeKey);
      if (legacy != null) {
        final mode = legacy ? ThemeMode.dark : ThemeMode.light;
        // Migrate to string format so future reads are consistent.
        await prefs.setString(_themeKey, mode.name);
        return mode;
      }

      // Not set yet -> follow device
      return ThemeMode.system;
    } catch (e) {
      debugPrint('Error loading initial theme mode: $e');
      return ThemeMode.system;
    }
  }

  static ThemeMode _parseStoredThemeMode(String raw) {
    final v = raw.trim().toLowerCase();
    switch (v) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }

  /// Load saved theme mode from SharedPreferences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_themeKey);
      if (stored != null && stored.trim().isNotEmpty) {
        state = _parseStoredThemeMode(stored);
      } else {
        // Legacy (older builds stored a bool at the same key)
        final legacy = prefs.getBool(_themeKey);
        if (legacy != null) {
          state = legacy ? ThemeMode.dark : ThemeMode.light;
          // Migrate to string format so future reads are consistent.
          await prefs.setString(_themeKey, state.name);
        } else {
          state = ThemeMode.system;
        }
      }
      _updateThemeHelper();
    } catch (e) {
      debugPrint('Error loading theme mode: $e');
    }
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    try {
      // If currently following system, default toggle goes to explicit dark.
      final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      state = newMode;
      _updateThemeHelper();

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, newMode.name);
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
      await prefs.setString(_themeKey, mode.name);
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
