import 'package:flutter/material.dart';

import '../core/utils/auth_guard.dart';
import '../core/utils/navigator_service.dart';
import '../presentation/account_registration_screen/account_registration_screen.dart';
import '../presentation/add_memory_upload_screen/add_memory_upload_screen.dart';
import '../presentation/app_download_screen/app_download_screen.dart';
import '../presentation/app_navigation_screen/app_navigation_screen.dart';
import '../presentation/app_shell/app_shell.dart';
import '../presentation/color_selection_screen/color_selection_screen.dart';
import '../presentation/create_group_screen/create_group_screen.dart';
import '../presentation/create_memory_screen/create_memory_screen.dart';
import '../presentation/event_stories_view_screen/event_stories_view_screen.dart';
import '../presentation/event_timeline_view_screen/event_timeline_view_screen.dart';
import '../presentation/feature_request_screen/feature_request_screen.dart';
import '../presentation/followers_management_screen/followers_management_screen.dart';
import '../presentation/following_list_screen/following_list_screen.dart';
import '../presentation/friends_management_screen/friends_management_screen.dart';
import '../presentation/group_join_confirmation_screen/group_join_confirmation_screen.dart';
import '../presentation/group_qr_invite_screen/group_qr_invite_screen.dart';
import '../presentation/groups_management_screen/groups_management_screen.dart';
import '../presentation/hangout_call_screen/hangout_call_screen.dart';
import '../presentation/invite_people_screen/invite_people_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/memories_dashboard_screen/memories_dashboard_screen.dart';
import '../presentation/memory_details_screen/memory_details_screen.dart';
import '../presentation/memory_details_view_screen/memory_details_view_screen.dart';
import '../presentation/memory_feed_dashboard_screen/memory_feed_dashboard_screen.dart';
import '../presentation/memory_invitation_screen/memory_invitation_screen.dart';
import '../presentation/memory_members_screen/memory_members_screen.dart';
import '../presentation/notification_settings_screen/notification_settings_screen.dart';
import '../presentation/notifications_screen/notifications_screen.dart';
import '../presentation/password_reset_screen/password_reset_screen.dart';
import '../presentation/post_story_screen/post_story_screen.dart';
import '../presentation/qr_code_share_screen/qr_code_share_screen.dart';
import '../presentation/qr_code_share_screen_two_screen/qr_code_share_screen_two_screen.dart';
import '../presentation/report_story_screen/report_story_screen.dart';
import '../presentation/share_story_screen/share_story_screen.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/user_menu_screen/user_menu_screen.dart';
import '../presentation/user_profile_screen/user_profile_screen.dart';
import '../presentation/user_profile_screen_two_screen/user_profile_screen_two_screen.dart';
import '../presentation/vibe_selection_screen/vibe_selection_screen.dart';
import '../presentation/video_call_interface_screen/video_call_interface_screen.dart';
import '../presentation/video_call_screen/video_call_screen.dart';

class AppRoutes {
  // Auth routes (no header)
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authReset = '/auth/reset';

  // Top-level routes (no header)
  static const String splash = '/splash';

  // App shell route - renders AppShell with persistent header
  static const String app = '/app';

  // Child routes under /app (header persists, only content changes)
  static const String appHome = '/app/home';
  static const String appFeed = '/app/feed';
  static const String appMemories = '/app/memories';
  static const String appProfile = '/app/profile';
  static const String appProfileTwo = '/app/profile-two';
  static const String appNotifications = '/app/notifications';
  static const String appSettings = '/app/settings';
  static const String appFriends = '/app/friends';
  static const String appFollowers = '/app/followers';
  static const String appFollowing = '/app/following';
  static const String appGroups = '/app/groups';
  static const String appMenu = '/app/menu';
  static const String appNavigation = '/app/navigation';
  static const String appTimeline = '/app/timeline';
  static const String appTimelineSealed = '/app/timeline-sealed';
  static const String appVideoCall = '/app/video-call';
  static const String appReels = '/app/reels';
  static const String appPost = '/app/post';
  static const String appReport = '/app/report';
  static const String appStickers = '/app/stickers';
  static const String appJoin = '/app/join';
  static const String appFeedback = '/app/feedback';

  // Bottom sheet routes under /app
  static const String appBsMemoryCreate = '/app/bs/memory-create';
  static const String appBsShare = '/app/bs/share';
  static const String appBsInvite = '/app/bs/invite';
  static const String appBsMembers = '/app/bs/members';
  static const String appBsQrTimeline = '/app/bs/qr-timeline';
  static const String appBsQrFriend = '/app/bs/qr-friend';
  static const String appBsGroupCreate = '/app/bs/group-create';
  static const String appBsQrGroup = '/app/bs/qr-group';
  static const String appBsStories = '/app/bs/stories';
  static const String appBsUpload = '/app/bs/upload';
  static const String appBsDetails = '/app/bs/details';
  static const String appBsVibes = '/app/bs/vibes';
  static const String appBsQrMemory = '/app/bs/qr-memory';
  static const String appBsDownload = '/app/bs/download';

  // Overlay routes under /app
  static const String appOverlayText = '/app/overlay/text';

  static const String initialRoute = appFeed;

