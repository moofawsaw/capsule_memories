import 'package:flutter/material.dart';

LightCodeColors get appTheme => ThemeHelper().themeColor();
ThemeData get theme => ThemeHelper().themeData();

/// Helper class for managing themes and colors.

// ignore_for_file: must_be_immutable
class ThemeHelper {
  // The current app theme
  var _appTheme = "lightCode";

  // A map of custom color themes supported by the app
  Map<String, LightCodeColors> _supportedCustomColor = {
    'lightCode': LightCodeColors()
  };

  // A map of color schemes supported by the app
  Map<String, ColorScheme> _supportedColorScheme = {
    'lightCode': ColorSchemes.lightCodeColorScheme
  };

  /// Returns the lightCode colors for the current theme.
  LightCodeColors _getThemeColors() {
    return _supportedCustomColor[_appTheme] ?? LightCodeColors();
  }

  /// Returns the current theme data.
  ThemeData _getThemeData() {
    var colorScheme =
        _supportedColorScheme[_appTheme] ?? ColorSchemes.lightCodeColorScheme;
    return ThemeData(
      visualDensity: VisualDensity.standard,
      colorScheme: colorScheme,
    );
  }

  /// Returns the lightCode colors for the current theme.
  LightCodeColors themeColor() => _getThemeColors();

  /// Returns the current theme data.
  ThemeData themeData() => _getThemeData();
}

class ColorSchemes {
  static final lightCodeColorScheme = ColorScheme.light();
}

class LightCodeColors {
  // App Colors
  Color get deep_purple_A100 => Color(0xFFA78BFA);
  Color get gray_50 => Color(0xFFF8FAFC);
  Color get blue_gray_300 => Color(0xFF94A3B8);
  Color get gray_900 => Color(0xFF1B181E);
  Color get white_A700 => Color(0xFFFFFFFF);
  Color get gray_900_01 => Color(0xFF151319);
  Color get blue_gray_900 => Color(0xFF1E293B);
  Color get gray_900_02 => Color(0xFF12151D);
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
  Color get colorFF52D1 => Color(0xFF52D1C6);
  Color get colorFFD81E => Color(0xFFD81E29);
  Color get color3BD81E => Color(0x3BD81E29);
  Color get colorDF0782 => Color(0xDF078249);
  Color get color41C124 => Color(0x41C1242F);
  Color get color5B0000 => Color(0x5B000000);
  Color get colorF716A8 => Color(0xF716A855);
  Color get colorFF1A1A => Color(0xFF1A1A1A);
  Color get colorFF3A3A => Color(0xFF3A3A3A);
  Color get colorFF2A2A => Color(0xFF2A2A2A);
  Color get color800000 => Color(0x80000000);
  Color get color418724 => Color(0x4187242F);
  Color get color4D0000 => Color(0x4D000000);
  Color get colorFF2A27 => Color(0xFF2A2731);
  Color get colorFF8B5C => Color(0xFF8B5CF6);
  Color get colorFF1E1E => Color(0xFF1E1E1E);
  Color get color3B8E1E => Color(0x3B8E1E29);
  Color get colorFFC124 => Color(0xFFC1242F);
  Color get colorFFE0E0 => Color(0xFFE0E0E0);
  Color get color3B8724 => Color(0x3B87242F);

  // Color Shades - Each shade has its own dedicated constant
  Color get grey200 => Colors.grey.shade200;
  Color get grey100 => Colors.grey.shade100;
}
