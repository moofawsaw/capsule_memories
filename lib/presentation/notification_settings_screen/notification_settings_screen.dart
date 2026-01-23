import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../presentation/user_menu_screen/notifier/user_menu_notifier.dart';
import '../../services/blocked_users_service.dart';
import '../../widgets/custom_about_settings.dart';
import '../../widgets/custom_account_settings.dart';
import '../../widgets/custom_blocked_users_settings.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_notification_settings.dart';
import '../../widgets/custom_privacy_settings.dart';
import '../../widgets/custom_settings_row.dart';
import '../../widgets/custom_support_settings.dart';
import '../../widgets/custom_warning_modal.dart';
import 'notifier/notification_settings_notifier.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  NotificationSettingsScreenState createState() =>
      NotificationSettingsScreenState();
}

class NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  // ===== External URLs =====
  static const String _privacyUrl = 'https://capapp.co/privacy';
  static const String _termsUrl = 'https://capapp.co/terms';
  static const String _helpUrl = 'https://capapp.co/help';
  static const String _contactUrl = 'https://capapp.co/contact';

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.parse(url);

    await launchUrl(
      uri,
      mode: LaunchMode.inAppWebView,
    );
  }

  final BlockedUsersService _blockedUsersService = BlockedUsersService();
  List<Map<String, dynamic>> _blockedUsers = [];
  bool _isLoadingBlockedUsers = false;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    if (!mounted) return;

    setState(() {
      _isLoadingBlockedUsers = true;
    });

    try {
      final users = await _blockedUsersService.getBlockedUsers();
      if (mounted) {
        setState(() {
          _blockedUsers = users;
          _isLoadingBlockedUsers = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading blocked users: $e');
      if (mounted) {
        setState(() {
          _isLoadingBlockedUsers = false;
        });
      }
    }
  }

  Future<void> _handleUnblockUser(String userId, String username) async {
    try {
      final success = await _blockedUsersService.unblockUser(userId);

      if (success && mounted) {
        // Remove from local list immediately for better UX
        setState(() {
          _blockedUsers.removeWhere((user) => user['user_id'] == userId);
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$username has been unblocked'),
            backgroundColor: appTheme.color3BD81E,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to unblock user'),
            backgroundColor: appTheme.red_500,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error unblocking user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('An error occurred'),
            backgroundColor: appTheme.red_500,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.gray_900_02,
      body: SingleChildScrollView(
        child: Container(
          width: double.maxFinite,
          padding: EdgeInsets.symmetric(vertical: 26.h),
          child: Column(
            spacing: 30.h,
            children: [
              _buildSettingsHeader(context),
              _buildDarkModeSection(context),
              _buildNotificationSettings(context),
              _buildAccountSettings(context),
              _buildBlockedUsersSettings(context),
              _buildSupportSettings(context),
              _buildAboutSettings(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildSettingsHeader(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.h),
      child: Row(
        children: [
          CustomImageView(
            imagePath: ImageConstant.imgIcon26x26,
            height: 26.h,
            width: 26.h,
          ),
          SizedBox(width: 6.h),
          Text(
            'Settings',
            style: TextStyleHelper.instance.title20ExtraBoldPlusJakartaSans,
          ),
        ],
      ),
    );
  }

  /// Dark mode toggle section - moved from user menu
  Widget _buildDarkModeSection(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(userMenuNotifier);

      return CustomSettingsRow(
        iconPath: ImageConstant.imgIcon5,
        title: 'Dark mode',
        description: 'Toggle dark mode on or off',
        switchValue: state.userMenuModel?.isDarkModeEnabled ?? true,
        onSwitchChanged: (value) =>
            ref.read(userMenuNotifier.notifier).toggleDarkMode(),
        margin: EdgeInsets.only(left: 16.h, right: 24.h),
      );
    });
  }

  /// Section Widget
  Widget _buildNotificationSettings(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(notificationSettingsNotifier);
        final pushEnabled = state.pushNotificationsEnabled ?? true;

        return CustomNotificationSettings(
          headerIcon: ImageConstant.imgIcon1,
          headerTitle: 'Notifications',
          pushNotificationsEnabled: pushEnabled,
          onPushNotificationsChanged: (value) {
            ref
                .read(notificationSettingsNotifier.notifier)
                .updatePushNotifications(value);
          },
          notificationOptions: [
            CustomNotificationOption(
              title: 'Memory Invites',
              description: 'Get notified when someone invites you to a memory',
              isEnabled:
              pushEnabled ? (state.memoryInvitesEnabled ?? true) : false,
              onChanged: pushEnabled
                  ? (value) => ref
                  .read(notificationSettingsNotifier.notifier)
                  .updateMemoryInvites(value)
                  : (value) {},
            ),
            CustomNotificationOption(
              title: 'Memory Activity',
              description:
              'Get notified when someone posts to a memory you\'re in',
              isEnabled:
              pushEnabled ? (state.memoryActivityEnabled ?? true) : false,
              onChanged: pushEnabled
                  ? (value) => ref
                  .read(notificationSettingsNotifier.notifier)
                  .updateMemoryActivity(value)
                  : (value) {},
            ),
            CustomNotificationOption(
              title: 'Memory Sealed',
              description: 'Get notified when a memory you\'re part of closes',
              isEnabled:
              pushEnabled ? (state.memorySealedEnabled ?? true) : false,
              onChanged: pushEnabled
                  ? (value) => ref
                  .read(notificationSettingsNotifier.notifier)
                  .updateMemorySealed(value)
                  : (value) {},
            ),
            CustomNotificationOption(
              title: 'Reactions',
              description: 'Get notified when someone reacts to your story',
              isEnabled: pushEnabled ? (state.reactionsEnabled ?? true) : false,
              onChanged: pushEnabled
                  ? (value) => ref
                  .read(notificationSettingsNotifier.notifier)
                  .updateReactions(value)
                  : (value) {},
            ),
            CustomNotificationOption(
              title: 'New Followers',
              description: 'Get notified when someone follows you',
              isEnabled:
              pushEnabled ? (state.newFollowersEnabled ?? true) : false,
              onChanged: pushEnabled
                  ? (value) => ref
                  .read(notificationSettingsNotifier.notifier)
                  .updateNewFollowers(value)
                  : (value) {},
            ),
            CustomNotificationOption(
              title: 'Friend Requests',
              description: 'Get notified when someone sends a friend request',
              isEnabled:
              pushEnabled ? (state.friendRequestsEnabled ?? true) : false,
              onChanged: pushEnabled
                  ? (value) => ref
                  .read(notificationSettingsNotifier.notifier)
                  .updateFriendRequests(value)
                  : (value) {},
            ),
            CustomNotificationOption(
              title: 'Group Invites',
              description: 'Get notified when invited to a group',
              isEnabled:
              pushEnabled ? (state.groupInvitesEnabled ?? true) : false,
              onChanged: pushEnabled
                  ? (value) => ref
                  .read(notificationSettingsNotifier.notifier)
                  .updateGroupInvites(value)
                  : (value) {},
            ),
          ],
          backgroundColor: appTheme.gray_900_01,
          borderRadius: 20.h,
          padding: EdgeInsets.all(24.h),
          margin: EdgeInsets.only(left: 16.h, right: 24.h),
        );
      },
    );
  }

  /// Section Widget - Account Settings
  /// Section Widget - Account Settings
  Widget _buildAccountSettings(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final userMenuState = ref.watch(userMenuNotifier);
        final userProfile = userMenuState.userMenuModel;

        // Format creation date
        final createdAt = userProfile?.createdAt;
        final formattedDate = createdAt != null
            ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
            : 'N/A';

        // ✅ Email comes from Supabase Auth user (not UserMenuModel)
        final userEmail =
            Supabase.instance.client.auth.currentUser?.email ?? 'Unknown email';

        final providerLabel =
        _getAccountTypeLabel(userProfile?.authProvider ?? 'email');

        return CustomAccountSettings(
          headerIcon: ImageConstant.imgIcon2,
          headerTitle: 'Account',
          accountOptions: [
            CustomAccountOption(
              title: 'Linked Accounts',
              // ✅ keep provider label + created date on the left
              subtitle: '$providerLabel • Created $formattedDate',
              // ✅ show the email on the right
              trailingText: userEmail,
              onTap: () {
                // Read-only informational row
              },
            ),
            // ✅ Change Email removed (per your request)

            CustomAccountOption(
              title: 'Reset Password',
              onTap: () => _showResetPasswordWarning(context),
            ),
            CustomAccountOption(
              title: 'Delete Account',
              isDanger: true,
              onTap: () => _showDeleteAccountWarning(context),
            ),
          ],
        );
      },
    );
  }

  /// Get account type label with appropriate icon/badge
  String _getAccountTypeLabel(String authProvider) {
    switch (authProvider.toLowerCase()) {
      case 'google':
        return '🔵 Google Account';
      case 'facebook':
        return '📘 Facebook Account';
      case 'email':
      default:
        return '📧 Email Account';
    }
  }

  /// Section Widget - Blocked Users
  Widget _buildBlockedUsersSettings(BuildContext context) {
    final blockedUserItems = _blockedUsers.map((user) {
      return BlockedUserItem(
        username: user['display_name'] ?? user['username'] ?? 'Unknown',
        avatarUrl: user['avatar_url'] ?? '',
        onUnblock: () => _showUnblockUserWarning(
          context,
          user['user_id'] as String,
          user['display_name'] ?? user['username'] ?? 'this user',
        ),
      );
    }).toList();

    return CustomBlockedUsersSettings(
      headerIcon: ImageConstant.imgIcon3,
      headerTitle: 'Blocked Users',
      blockedUsers: _isLoadingBlockedUsers ? null : blockedUserItems,
    );
  }

  /// Section Widget - Support Settings
  Widget _buildSupportSettings(BuildContext context) {
    return CustomSupportSettings(
      headerIcon: ImageConstant.imgIcon4,
      headerTitle: 'Support',
      supportOptions: [
        CustomSupportOption(
          title: 'Help Center',
          onTap: () => _openExternalUrl(_helpUrl),
        ),
        CustomSupportOption(
          title: 'Contact Us',
          onTap: () => _openExternalUrl(_contactUrl),
        ),
        CustomSupportOption(
          title: 'Report a Problem',
          onTap: () => NavigatorService.pushNamed(AppRoutes.appReport),
        ),
        CustomSupportOption(
          title: 'Suggest a Feature',
          onTap: () => NavigatorService.pushNamed(AppRoutes.appFeedback),
        ),
      ],
    );
  }

  /// Section Widget - About Settings
  Widget _buildAboutSettings(BuildContext context) {
    return CustomAboutSettings(
      headerIcon: ImageConstant.imgIcon5,
      headerTitle: 'About',
      appVersion: 'V1.0.01',
      aboutOptions: [
        CustomAboutOption(
          title: 'Terms of Service',
          onTap: () => _openExternalUrl(_termsUrl),
        ),
        CustomAboutOption(
          title: 'Privacy Policy',
          onTap: () => _openExternalUrl(_privacyUrl),
        ),
      ],
    );
  }

  /// Shows warning modal for deleting account
  void _showDeleteAccountWarning(BuildContext context) {
    CustomWarningModal.show(
      context: context,
      title: 'Delete Account?',
      message:
      'This action cannot be undone. All your memories, stories, and data will be permanently deleted.',
      confirmButtonText: 'Delete Account',
      icon: Icons.warning_rounded,
      onConfirm: () {
        // Handle account deletion
        // TODO: Implement account deletion logic
      },
    );
  }

  /// Shows warning modal for resetting password
  void _showResetPasswordWarning(BuildContext context) {
    CustomWarningModal.show(
      context: context,
      title: 'Reset Password?',
      message:
      'You will be logged out and receive an email with instructions to reset your password.',
      confirmButtonText: 'Reset Password',
      confirmButtonColor: appTheme.orange_600,
      icon: Icons.lock_reset_rounded,
      onConfirm: () {
        NavigatorService.pushNamed(AppRoutes.authReset);
      },
    );
  }

  /// Shows warning modal for unblocking user
  void _showUnblockUserWarning(
      BuildContext context, String userId, String username) {
    CustomWarningModal.show(
      context: context,
      title: 'Unblock User?',
      message:
      '$username will be able to see your profile and interact with you again.',
      confirmButtonText: 'Unblock',
      confirmButtonColor: appTheme.color3BD81E,
      icon: Icons.person_add_rounded,
      onConfirm: () {
        _handleUnblockUser(userId, username);
      },
    );
  }

  /// Navigates to the notifications screen when the bell icon is tapped.
  void onTapNotificationBell(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appNotifications);
  }
}