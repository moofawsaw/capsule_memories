import '../core/app_export.dart';

// ... keep existing code ...

  ButtonStyle get fillDark => ElevatedButton.styleFrom(
        backgroundColor: appTheme.gray_900_01,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26.0),
        ),
      );
      
  ButtonStyle get fillSuccess => ElevatedButton.styleFrom(
        backgroundColor: appTheme.colorFF52D1,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26.0),
        ),
      );

  ButtonStyle get fillPrimary => ElevatedButton.styleFrom(
        backgroundColor: ThemeData().colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 0,
        padding: EdgeInsets.zero,
      );

  ButtonStyle get fillGreen => ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF10B981),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 0,
        padding: EdgeInsets.zero,
      );

  ButtonStyle get fillRed => ElevatedButton.styleFrom(
        backgroundColor: ThemeData().colorScheme.error,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 0,
        padding: EdgeInsets.zero,
      );

// ... rest of code ...