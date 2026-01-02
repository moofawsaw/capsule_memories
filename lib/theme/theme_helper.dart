import 'package:flutter/material.dart';

// Global theme accessors
ThemeColors get appTheme => ThemeHelper().themeColor();
ThemeData get theme => ThemeHelper().themeData();

/// Helper class for managing themes and colors.
class ThemeHelper {
  // Singleton pattern to ensure single instance
  static final ThemeHelper _instance = ThemeHelper._internal();
  factory ThemeHelper() => _instance;
  ThemeHelper._internal();

  // Current app theme mode
  var _themeMode = ThemeMode.dark;

  // Map of custom color themes
  Map<String, ThemeColors> _supportedCustomColor = {
    'dark': DarkModeColors(),
    'light': LightModeColors()
  };

  // Map of color schemes - initialized lazily to avoid circular dependency
  Map<String, ColorScheme>? _supportedColorScheme;

  Map<String, ColorScheme> get supportedColorScheme {
    if (_supportedColorScheme == null) {
      _supportedColorScheme = {
        'dark': ColorScheme.dark(
          primary: Color(0xFFA78BFA),
          surface: Color(0xFF0c0d13),
        ),
        'light': ColorScheme.light(
          primary: Color(0xFF7C3AED),
          surface: Color(0xFFFFFFFF),
        )
      };
    }
    return _supportedColorScheme!;
  }

  /// Set theme mode
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
  }

  /// Returns the colors for the current theme.
  ThemeColors _getThemeColors() {
    final isDark = _themeMode == ThemeMode.dark;
    return _supportedCustomColor[isDark ? 'dark' : 'light'] ?? DarkModeColors();
  }

  /// Returns the current theme data.
  ThemeData _getThemeData() {
    final isDark = _themeMode == ThemeMode.dark;
    final colors = _getThemeColors();
    var colorScheme = supportedColorScheme[isDark ? 'dark' : 'light'] ??
        supportedColorScheme['dark']!;

    return ThemeData(
      visualDensity: VisualDensity.standard,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.gray_900_02,
    );
  }

  /// Returns the colors for the current theme.
  ThemeColors themeColor() => _getThemeColors();

  /// Returns the current theme data.
  ThemeData themeData() => _getThemeData();

  /// Returns light theme configuration
  ThemeData lightTheme() {
    final colors = _supportedCustomColor['light']!;
    final colorScheme = supportedColorScheme['light']!;

    return ThemeData(
      visualDensity: VisualDensity.standard,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.gray_900_02,
    );
  }

  /// Returns dark theme configuration
  ThemeData darkTheme() {
    final colors = _supportedCustomColor['dark']!;
    final colorScheme = supportedColorScheme['dark']!;

    return ThemeData(
      visualDensity: VisualDensity.standard,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.gray_900_02,
    );
  }
}

class ColorSchemes {
  static final darkColorScheme = ColorScheme.dark(
    primary: appTheme.deep_purple_A100,
    surface: appTheme.gray_900_02,
  );

  static final lightColorScheme = ColorScheme.light(
    primary: appTheme.deep_purple_A100,
    surface: appTheme.gray_900_02,
  );
}

/// Base abstract class for theme colors
abstract class ThemeColors {
  // App Colors
  Color get deep_purple_A100;
  Color get gray_50;
  Color get blue_gray_300;
  Color get gray_900;
  Color get white_A700;
  Color get gray_900_01;
  Color get blue_gray_900;
  Color get gray_900_02;
  Color get gray_900_03;
  Color get blue_gray_900_01;
  Color get green_500;
  Color get deep_orange_100;
  Color get orange_100;
  Color get gray_300;
  Color get deep_purple_400_07;
  Color get black_900;
  Color get red_500;
  Color get deep_purple_A200;
  Color get deep_purple_A200_16;
  Color get pink_200;
  Color get blue_gray_500;
  Color get gray_700;
  Color get red_600;
  Color get blue_A700;
  Color get deep_orange_100_01;
  Color get red_800;
  Color get blue_300;
  Color get orange_A200;
  Color get deep_orange_A700;
  Color get blue_gray_900_02;
  Color get gray_400;
  Color get blue_gray_100;
  Color get blue_gray_900_03;
  Color get gray_900_04;
  Color get lime_900;
  Color get orange_600;
  Color get amber_600;
  Color get blue_A200;
  Color get teal_400;
  Color get orange_700;
  Color get pink_A200;
  Color get red_800_01;
  Color get red_800_02;
  Color get red_500_01;
  Color get red_A100;
  Color get red_600_01;
  Color get red_400;
  Color get green_800;
  Color get green_400;
  Color get amber_100;
  Color get orange_200;

