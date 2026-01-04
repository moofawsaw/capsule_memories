import '../core/app_export.dart';

/// A helper class for managing text styles in the application
class TextStyleHelper {
  static TextStyleHelper? _instance;

  TextStyleHelper._();

  static TextStyleHelper get instance {
    _instance ??= TextStyleHelper._();
    return _instance!;
  }

  // Headline Styles
  // Medium-large text styles for section headers

  TextStyle get headline32 => TextStyle(
        fontSize: 32.fSize,
      );

  TextStyle get headline28ExtraBoldPlusJakartaSans => TextStyle(
        fontSize: 28.fSize,
        fontWeight: FontWeight.w800,
        fontFamily: 'Plus Jakarta Sans',
        color: appTheme.deep_purple_A100,
      );

  TextStyle get headline28ExtraBold => TextStyle(
        fontSize: 28.fSize,
        fontWeight: FontWeight.w800,
        color: appTheme.gray_50,
      );

  TextStyle get headline24 => TextStyle(
        fontSize: 24.fSize,
      );

  TextStyle get headline24ExtraBoldPlusJakartaSans => TextStyle(
        fontSize: 24.fSize,
        fontWeight: FontWeight.w800,
        fontFamily: 'Plus Jakarta Sans',
        color: appTheme.gray_50,
      );

  // Title Styles
  // Medium text styles for titles and subtitles

  TextStyle get title20 => TextStyle(
        fontSize: 20.fSize,
      );

  TextStyle get title20RegularRoboto => TextStyle(
        fontSize: 20.fSize,
        fontWeight: FontWeight.w400,
        fontFamily: 'Roboto',
      );

  TextStyle get title20BoldPlusJakartaSans => TextStyle(
        fontSize: 20.fSize,
        fontWeight: FontWeight.w700,
        fontFamily: 'Plus Jakarta Sans',
        color: appTheme.gray_50,
      );

  TextStyle get title20ExtraBoldPlusJakartaSans => TextStyle(
        fontSize: 20.fSize,
        fontWeight: FontWeight.w800,
        fontFamily: 'Plus Jakarta Sans',
        color: appTheme.gray_50,
      );

  TextStyle get title20Bold => TextStyle(
        fontSize: 20.fSize,
        fontWeight: FontWeight.w700,
        color: appTheme.gray_50,
      );

  TextStyle get title18BoldPlusJakartaSans => TextStyle(
        fontSize: 18.fSize,
        fontWeight: FontWeight.w700,
        fontFamily: 'Plus Jakarta Sans',
      );

  TextStyle get title18SemiBoldPlusJakartaSans => TextStyle(
        fontSize: 18.fSize,
        fontWeight: FontWeight.w600,
        fontFamily: 'Plus Jakarta Sans',
        color: appTheme.gray_50,
      );

  TextStyle get title18Bold => TextStyle(
        fontSize: 18.fSize,
        fontWeight: FontWeight.w700,
        color: appTheme.gray_50,
      );

  TextStyle get title16RegularPlusJakartaSans => TextStyle(
        fontSize: 16.fSize,
        fontWeight: FontWeight.w400,
        fontFamily: 'Plus Jakarta Sans',
      );

  TextStyle get title16BoldPlusJakartaSans => TextStyle(
        fontSize: 16.fSize,
        fontWeight: FontWeight.w700,
        fontFamily: 'Plus Jakarta Sans',
      );

  TextStyle get title16MediumPlusJakartaSans => TextStyle(
        fontSize: 16.fSize,
        fontWeight: FontWeight.w500,
        fontFamily: 'Plus Jakarta Sans',
        color: appTheme.gray_50,
      );

  TextStyle get title16SemiBold => TextStyle(
        fontSize: 16.fSize,
        fontWeight: FontWeight.w600,
        color: appTheme.blue_A700,
      );

  TextStyle get title16SemiBoldPlusJakartaSans => TextStyle(
        fontSize: 16.fSize,
        fontWeight: FontWeight.w600,
        fontFamily: 'Plus Jakarta Sans',
        color: appTheme.blue_A700,
      );

  // Body Styles
  // Standard text styles for body content

