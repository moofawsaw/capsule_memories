import 'package:flutter/material.dart';
import '../presentation/hangout_call_screen/hangout_call_screen.dart';
import '../presentation/color_selection_screen/color_selection_screen.dart';
import '../presentation/memory_details_view_screen/memory_details_view_screen.dart';
import '../presentation/app_download_screen/app_download_screen.dart';
import '../presentation/feature_request_screen/feature_request_screen.dart';
import '../presentation/memory_feed_dashboard_screen/memory_feed_dashboard_screen.dart';
import '../presentation/followers_management_screen/followers_management_screen.dart';
import '../presentation/following_list_screen/following_list_screen.dart';
import '../presentation/friends_management_screen/friends_management_screen.dart';
import '../presentation/groups_management_screen/groups_management_screen.dart';
import '../presentation/group_join_confirmation_screen/group_join_confirmation_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/memories_dashboard_screen/memories_dashboard_screen.dart';
import '../presentation/user_menu_screen/user_menu_screen.dart';
import '../presentation/app_navigation_screen/app_navigation_screen.dart';
import '../presentation/notifications_screen/notifications_screen.dart';
import '../presentation/post_story_screen/post_story_screen.dart';
import '../presentation/user_profile_screen/user_profile_screen.dart';
import '../presentation/user_profile_screen_two_screen/user_profile_screen_two_screen.dart';
import '../presentation/account_registration_screen/account_registration_screen.dart';
import '../presentation/report_story_screen/report_story_screen.dart';
import '../presentation/password_reset_screen/password_reset_screen.dart';
import '../presentation/notification_settings_screen/notification_settings_screen.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/event_timeline_view_screen/event_timeline_view_screen.dart';
import '../presentation/video_call_screen/video_call_screen.dart';
import '../presentation/video_call_interface_screen/video_call_interface_screen.dart';
import '../presentation/create_memory_screen/create_memory_screen.dart';
import '../presentation/share_story_screen/share_story_screen.dart';
import '../presentation/invite_people_screen/invite_people_screen.dart';
import '../presentation/memory_members_screen/memory_members_screen.dart';
import '../presentation/create_group_screen/create_group_screen.dart';
import '../presentation/event_stories_view_screen/event_stories_view_screen.dart';
import '../presentation/add_memory_upload_screen/add_memory_upload_screen.dart';
import '../presentation/memory_details_screen/memory_details_screen.dart';
import '../presentation/vibe_selection_screen/vibe_selection_screen.dart';
import '../presentation/qr_code_share_screen/qr_code_share_screen.dart';
import '../presentation/group_qr_invite_screen/group_qr_invite_screen.dart';
import '../presentation/qr_code_share_screen_two_screen/qr_code_share_screen_two_screen.dart';
import '../presentation/memory_invitation_screen/memory_invitation_screen.dart';

class AppRoutes {
  static const String colorsScreen = '/colors';
  static const String timelineSealed = '/timeline_sealed';
  static const String downloadScreen = '/download';
  static const String feedbackScreen = '/feedback';
  static const String feedScreen = '/feed';
  static const String followersScreen = '/followers';
  static const String followingScreen = '/following';
  static const String friendsScreen = '/friends';
  static const String groupsScreen = '/groups';
  static const String homeScreen = '/home';
  static const String joinScreen = '/join';
  static const String loginScreen = '/login';
  static const String memoriesScreen = '/memories';
  static const String menuScreen = '/menu';
  static const String navigationScreen = '/navigation';
  static const String notificationsScreen = '/notifications';
  static const String postScreen = '/post';
  static const String profileScreen = '/profile';
  static const String profileTwoScreen = '/profile_two';
  static const String reelsScreen = '/reels';
  static const String registerScreen = '/register';
  static const String reportScreen = '/report';
  static const String resetScreen = '/reset';
  static const String settingsScreen = '/settings';
  static const String splashScreen = '/splash';
  static const String stickersScreen = '/stickers';
  static const String timelineScreen = '/timeline';
  static const String videoCallScreen = '/video_call';

