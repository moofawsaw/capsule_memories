import 'package:flutter/material.dart';
import '../presentation/invite_people_screen/invite_people_screen.dart';
import '../presentation/memory_invitation_screen/memory_invitation_screen.dart';
import '../presentation/group_join_confirmation_screen/group_join_confirmation_screen.dart';
import '../presentation/create_memory_screen/create_memory_screen.dart';
import '../presentation/create_group_screen/create_group_screen.dart';
import '../presentation/add_memory_upload_screen/add_memory_upload_screen.dart';
import '../presentation/account_registration_screen/account_registration_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/password_reset_screen/password_reset_screen.dart';
import '../presentation/video_call_interface_screen/video_call_interface_screen.dart';
import '../presentation/memory_feed_dashboard_screen/memory_feed_dashboard_screen.dart';
import '../presentation/event_stories_view_screen/event_stories_view_screen.dart';
import '../presentation/user_menu_screen/user_menu_screen.dart';
import '../presentation/user_profile_screen/user_profile_screen.dart';
import '../presentation/user_profile_screen_two_screen/user_profile_screen_two_screen.dart';
import '../presentation/memories_dashboard_screen/memories_dashboard_screen.dart';
import '../presentation/event_timeline_view_screen/event_timeline_view_screen.dart';
import '../presentation/memory_details_view_screen/memory_details_view_screen.dart';
import '../presentation/groups_management_screen/groups_management_screen.dart';
import '../presentation/friends_management_screen/friends_management_screen.dart';
import '../presentation/following_list_screen/following_list_screen.dart';
import '../presentation/followers_management_screen/followers_management_screen.dart';
import '../presentation/notifications_screen/notifications_screen.dart';
import '../presentation/notification_settings_screen/notification_settings_screen.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/feature_request_screen/feature_request_screen.dart';
import '../presentation/report_story_screen/report_story_screen.dart';
import '../presentation/post_story_screen/post_story_screen.dart';
import '../presentation/hangout_call_screen/hangout_call_screen.dart';
import '../presentation/video_call_screen/video_call_screen.dart';
import '../presentation/color_selection_screen/color_selection_screen.dart';
import '../presentation/vibe_selection_screen/vibe_selection_screen.dart';
import '../presentation/share_story_screen/share_story_screen.dart';
import '../presentation/vibe_selection_screen_two_screen/vibe_selection_screen_two_screen.dart';
import '../presentation/memory_members_screen/memory_members_screen.dart';
import '../presentation/memory_details_screen/memory_details_screen.dart';
import '../presentation/qr_code_share_screen/qr_code_share_screen.dart';
import '../presentation/group_qr_invite_screen/group_qr_invite_screen.dart';
import '../presentation/app_download_screen/app_download_screen.dart';
import '../presentation/qr_code_share_screen_two_screen/qr_code_share_screen_two_screen.dart';

import '../presentation/app_navigation_screen/app_navigation_screen.dart';

class AppRoutes {
  static const String invitePeopleScreen = '/invite_people_screen';
  static const String memoryInvitationScreen = '/memory_invitation_screen';
  static const String groupJoinConfirmationScreen =
      '/group_join_confirmation_screen';
  static const String createMemoryScreen = '/create_memory_screen';
  static const String createGroupScreen = '/create_group_screen';
  static const String addMemoryUploadScreen = '/add_memory_upload_screen';
  static const String accountRegistrationScreen =
      '/account_registration_screen';
  static const String loginScreen = '/login_screen';
  static const String passwordResetScreen = '/password_reset_screen';
  static const String videoCallInterfaceScreen = '/video_call_interface_screen';
  static const String memoryFeedDashboardScreen =
      '/memory_feed_dashboard_screen';
  static const String eventStoriesViewScreen = '/event_stories_view_screen';
  static const String userMenuScreen = '/user_menu_screen';
  static const String userProfileScreen = '/user_profile_screen';
  static const String userProfileScreenTwo = '/user_profile_screen_two';
  static const String memoriesDashboardScreen = '/memories_dashboard_screen';
  static const String eventTimelineViewScreen = '/event_timeline_view_screen';
  static const String memoryDetailsViewScreen = '/memory_details_view_screen';
  static const String groupsManagementScreen = '/groups_management_screen';
  static const String friendsManagementScreen = '/friends_management_screen';
  static const String followingListScreen = '/following_list_screen';
  static const String followersManagementScreen =
      '/followers_management_screen';
  static const String notificationsScreen = '/notifications_screen';
  static const String notificationSettingsScreen =
      '/notification_settings_screen';
  static const String splashScreen = '/splash_screen';
  static const String featureRequestScreen = '/feature_request_screen';
  static const String reportStoryScreen = '/report_story_screen';
  static const String postStoryScreen = '/post_story_screen';
  static const String hangoutCallScreen = '/hangout_call_screen';
  static const String videoCallScreen = '/video_call_screen';
  static const String colorSelectionScreen = '/color_selection_screen';
  static const String vibeSelectionScreen = '/vibe_selection_screen';
  static const String shareStoryScreen = '/share_story_screen';
  static const String vibeSelectionScreenTwo = '/vibe_selection_screen_two';
  static const String memoryMembersScreen = '/memory_members_screen';
  static const String memoryDetailsScreen = '/memory_details_screen';
  static const String qRCodeShareScreen = '/q_r_code_share_screen';
  static const String groupQRInviteScreen = '/group_q_r_invite_screen';
  static const String appDownloadScreen = '/app_download_screen';
  static const String qRCodeShareScreenTwo = '/q_r_code_share_screen_two';

