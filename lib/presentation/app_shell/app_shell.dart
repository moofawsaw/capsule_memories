import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import 'package:flutter/services.dart';

/// AppShell provides a persistent layout with header that remains static across navigation
/// This widget renders ONCE and only the child content changes on navigation
class AppShell extends StatelessWidget {
  final Widget child;

  /// ✅ When true, AppShell will NOT render the persistent header and will allow full-screen UI.
  /// Use this for camera / story edit / story view flows.
  final bool hideHeader;

  const AppShell({
    Key? key,
    required this.child,
    this.hideHeader = false,
  }) : super(key: key);

  SystemUiOverlayStyle _overlayStyleForBackground(Color background) {
    final brightness = ThemeData.estimateBrightnessForColor(background);
    final bool isLightBg = brightness == Brightness.light;

    // iOS uses statusBarBrightness; Android uses statusBarIconBrightness.
    return (isLightBg ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light)
        .copyWith(
      statusBarColor: Colors.transparent, // Android
      statusBarBrightness: isLightBg ? Brightness.light : Brightness.dark, // iOS
      statusBarIconBrightness: isLightBg ? Brightness.dark : Brightness.light, // Android
    );
  }

  @override
  Widget build(BuildContext context) {
    // Force rebuild of /app subtree when themeMode changes.
    // Many screens use the global `appTheme` (not Theme.of(context)),
    // so without this they won't repaint until navigation.
    final themeBrightness = Theme.of(context).brightness;

    // Determine status bar style from the actual background this shell paints.
    // This avoids mismatches where the theme is light but the screen background is dark
    // (or vice-versa). Flutter does NOT infer this for you.
    final Color shellBackground = appTheme.gray_900_02;
    final SystemUiOverlayStyle overlayStyle = hideHeader
        // Fullscreen flows in this app are generally dark (camera/story), so prefer white icons.
        ? _overlayStyleForBackground(appTheme.gray_900_02)
        : _overlayStyleForBackground(shellBackground);
    final keyedChild = KeyedSubtree(
      key: ValueKey(themeBrightness),
      child: child,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: shellBackground,

        // ✅ Hide the app bar for fullscreen routes
        appBar: hideHeader ? null : _buildPersistentHeader(context),

        // ✅ Only apply SafeArea when there is NO AppBar (fullscreen)
        body: hideHeader
            ? SafeArea(
                top: false, // allow under status bar
                bottom: false,
                child: keyedChild,
              )
            : keyedChild, // ✅ no SafeArea; AppBar already handled it
      ),
    );
  }

  /// Persistent header that renders once and stays visible across all /app routes
  PreferredSizeWidget _buildPersistentHeader(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return CustomAppBar(
      logoImagePath: isLight ? ImageConstant.imgLogoLight : ImageConstant.imgLogo,
      showIconButton: true,
      iconButtonBackgroundColor: appTheme.color3BD81E,
      actionIcons: [
        CustomAppBarActionType.memories,
        CustomAppBarActionType.notifications,
      ],
      showProfileImage: true,
      showBottomBorder: true,
    );
  }
}