  /// Get the child widget for a given app route
  static Widget _getAppChild(String routeName) {
    switch (routeName) {
      case appHome:
        return HangoutCallScreen();
      case appFeed:
        return const MemoryFeedDashboardScreen();
      case appMemories:
        return MemoriesDashboardScreen();
      case appProfile:
        return UserProfileScreen();
      case appProfileTwo:
        return UserProfileScreenTwo();
      case appNotifications:
        return const NotificationsScreen();
      case appSettings:
        return NotificationSettingsScreen();
      case appFriends:
        return const FriendsManagementScreen();
      case appFollowers:
        return FollowersManagementScreen();
      case appFollowing:
        return FollowingListScreen();
      case appGroups:
        return GroupsManagementScreen();
      case appMenu:
        return UserMenuScreen();
      case appNavigation:
        return const AppNavigationScreen();
      case appTimeline:
        return EventTimelineViewScreen();
      case appTimelineSealed:
        return MemoryDetailsViewScreen();
      case appVideoCall:
        return VideoCallScreen();
      case appReels:
        return VideoCallInterfaceScreen();
      case appPost:
        return PostStoryScreen();
      case appReport:
        return ReportStoryScreen();
      case appStickers:
        return VibeSelectionScreen();
      case appJoin:
        return GroupJoinConfirmationScreen();
      case appFeedback:
        return FeatureRequestScreen();

      // Bottom sheet routes
      case appBsMemoryCreate:
        return CreateMemoryScreen();
      case appBsShare:
        return ShareStoryScreen();
      case appBsInvite:
        return InvitePeopleScreen();
      case appBsMembers:
        return MemoryMembersScreen();
      case appBsQrTimeline:
        return QRCodeShareScreen();
      case appBsQrFriend:
        return QRCodeShareScreenTwo();
      case appBsGroupCreate:
        return CreateGroupScreen();
      case appBsQrGroup:
        return GroupQRInviteScreen();
      case appBsStories:
        return EventStoriesViewScreen();
      case appBsUpload:
        return AddMemoryUploadScreen();
      case appBsDetails:
        return MemoryDetailsScreen();
      case appBsVibes:
        return VibeSelectionScreen();
      case appBsQrMemory:
        return MemoryInvitationScreen();
      case appBsDownload:
        return AppDownloadScreen();

      // Overlay routes
      case appOverlayText:
        return ColorSelectionScreen();

      default:
        return const MemoryFeedDashboardScreen();
    }
  }

  /// Check if route requires authentication
  static bool _requiresAuth(String routeName) {
    return routeName.startsWith('/app');
  }

  /// Check if route should have animation
  static bool _shouldAnimate(String routeName) {
    // Bottom sheets and overlays should have animation
    return routeName.contains('/bs/') || routeName.contains('/overlay/');
  }

  /// Custom route generator for nested routing
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name ?? '';

    // Auth routes (no header)
    if (routeName == authLogin) {
      return _buildRoute(LoginScreen(), settings, shouldAnimate: true);
    }
    if (routeName == authRegister) {
      return _buildRoute(AccountRegistrationScreen(), settings,
          shouldAnimate: true);
    }
    if (routeName == authReset) {
      return _buildRoute(PasswordResetScreen(), settings, shouldAnimate: true);
    }

    // Top-level routes (no header)
    if (routeName == splash) {
      return _buildRoute(SplashScreen(), settings, shouldAnimate: false);
    }

    // ✅ NEW: Special handling for menu overlay - slides from left over current screen
    if (routeName == appMenu) {
      return _buildSlideOverlayRoute(UserMenuScreen(), settings);
    }

    // App routes (with persistent header)
    if (routeName.startsWith('/app')) {
      final child = _getAppChild(routeName);
      final requiresAuth = _requiresAuth(routeName);
      final shouldAnimate = _shouldAnimate(routeName);

      // Wrap with auth guard if needed
      final protectedChild = requiresAuth
          ? AuthGuard.protectedRoute(
              NavigatorService.navigatorKey.currentContext!,
              routeName,
              child,
            )
          : child;

      // Wrap with AppShell for persistent header
      final shellChild = AppShell(child: protectedChild);

      return _buildRoute(shellChild, settings, shouldAnimate: shouldAnimate);
    }

    return null; // Unknown route
  }

  /// Build route with optional animation
  static Route<dynamic> _buildRoute(
    Widget child,
    RouteSettings settings, {
    required bool shouldAnimate,
  }) {
    if (shouldAnimate) {
      return MaterialPageRoute(
        builder: (context) => child,
        settings: settings,
      );
    } else {
      return PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        settings: settings,
      );
    }
  }

  /// ✅ NEW: Build slide overlay route - slides from left over current screen
  static Route<dynamic> _buildSlideOverlayRoute(
    Widget child,
    RouteSettings settings,
  ) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      settings: settings,
      opaque:
          false, // Makes the route transparent so previous screen shows through
      barrierColor: Colors.black.withAlpha(128), // Semi-transparent backdrop
      barrierDismissible: true, // Allow dismissing by tapping backdrop
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Slide animation from left to right
        const begin = Offset(-1.0, 0.0); // Start off-screen to the left
        const end = Offset.zero; // End at normal position
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  // Legacy route map for backward compatibility
  static Map<String, WidgetBuilder> get routes => {
        authLogin: (context) => LoginScreen(),
        authRegister: (context) => AccountRegistrationScreen(),
        authReset: (context) => PasswordResetScreen(),
        splash: (context) => SplashScreen(),
        // All app routes are handled by onGenerateRoute
      };
}