  static const String appNavigationScreen = '/app_navigation_screen';
  static const String initialRoute = '/';

  static Map<String, WidgetBuilder> get routes => {
        invitePeopleScreen: (context) => InvitePeopleScreen(),
        memoryInvitationScreen: (context) => MemoryInvitationScreen(),
        groupJoinConfirmationScreen: (context) => GroupJoinConfirmationScreen(),
        createMemoryScreen: (context) => CreateMemoryScreen(),
        createGroupScreen: (context) => CreateGroupScreen(),
        addMemoryUploadScreen: (context) => AddMemoryUploadScreen(),
        accountRegistrationScreen: (context) => AccountRegistrationScreen(),
        loginScreen: (context) => LoginScreen(),
        passwordResetScreen: (context) => PasswordResetScreen(),
        videoCallInterfaceScreen: (context) => VideoCallInterfaceScreen(),
        memoryFeedDashboardScreen: (context) => MemoryFeedDashboardScreen(),
        eventStoriesViewScreen: (context) => EventStoriesViewScreen(),
        userMenuScreen: (context) => UserMenuScreen(),
        userProfileScreen: (context) => UserProfileScreen(),
        userProfileScreenTwo: (context) => UserProfileScreenTwo(),
        memoriesDashboardScreen: (context) => MemoriesDashboardScreen(),
        eventTimelineViewScreen: (context) => EventTimelineViewScreen(),
        memoryDetailsViewScreen: (context) => MemoryDetailsViewScreen(),
        groupsManagementScreen: (context) => GroupsManagementScreen(),
        friendsManagementScreen: (context) => FriendsManagementScreen(),
        followingListScreen: (context) => FollowingListScreen(),
        followersManagementScreen: (context) => FollowersManagementScreen(),
        notificationsScreen: (context) => NotificationsScreen(),
        notificationSettingsScreen: (context) => NotificationSettingsScreen(),
        splashScreen: (context) => SplashScreen(),
        featureRequestScreen: (context) => FeatureRequestScreen(),
        reportStoryScreen: (context) => ReportStoryScreen(),
        postStoryScreen: (context) => PostStoryScreen(),
        hangoutCallScreen: (context) => HangoutCallScreen(),
        videoCallScreen: (context) => VideoCallScreen(),
        colorSelectionScreen: (context) => ColorSelectionScreen(),
        vibeSelectionScreen: (context) => VibeSelectionScreen(),
        shareStoryScreen: (context) => ShareStoryScreen(),
        vibeSelectionScreenTwo: (context) => VibeSelectionScreenTwo(),
        memoryMembersScreen: (context) => MemoryMembersScreen(),
        memoryDetailsScreen: (context) => MemoryDetailsScreen(),
        qRCodeShareScreen: (context) => QRCodeShareScreen(),
        groupQRInviteScreen: (context) => GroupQRInviteScreen(),
        appDownloadScreen: (context) => AppDownloadScreen(),
        qRCodeShareScreenTwo: (context) => QRCodeShareScreenTwo(),
        appNavigationScreen: (context) => AppNavigationScreen(),
        initialRoute: (context) => AppNavigationScreen()
      };
}