  // Additional Colors
  Color get whiteCustom;
  Color get blackCustom;
  Color get transparentCustom;
  Color get redCustom;
  Color get greyCustom;
  Color get background_transparent;
  Color get colorFF52D1;
  Color get colorFFD81E;
  Color get color3BD81E;
  Color get colorDF0782;
  Color get color41C124;
  Color get color5B0000;
  Color get colorF716A8;
  Color get colorFF1A1A;
  Color get colorFF3A3A;
  Color get colorFF2A2A;
  Color get color800000;
  Color get color418724;
  Color get color4D0000;
  Color get colorFF2A27;
  Color get colorFF8B5C;
  Color get colorFF1E1E;
  Color get color3B8E1E;
  Color get colorFFC124;
  Color get colorFFE0E0;
  Color get color3B8724;

  // Color Shades
  Color get grey200;
  Color get grey100;
}

/// Dark mode color implementation
class DarkModeColors implements ThemeColors {
  // App Colors
  Color get deep_purple_A100 => Color(0xFFA78BFA);
  Color get gray_50 => Color(0xFFF8FAFC);
  Color get blue_gray_300 => Color(0xFF94A3B8);
  Color get gray_900 => Color(0xFF1B181E);
  Color get white_A700 => Color(0xFFFFFFFF);
  Color get gray_900_01 => Color(0xFF1D2636);
  Color get blue_gray_900 => Color(0xFF1E293B);
  Color get gray_900_02 => Color(0xFF0c0d13);
  Color get gray_900_03 => Color(0xFF221730);
  Color get blue_gray_900_01 => Color(0xFF242F41);
  Color get green_500 => Color(0xFF34B456);
  Color get deep_orange_100 => Color(0xFFF6D3BD);
  Color get orange_100 => Color(0xFFFFE5B8);
  Color get gray_300 => Color(0xFFE3E4E8);
  Color get deep_purple_400_07 => Color(0x078249DF);
  Color get black_900 => Color(0xFF000000);
  Color get red_500 => Color(0xFFEF4444);
  Color get deep_purple_A200 => Color(0xFF913AF9);
  Color get deep_purple_A200_16 => Color(0x16A855F7);
  Color get pink_200 => Color(0xFFF687A9);
  Color get blue_gray_500 => Color(0xFF66757F);
  Color get gray_700 => Color(0xFF865B51);
  Color get red_600 => Color(0xFFDD2E44);
  Color get blue_A700 => Color(0xFF0061FF);
  Color get deep_orange_100_01 => Color(0xFFFFC0B8);
  Color get red_800 => Color(0xFFBE1931);
  Color get blue_300 => Color(0xFF64AADD);
  Color get orange_A200 => Color(0xFFEE9547);
  Color get deep_orange_A700 => Color(0xFFD92F0A);
  Color get blue_gray_900_02 => Color(0xFF1F2937);
  Color get gray_400 => Color(0xFFC1C1C1);
  Color get blue_gray_100 => Color(0xFFD9D9D9);
  Color get blue_gray_900_03 => Color(0xFF253153);
  Color get gray_900_04 => Color(0xFF422B0D);
  Color get lime_900 => Color(0xFF896024);
  Color get orange_600 => Color(0xFFEB8F00);
  Color get amber_600 => Color(0xFFEAB308);
  Color get blue_A200 => Color(0xFF3B82F6);
  Color get teal_400 => Color(0xFF10B981);
  Color get orange_700 => Color(0xFFFF7A00);
  Color get pink_A200 => Color(0xFFFF4081);
  Color get red_800_01 => Color(0xFFAB3F2E);
  Color get red_800_02 => Color(0xFFC62828);
  Color get red_500_01 => Color(0xFFF44336);
  Color get red_A100 => Color(0xFFFF847A);
  Color get red_600_01 => Color(0xFFE53935);
  Color get red_400 => Color(0xFFEF5350);
  Color get green_800 => Color(0xFF2E7D32);
  Color get green_400 => Color(0xFF66BB6A);
  Color get amber_100 => Color(0xFFFFECB3);
  Color get orange_200 => Color(0xFFFFC06C);

