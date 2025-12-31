import '../../core/app_export.dart';
import '../../widgets/custom_icon_button_row.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_search_view.dart';
import '../qr_code_share_screen_two_screen/qr_code_share_screen_two_screen.dart';
import './notifier/friends_management_notifier.dart';
import './widgets/camera_scanner_screen.dart';
import './widgets/friends_section_widget.dart';
import './widgets/incoming_requests_section_widget.dart';
import './widgets/sent_requests_section_widget.dart';
import './widgets/user_search_results_widget.dart';

class FriendsManagementScreen extends ConsumerStatefulWidget {
  const FriendsManagementScreen({Key? key}) : super(key: key);

  @override
  FriendsManagementScreenState createState() => FriendsManagementScreenState();
}

class FriendsManagementScreenState
    extends ConsumerState<FriendsManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(friendsManagementNotifier.notifier).initialize();
    });
  }

  @override
  void dispose() {
    // Clean up camera when leaving screen
    ref.read(friendsManagementNotifier.notifier).closeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendsManagementNotifier);
    final notifier = ref.read(friendsManagementNotifier.notifier);

    // Show error message if present
    ref.listen<FriendsManagementState>(
      friendsManagementNotifier,
      (previous, next) {
        // Remove errorMessage checks - not defined in FriendsManagementState
        // Error messages are already handled through the errorMessage property in the state

        // Remove successMessage checks - not defined in FriendsManagementState
        // Success messages are already handled through the successMessage property in the state
      },
    );

    return SafeArea(
        child: Scaffold(
            backgroundColor: appTheme.gray_900_02,
            body: Container(
                width: double.infinity,
                child: Column(children: [
                  Expanded(
                      child: SingleChildScrollView(
                          child: Column(spacing: 24.h, children: [
                    _buildMainContentSection(context),
                  ]))),
                ]))));
  }

  /// Main content section with friends management
  Widget _buildMainContentSection(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(friendsManagementNotifier);
      final isSearching = (state.searchResults?.isNotEmpty ?? false) || (_searchQuery.isNotEmpty);

      return Container(
          margin:
              EdgeInsets.only(left: 16.h, top: 24.h, right: 20.h, bottom: 14.h),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildFriendsHeaderSection(context),
            SizedBox(height: 16.h),
            _buildSearchSection(context),
            SizedBox(height: 20.h),
            if (isSearching) ...[
              UserSearchResultsWidget(),
            ] else ...[
              FriendsSectionWidget(),
              SizedBox(height: 20.h),
              SentRequestsSectionWidget(),
              SizedBox(height: 20.h),
              IncomingRequestsSectionWidget(),
            ]
          ]));
    });
  }

  /// Friends header with count and action buttons
  Widget _buildFriendsHeaderSection(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(friendsManagementNotifier);
      final friendsCount = state.friendsManagementModel?.friendsList?.length ?? 0;

      return Container(
          margin: EdgeInsets.only(right: 6.h),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                width: 26.h,
                height: 26.h,
                margin: EdgeInsets.only(top: 2.h),
                child: CustomImageView(
                    imagePath: ImageConstant.imgIconDeepPurpleA100,
                    fit: BoxFit.contain)),
            SizedBox(width: 6.h),
            Container(
                margin: EdgeInsets.only(top: 2.h),
                child: Text('Friends ($friendsCount)',
                    style: TextStyleHelper
                        .instance.title20ExtraBoldPlusJakartaSans)),
            Expanded(
                child: Container(
                    alignment: Alignment.centerRight,
                    child: CustomIconButtonRow(
                        firstIconPath: ImageConstant.imgButtons,
                        secondIconPath: ImageConstant.imgButtonsGray50,
                        onFirstIconTap: () => _openQRShareBottomSheet(context),
                        onSecondIconTap: () => onTapCameraButton(context)))),
          ]));
    });
  }

  /// Open QR share bottom sheet
  void _openQRShareBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QRCodeShareScreenTwoScreen(),
    );
  }

  /// Search section
  Widget _buildSearchSection(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(friendsManagementNotifier);

      return Container(
          margin: EdgeInsets.only(left: 4.h),
          child: CustomSearchView(
              placeholder: 'Search for friends...',
              onChanged: (value) {
                ref
                    .read(friendsManagementNotifier.notifier)
                    .onSearchChanged(value);
              }));
    });
  }

  /// Navigate to add content
  void onTapAddButton(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appPost);
  }

  /// Navigate to notifications
  void onTapNotificationIcon(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appNotifications);
  }

  /// Navigate to notifications
  void onTapNotificationBell(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appNotifications);
  }

  /// Navigate to profile
  void onTapProfileImage(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appProfile);
  }

  /// Handle QR scan action
  void onTapQRScanButton(BuildContext context) {
    ref.read(friendsManagementNotifier.notifier).onQRScanTap();
  }

  /// Handle camera action
  void onTapCameraButton(BuildContext context) {
    ref.read(friendsManagementNotifier.notifier).onCameraTap();
  }

  /// Show permission denied dialog
  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appTheme.gray_900_01,
        title: Text(
          'Camera Permission Required',
          style: TextStyleHelper.instance.title16BoldPlusJakartaSans,
        ),
        content: Text(
          'Camera permission is required to scan QR codes. Please enable it in app settings.',
          style: TextStyleHelper.instance.body14MediumPlusJakartaSans,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyleHelper.instance.body14Regular,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(friendsManagementNotifier.notifier).openAppSettings();
            },
            child: Text(
              'Open Settings',
              style: TextStyleHelper.instance.body14Bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Open camera scanner
  void _openCameraScanner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScannerScreen(),
      ),
    ).then((_) {
      // Close camera when returning
      ref.read(friendsManagementNotifier.notifier).closeCamera();
    });
  }

  /// Show error snackbar
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: appTheme.red_500,
        duration: Duration(seconds: 3),
      ),
    );
  }
}