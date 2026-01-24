// lib/core/utils/image_constant.dart
class ImageConstant {
  ImageConstant._();

  static const String _basePath = 'assets/images/';

  /// App logo (the ONLY asset used throughout the app UI).
  static const String imgLogo = '${_basePath}logo.svg';

  /// Splash assets (used by native splash + splash screen).
  static const String iosSplash = '${_basePath}ios_splash.png';
  static const String androidSplash = '${_basePath}android_splash.png';
  static const String splashLogo = '${_basePath}splash_logo.png';
  static const String splashIcon = '${_basePath}splash_icon.png';
}