  // Additional Colors
  Color get whiteCustom => Colors.white;
  Color get blackCustom => Colors.black;
  Color get transparentCustom => Colors.transparent;
  Color get redCustom => Colors.red;
  Color get greyCustom => Colors.grey;
  Color get background_transparent => Color(0xFF1D2636);
  Color get colorFF52D1 => Color(0xFF52D1C6);
  Color get colorFFD81E => Color(0xFFD81E29);
  Color get color3BD81E => Color(0xFF1D2636);
  Color get colorDF0782 => Color(0xDF078249);
  Color get color41C124 => Color(0xFF1D2636);
  Color get color5B0000 => Color(0x5B000000);
  Color get colorF716A8 => Color(0xFF110f1a);
  Color get colorFF1A1A => Color(0xFF1A1A1A);
  Color get colorFF3A3A => Color(0xFF3A3A3A);
  Color get colorFF2A2A => Color(0xFF2A2A2A);
  Color get color800000 => Color(0x80000000);
  Color get color418724 => Color(0xFF1D2636);
  Color get color4D0000 => Color(0x4D000000);
  Color get colorFF2A27 => Color(0xFF2A2731);
  Color get colorFF8B5C => Color(0xFF8B5CF6);
  Color get colorFF1E1E => Color(0xFF1E1E1E);
  Color get color3B8E1E => Color(0xFF1D2636);
  Color get colorFFC124 => Color(0xFFC1242F);
  Color get colorFFE0E0 => Color(0xFFE0E0E0);
  Color get color3B8724 => Color(0xFF1D2636);

  // Color Shades
  Color get grey200 => Colors.grey.shade200;
  Color get grey100 => Colors.grey.shade100;
}

/// Light mode color implementation - matching dark mode aesthetic
class LightModeColors implements ThemeColors {
  // App Colors - Light mode equivalents
  Color get deep_purple_A100 =>
      Color(0xFF7C3AED); // Darker purple for light mode
  Color get gray_50 => Color(0xFF1E293B); // Dark icons/text on light background
  Color get blue_gray_300 => Color(0xFF475569); // Darker blue-gray for icons
  Color get gray_900 => Color(0xFFF8FAFC); // Light backgrounds
  Color get white_A700 => Color(0xFFFFFFFF); // WHITE text on primary buttons
  Color get gray_900_01 => Color(0xFFF1F5F9); // Light surface
  Color get blue_gray_900 => Color(0xFFE2E8F0); // Light surface variant
  Color get gray_900_02 => Color(0xFFFFFFFF); // White background
  Color get gray_900_03 => Color(0xFFF8F4FF); // Light purple tint
  Color get blue_gray_900_01 => Color(0xFFEEF2FF); // Light blue surface
  Color get green_500 => Color(0xFF22C55E); // Vibrant green
  Color get deep_orange_100 => Color(0xFFFFEDD5); // Light orange
  Color get orange_100 => Color(0xFFFFF7ED); // Lighter orange
  Color get gray_300 => Color(0xFFCBD5E1); // Medium gray
  Color get deep_purple_400_07 => Color(0x077C3AED); // Transparent purple
  Color get black_900 =>
      Color(0xFF000000); // Black for list items/dropdown text
  Color get red_500 => Color(0xFFEF4444); // Keep red vibrant
  Color get deep_purple_A200 => Color(0xFF8B5CF6); // Rich purple
  Color get deep_purple_A200_16 => Color(0x168B5CF6); // Transparent purple
  Color get pink_200 => Color(0xFFFBBF24); // Golden accent
  Color get blue_gray_500 => Color(0xFF64748B); // Medium slate
  Color get gray_700 => Color(0xFFB45309); // Warm brown
  Color get red_600 => Color(0xFFDC2626); // Deep red
  Color get blue_A700 => Color(0xFF2563EB); // Bright blue
  Color get deep_orange_100_01 => Color(0xFFFFE4E6); // Light rose
  Color get red_800 => Color(0xFFA21CAF); // Magenta
  Color get blue_300 => Color(0xFF60A5FA); // Sky blue
  Color get orange_A200 => Color(0xFFF59E0B); // Amber
  Color get deep_orange_A700 => Color(0xFFEA580C); // Orange
  Color get blue_gray_900_02 => Color(0xFFF3F4F6); // Light gray
  Color get gray_400 => Color(0xFF9CA3AF); // Gray
  Color get blue_gray_100 => Color(0xFFE5E7EB); // Very light gray
  Color get blue_gray_900_03 => Color(0xFFEEF2FF); // Indigo tint
  Color get gray_900_04 => Color(0xFFFEF3C7); // Light yellow
  Color get lime_900 => Color(0xFFA16207); // Amber dark
  Color get orange_600 => Color(0xFFEA580C); // Orange
  Color get amber_600 => Color(0xFFD97706); // Amber
  Color get blue_A200 => Color(0xFF3B82F6); // Blue
  Color get teal_400 => Color(0xFF14B8A6); // Teal
  Color get orange_700 => Color(0xFFC2410C); // Dark orange
  Color get pink_A200 => Color(0xFFEC4899); // Pink
  Color get red_800_01 => Color(0xFF9F1239); // Dark red
  Color get red_800_02 => Color(0xFFB91C1C); // Red
  Color get red_500_01 => Color(0xFFEF4444); // Red
  Color get red_A100 => Color(0xFFFCA5A5); // Light red
  Color get red_600_01 => Color(0xFFDC2626); // Red
  Color get red_400 => Color(0xFFF87171); // Light red
  Color get green_800 => Color(0xFF166534); // Dark green
  Color get green_400 => Color(0xFF4ADE80); // Light green
  Color get amber_100 => Color(0xFFFEF3C7); // Very light amber
  Color get orange_200 => Color(0xFFFED7AA); // Light orange