  // Bottom Sheet Route Definitions - restored for navigation compatibility
  static const String bs_memoryCreateScreen = '/bs_memory_create';
  static const String bs_shareScreen = '/bs_share';
  static const String bs_inviteScreen = '/bs_invite';
  static const String bs_membersScreen = '/bs_members';
  static const String bs_qr_timeline = '/bs_qr_timeline';
  static const String bs_qrFriendScreen = '/bs_qr_friend';
  static const String bs_groupCreateScreen = '/bs_group_create';
  static const String bs_qrGroupScreen = '/bs_qr_group';
  static const String bs_storiesScreen = '/bs_stories';
  static const String bs_uploadScreen = '/bs_upload';
  static const String bs_detailsScreen = '/bs_details';
  static const String bs_vibesScreen = '/bs_vibes';
  static const String bs_qr_memoryScreen = '/bs_qr_memory';

  static const String initialRoute = '/feed';

  static Map<String, WidgetBuilder> get routes => {
        colorsScreen: (context) => ColorSelectionScreen(),
        timelineSealed: (context) => MemoryDetailsViewScreen(),
        downloadScreen: (context) => AppDownloadScreen(),
        feedbackScreen: (context) => FeatureRequestScreen(),
        feedScreen: (context) => MemoryFeedDashboardScreen(),
        followersScreen: (context) => FollowersManagementScreen(),
        followingScreen: (context) => FollowingListScreen(),
        friendsScreen: (context) => const FriendsManagementScreen(),
        groupsScreen: (context) => GroupsManagementScreen(),
        homeScreen: (context) => HangoutCallScreen(),
        joinScreen: (context) => GroupJoinConfirmationScreen(),
        loginScreen: (context) => LoginScreen(),
        memoriesScreen: (context) => MemoriesDashboardScreen(),
        menuScreen: (context) => UserMenuScreen(),
        navigationScreen: (context) => const AppNavigationScreen(),
        notificationsScreen: (context) => NotificationsScreen(),
        postScreen: (context) => PostStoryScreen(),
        profileScreen: (context) => UserProfileScreen(),
        profileTwoScreen: (context) => UserProfileScreenTwo(),
        reelsScreen: (context) => VideoCallInterfaceScreen(),
        registerScreen: (context) => AccountRegistrationScreen(),
        reportScreen: (context) => ReportStoryScreen(),
        resetScreen: (context) => PasswordResetScreen(),
        settingsScreen: (context) => NotificationSettingsScreen(),
        splashScreen: (context) => SplashScreen(),
        stickersScreen: (context) => VibeSelectionScreen(),
        timelineScreen: (context) => EventTimelineViewScreen(),
        videoCallScreen: (context) => VideoCallScreen(),

        // Bottom sheet routes
        bs_memoryCreateScreen: (context) => CreateMemoryScreen(),
        bs_shareScreen: (context) => ShareStoryScreen(),
        bs_inviteScreen: (context) => InvitePeopleScreen(),
        bs_membersScreen: (context) => MemoryMembersScreen(),
        bs_qr_timeline: (context) => QRCodeShareScreen(),
        bs_qrFriendScreen: (context) => QRCodeShareScreenTwo(),
        bs_groupCreateScreen: (context) => CreateGroupScreen(),
        bs_qrGroupScreen: (context) => GroupQRInviteScreen(),
        bs_storiesScreen: (context) => EventStoriesViewScreen(),
        bs_uploadScreen: (context) => AddMemoryUploadScreen(),
        bs_detailsScreen: (context) => MemoryDetailsScreen(),
        bs_vibesScreen: (context) => VibeSelectionScreen(),
        bs_qr_memoryScreen: (context) => MemoryInvitationScreen(),

        initialRoute: (context) => MemoryFeedDashboardScreen()
      };
}