  TextStyle get body14 => TextStyle(
        fontSize: 14.fSize,
        color: appTheme.blue_gray_300,
      );

  TextStyle get body14MediumPlusJakartaSans => TextStyle(
        fontSize: 14.fSize,
        fontWeight: FontWeight.w500,
        fontFamily: 'Plus Jakarta Sans',
        color: appTheme.gray_50,
      );

  TextStyle get body14BoldPlusJakartaSans => TextStyle(
        fontSize: 14.fSize,
        fontWeight: FontWeight.w700,
        fontFamily: 'Plus Jakarta Sans',
      );

  TextStyle get body14RegularPlusJakartaSans => TextStyle(
        fontSize: 14.fSize,
        fontWeight: FontWeight.w400,
        fontFamily: 'Plus Jakarta Sans',
      );

  TextStyle get body14Regular => TextStyle(
        fontSize: 14.fSize,
        fontWeight: FontWeight.w400,
        color: appTheme.blue_gray_300,
      );

  TextStyle get body14SemiBold => TextStyle(
        fontSize: 14.fSize,
        fontWeight: FontWeight.w600,
        color: appTheme.gray_50,
      );

  TextStyle get body14Bold => TextStyle(
        fontSize: 14.fSize,
        fontWeight: FontWeight.w700,
        color: appTheme.gray_50,
      );

  TextStyle get body16BoldPlusJakartaSans => TextStyle(
        fontSize: 16.fSize,
        fontWeight: FontWeight.w700,
        fontFamily: 'Plus Jakarta Sans',
      );

  TextStyle get body16MediumPlusJakartaSans => TextStyle(
        fontSize: 16.fSize,
        fontWeight: FontWeight.w500,
        fontFamily: 'Plus Jakarta Sans',
        color: appTheme.gray_50,
      );

  TextStyle get body16RegularPlusJakartaSans => TextStyle(
        fontSize: 16.fSize,
        fontWeight: FontWeight.w400,
        fontFamily: 'Plus Jakarta Sans',
        color: appTheme.gray_50,
      );

  TextStyle get body12MediumPlusJakartaSans => TextStyle(
        fontSize: 12.fSize,
        fontWeight: FontWeight.w500,
        fontFamily: 'Plus Jakarta Sans',
        color: appTheme.blue_gray_300,
      );

  TextStyle get body12BoldPlusJakartaSans => TextStyle(
        fontSize: 12.fSize,
        fontWeight: FontWeight.w700,
        fontFamily: 'Plus Jakarta Sans',
      );

  TextStyle get body12Medium => TextStyle(
        fontSize: 12.fSize,
        fontWeight: FontWeight.w500,
        color: appTheme.gray_50,
      );

  TextStyle get body12Bold => TextStyle(
        fontSize: 12.fSize,
        fontWeight: FontWeight.w700,
        color: appTheme.gray_50,
      );

  TextStyle get body12RegularPlusJakartaSans => TextStyle(
        fontSize: 12.fSize,
        fontWeight: FontWeight.w400,
        fontFamily: 'Plus Jakarta Sans',
        color: appTheme.blue_gray_300,
      );

  // Label Styles
  // Small text styles for labels, captions, and hints

  TextStyle get label10RegularPlusJakartaSans => TextStyle(
        fontSize: 10.fSize,
        fontWeight: FontWeight.w400,
        fontFamily: 'Plus Jakarta Sans',
        color: appTheme.gray_50,
      );

  // Other Styles
  // Miscellaneous text styles without specified font size

  TextStyle get bodyTextPlusJakartaSans => TextStyle(
        fontFamily: 'Plus Jakarta Sans',
      );

  TextStyle get bodyTextRegularPlusJakartaSans => TextStyle(
        fontWeight: FontWeight.w400,
        fontFamily: 'Plus Jakarta Sans',
      );

  TextStyle get bodyTextExtraBoldPlusJakartaSans => TextStyle(
        fontWeight: FontWeight.w800,
        fontFamily: 'Plus Jakarta Sans',
      );

  // Body text styles
  TextStyle get body10BoldPlusJakartaSans => TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 10.fSize,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      );
}