  // Additional Colors - Light mode
  Color get whiteCustom => Color(0xFFFFFFFF); // WHITE for button text
  Color get blackCustom => Color(0xFF000000); // Black for list items
  Color get transparentCustom => Colors.transparent;
  Color get redCustom => Color(0xFFEF4444);
  Color get greyCustom => Color(0xFF64748B);
  Color get background_transparent => Color(0xFFF8FAFC);
  Color get colorFF52D1 => Color(0xFF06B6D4); // Cyan
  Color get colorFFD81E => Color(0xFFDC2626); // Red
  Color get color3BD81E => Color(0xFFE2E8F0); // Light surface
  Color get colorDF0782 => Color(0xDF7C3AED); // Purple
  Color get color41C124 => Color(0xFFE2E8F0); // Light divider
  Color get color5B0000 => Color(0x5BFFFFFF); // Transparent white
  Color get colorF716A8 => Color(0xFFF8FAFC); // Very light
  Color get colorFF1A1A => Color(0xFFF1F5F9); // Light gray
  Color get colorFF3A3A => Color(0xFFE2E8F0); // Lighter gray
  Color get colorFF2A2A => Color(0xFFEEF2FF); // Very light
  Color get color800000 => Color(0x80FFFFFF); // Transparent white
  Color get color418724 => Color(0xFFE2E8F0); // Light surface
  Color get color4D0000 => Color(0x4DFFFFFF); // Transparent white
  Color get colorFF2A27 => Color(0xFFF8FAFC); // Light surface
  Color get colorFF8B5C => Color(0xFF8B5CF6); // Purple
  Color get colorFF1E1E => Color(0xFFF9FAFB); // Almost white
  Color get color3B8E1E => Color(0xFFE2E8F0); // Light surface
  Color get colorFFC124 => Color(0xFFDC2626); // Red
  Color get colorFFE0E0 => Color(0xFF334155); // Dark gray
  Color get color3B8724 => Color(0xFFE2E8F0); // Light surface

  // Color Shades - Light mode
  Color get grey200 => Color(0xFF475569); // Darker for light mode
  Color get grey100 => Color(0xFF64748B); // Darker for light mode
}
