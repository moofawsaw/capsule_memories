import '../../core/app_export.dart';
import '../../widgets/custom_about_settings.dart';
import '../../widgets/custom_account_settings.dart';
import '../../widgets/custom_blocked_users_settings.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_notification_settings.dart';
import '../../widgets/custom_privacy_settings.dart';
import '../../widgets/custom_support_settings.dart';
import '../../widgets/custom_warning_modal.dart';
import 'notifier/notification_settings_notifier.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  NotificationSettingsScreenState createState() =>
      NotificationSettingsScreenState();
}

class NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray_900_02,
        body: SingleChildScrollView(
          child: Container(
            width: double.maxFinite,
            padding: EdgeInsets.symmetric(vertical: 26.h),
            child: Column(
              spacing: 30.h,
              children: [
                _buildSettingsHeader(context),
                _buildNotificationSettings(context),
                _buildPrivacySettings(context),
                _buildAccountSettings(context),
                _buildBlockedUsersSettings(context),
                _buildSupportSettings(context),
                _buildAboutSettings(context),
              ],
            ),
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

  /// Section Widget - Privacy Settings
  Widget _buildPrivacySettings(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(notificationSettingsNotifier);

        return CustomPrivacySettings(
          headerIcon: ImageConstant.imgIcon,
          headerTitle: 'Privacy',
          privacyOptions: [
            CustomPrivacyOption(
              title: 'Private Account',
              isEnabled: state.privateAccountEnabled ?? false,
              onChanged: (value) {
                ref
                    .read(notificationSettingsNotifier.notifier)
                    .updatePrivateAccount(value);
              },
            ),
            CustomPrivacyOption(
              title: 'Show Location on Stories',
              isEnabled: state.showLocationEnabled ?? true,
              onChanged: (value) {
                ref
                    .read(notificationSettingsNotifier.notifier)
                    .updateShowLocation(value);
              },
            ),
            CustomPrivacyOption(
              title: 'Who Can Invite Me to Memories',
              isEnabled: state.allowMemoryInvitesEnabled ?? true,
              onChanged: (value) {
                ref
                    .read(notificationSettingsNotifier.notifier)
                    .updateAllowMemoryInvites(value);
              },
            ),
            CustomPrivacyOption(
              title: 'Allow Story Reactions',
              isEnabled: state.allowStoryReactionsEnabled ?? true,
              onChanged: (value) {
                ref
                    .read(notificationSettingsNotifier.notifier)
                    .updateAllowStoryReactions(value);
              },
            ),
            CustomPrivacyOption(
              title: 'Allow Story Sharing',
              isEnabled: state.allowStorySharingEnabled ?? true,
              onChanged: (value) {
                ref
                    .read(notificationSettingsNotifier.notifier)
                    .updateAllowStorySharing(value);
              },
            ),
          ],
        );
      },
    );
  }

  /// Section Widget - Account Settings
  Widget _buildAccountSettings(BuildContext context) {
    return CustomAccountSettings(
      headerIcon: ImageConstant.imgIcon2,
      headerTitle: 'Account',
      accountOptions: [
        CustomAccountOption(
          title: 'Linked Accounts',
          onTap: () {
            // Navigate to linked accounts screen
          },
        ),
        CustomAccountOption(
          title: 'Change Email',
          onTap: () {
            // Navigate to change email screen
          },
        ),
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
  }

  /// Section Widget - Blocked Users
  Widget _buildBlockedUsersSettings(BuildContext context) {
    return CustomBlockedUsersSettings(
      headerIcon: ImageConstant.imgIcon3,
      headerTitle: 'Blocked Users',
      blockedUsers: [
        BlockedUserItem(
          username: 'Sarah Smith',
          avatarUrl:
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
          onUnblock: () => _showUnblockUserWarning(context, 'Sarah Smith'),
        ),
      ],
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
          onTap: () {
            // Open help center
          },
        ),
        CustomSupportOption(
          title: 'Contact Us',
          onTap: () {
            // Open contact us screen
          },
        ),
        CustomSupportOption(
          title: 'Report a Problem',
          onTap: () {
            NavigatorService.pushNamed(AppRoutes.appReport);
          },
        ),
        CustomSupportOption(
          title: 'Suggest a Feature',
          onTap: () {
            NavigatorService.pushNamed(AppRoutes.appFeedback);
          },
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
          onTap: () {
            // Open terms of service
          },
        ),
        CustomAboutOption(
          title: 'Privacy Policy',
          onTap: () {
            // Open privacy policy
          },
        ),
        CustomAboutOption(
          title: 'Open Source Licenses',
          onTap: () {
            // Open licenses screen
          },
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
  void _showUnblockUserWarning(BuildContext context, String username) {
    CustomWarningModal.show(
      context: context,
      title: 'Unblock User?',
      message:
          '$username will be able to see your profile and interact with you again.',
      confirmButtonText: 'Unblock',
      confirmButtonColor: appTheme.color3BD81E,
      icon: Icons.person_add_rounded,
      onConfirm: () {
        // Handle unblock user action
        // TODO: Implement unblock user logic
      },
    );
  }

  /// Navigates to the notifications screen when the bell icon is tapped.
  void onTapNotificationBell(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appNotifications);
  }
}
