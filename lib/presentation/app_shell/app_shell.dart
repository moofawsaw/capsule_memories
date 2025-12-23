import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';

/// AppShell provides a persistent layout with header that remains static across navigation
/// This widget renders ONCE and only the child content changes on navigation
class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.gray_900_02,
      appBar: _buildPersistentHeader(),
      body: SafeArea(
        // Direct child rendering - no AnimatedSwitcher needed
        // The routing system handles content swapping
        child: child,
      ),
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
        ImageConstant.imgIconGray5032x32
      ],
      showProfileImage: true,
      showBottomBorder: true,
    );
  }
}
