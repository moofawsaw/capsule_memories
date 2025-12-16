import 'package:flutter/material.dart';
import '../../core/app_export.dart';

import '../video_call_interface_screen/video_call_interface_screen.dart';
import '../event_stories_view_screen/event_stories_view_screen.dart';
import '../share_story_screen/share_story_screen.dart';
import '../vibe_selection_screen_two_screen/vibe_selection_screen_two_screen.dart';

class AppNavigationScreen extends ConsumerStatefulWidget {
  const AppNavigationScreen({Key? key}) : super(key: key);

  @override
  AppNavigationScreenState createState() => AppNavigationScreenState();
}

class AppNavigationScreenState extends ConsumerState<AppNavigationScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0XFFFFFFFF),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.only(top: 10.h),
                  child: Column(
                    children: [
                      _buildScreenTitle(
                        context,
                        screenTitle: "BottomSheet/Memory/AddUsers",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.invitePeopleScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "BottomSheet/Memory/InviteCard",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.memoryInvitationScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "Modal/RequestFeature One",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.groupJoinConfirmationScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "BottomSheet/Memory/Create",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.createMemoryScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "BottomSheet/Group/Create One",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.createGroupScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "BottomSheet/Group/Create",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.addMemoryUploadScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "Screen/Auth/Signup",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.accountRegistrationScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "Screen/Auth/Login",
                        onTapScreenTitle: () =>
                            onTapScreenTitle(context, AppRoutes.loginScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "Screen/Auth/ForgotPassword",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.passwordResetScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "Screen/Reel",
                        onTapScreenTitle: () => onTapBottomSheetTitle(
                            context, VideoCallInterfaceScreen()),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "Screen/Home",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.memoryFeedDashboardScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "BottomSheet/Memory/QuickView",
                        onTapScreenTitle: () => onTapBottomSheetTitle(
                            context, EventStoriesViewScreen()),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "Drawer/UserAccount",
                        onTapScreenTitle: () =>
                            onTapScreenTitle(context, AppRoutes.userMenuScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "Screen/User",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.userProfileScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "Screen/Profile/Profile",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.userProfileScreenTwo),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "Screen/Profile/Memories",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.memoriesDashboardScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "Screen/Profile/Memories/Details",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.eventTimelineViewScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "Screen/Profile/Memories/Details(sealed)",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.memoryDetailsViewScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "Screen/Profile/Groups",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.groupsManagementScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "Screen/Profile/Friends",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.friendsManagementScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "Screen/Profile/Following One",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.followingListScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "Screen/Profile/Followers",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.followersManagementScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "Screen/Profile/Following",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.notificationsScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "Screen/Profile/Settings",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.notificationSettingsScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "Screen/Splash",
                        onTapScreenTitle: () =>
                            onTapScreenTitle(context, AppRoutes.splashScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "Modal/RequestFeature",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.featureRequestScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "Modal/ReportStory",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.reportStoryScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "Screen/Story/Editor",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.postStoryScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "Screen/Story/Record",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.hangoutCallScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "Screen/Story/View",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.videoCallScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "Overlay/StoryEditor/AddText",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.colorSelectionScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "BottomSheet/StoryEditor/Music",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.vibeSelectionScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "BottomSheet/Story/Share",
                        onTapScreenTitle: () =>
                            onTapBottomSheetTitle(context, ShareStoryScreen()),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "BottomSheet/StoryEditor/Stickers",
                        onTapScreenTitle: () => onTapBottomSheetTitle(
                            context, VibeSelectionScreenTwo()),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "BottomSheet/Memory/Members",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.memoryMembersScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "BottomSheet/Memory/Edit",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.memoryDetailsScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "BottomSheet/Share/Invite",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.qRCodeShareScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "BottomSheet/Share/Group",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.groupQRInviteScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "BottomSheet/ShareApp",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.appDownloadScreen),
                      ),
                      _buildScreenTitle(
                        context,
                        screenTitle: "BottomSheet/Share/UserQR",
                        onTapScreenTitle: () => onTapScreenTitle(
                            context, AppRoutes.qRCodeShareScreenTwo),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// Common widget
  Widget _buildScreenTitle(
    BuildContext context, {
    required String screenTitle,
    Function? onTapScreenTitle,
  }) {
    return GestureDetector(
      onTap: () {
        onTapScreenTitle?.call();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.h),
        decoration: BoxDecoration(color: Color(0XFFFFFFFF)),
        child: Column(
          children: [
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  screenTitle,
                  textAlign: TextAlign.center,
                  style: TextStyleHelper.instance.title20RegularRoboto
                      .copyWith(color: Color(0XFF000000)),
                ),
                Icon(
                  Icons.arrow_forward,
                  color: Color(0XFF343330),
                )
              ],
            ),
            SizedBox(height: 10.h),
            Divider(height: 1.h, thickness: 1.h, color: Color(0XFFD2D2D2)),
          ],
        ),
      ),
    );
  }

  /// Common click event
  void onTapScreenTitle(BuildContext context, String routeName) {
    NavigatorService.pushNamed(routeName);
  }

  /// Common click event for bottomsheet
  void onTapBottomSheetTitle(BuildContext context, Widget className) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return className;
      },
      isScrollControlled: true,
      backgroundColor: appTheme.transparentCustom,
    );
  }

  /// Common click event for dialog
  void onTapDialogTitle(BuildContext context, Widget className) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: className,
          backgroundColor: appTheme.transparentCustom,
          insetPadding: EdgeInsets.zero,
        );
      },
    );
  }
}
