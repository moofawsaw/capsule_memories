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
    return Scaffold(
      backgroundColor: appTheme.gray_900_02,

      // ✅ Hide the app bar for fullscreen routes
      appBar: hideHeader ? null : _buildPersistentHeader(),

      // ✅ Only apply SafeArea when there is NO AppBar (fullscreen)
      body: hideHeader
          ? SafeArea(
        top: false,   // allow under status bar
        bottom: false,
        child: child,
      )
          : child,          // ✅ no SafeArea; AppBar already handled it
    );
  }

  /// Persistent header that renders once and stays visible across all /app routes
  PreferredSizeWidget _buildPersistentHeader() {
    return CustomAppBar(
      logoImagePath: ImageConstant.imgLogo,
      showIconButton: true,
      iconButtonImagePath: ImageConstant.imgFrame19,
      iconButtonBackgroundColor: appTheme.color3BD81E,
      actionIcons: [
        ImageConstant.imgIconGray50,
        ImageConstant.imgIconGray5032x32,
      ],
      showProfileImage: true,
      showBottomBorder: true,
    );
  }
}
