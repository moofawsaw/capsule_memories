import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';

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

  @override
  Widget build(BuildContext context) {
    // Force rebuild of /app subtree when themeMode changes.
    // Many screens use the global `appTheme` (not Theme.of(context)),
    // so without this they won't repaint until navigation.
    final brightness = Theme.of(context).brightness;
    final keyedChild = KeyedSubtree(
      key: ValueKey(brightness),
      child: child,
    );

    return Scaffold(
      backgroundColor: appTheme.gray_900_02,

      // ✅ Hide the app bar for fullscreen routes
      appBar: hideHeader ? null : _buildPersistentHeader(context),

      // ✅ Only apply SafeArea when there is NO AppBar (fullscreen)
      body: hideHeader
          ? SafeArea(
        top: false,   // allow under status bar
        bottom: false,
        child: keyedChild,
      )
          : keyedChild,          // ✅ no SafeArea; AppBar already handled it
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
