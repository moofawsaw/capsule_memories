import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_notification_settings.dart';
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
        appBar: CustomAppBar(
          layoutType: CustomAppBarLayoutType.logoWithActions,
          logoImagePath: ImageConstant.imgLogo,
          showIconButton: true,
          iconButtonImagePath: ImageConstant.imgFrame19,
          iconButtonBackgroundColor: appTheme.color3BD81E,
          actionIcons: [
            ImageConstant.imgIconGray50,
            ImageConstant.imgIconGray5032x32
          ],
          showProfileImage: true,
          profileImagePath: ImageConstant.imgEllipse8DeepOrange100,
          isProfileCircular: true,
          customHeight: 100.h,
          backgroundColor: appTheme.gray_900_02,
          showBottomBorder: true,
        ),
        body: Container(
          width: double.maxFinite,
          padding: EdgeInsets.symmetric(vertical: 26.h),
          child: Column(
            spacing: 30.h,
            children: [
              _buildSettingsHeader(context),
              Expanded(
                child: _buildNotificationSettings(context),
              ),
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

  /// Section Widget
  Widget _buildNotificationSettings(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(notificationSettingsNotifier);

        // Listen for state changes
        ref.listen(
          notificationSettingsNotifier,
          (previous, current) {
            // Handle side effects if needed
          },
        );

        return CustomNotificationSettings(
          headerIcon: ImageConstant.imgIcon1,
          headerTitle: 'Notifications',
          pushNotificationsEnabled: state.pushNotificationsEnabled ?? true,
          onPushNotificationsChanged: (value) {
            ref
                .read(notificationSettingsNotifier.notifier)
                .updatePushNotifications(value);
          },
          notificationOptions: [
            CustomNotificationOption(
              title: 'Memory Invites',
              description: 'Get notified when someone invites you to a memory',
              isEnabled: state.memoryInvitesEnabled ?? true,
              onChanged: (value) {
                ref
                    .read(notificationSettingsNotifier.notifier)
                    .updateMemoryInvites(value);
              },
            ),
            CustomNotificationOption(
              title: 'Memory Activity',
              description:
                  'Get notified when someone posts to a memory you\'re in',
              isEnabled: state.memoryActivityEnabled ?? true,
              onChanged: (value) {
                ref
                    .read(notificationSettingsNotifier.notifier)
                    .updateMemoryActivity(value);
              },
            ),
            CustomNotificationOption(
              title: 'Memory Sealed',
              description: 'Get notified when a memory you\'re part of closes',
              isEnabled: state.memorySealedEnabled ?? true,
              onChanged: (value) {
                ref
                    .read(notificationSettingsNotifier.notifier)
                    .updateMemorySealed(value);
              },
            ),
            CustomNotificationOption(
              title: 'Reactions',
              description: 'Get notified when someone reacts to your story',
              isEnabled: state.reactionsEnabled ?? true,
              onChanged: (value) {
                ref
                    .read(notificationSettingsNotifier.notifier)
                    .updateReactions(value);
              },
            ),
            CustomNotificationOption(
              title: 'New Followers',
              description: 'Get notified when someone follows you',
              isEnabled: state.newFollowersEnabled ?? true,
              onChanged: (value) {
                ref
                    .read(notificationSettingsNotifier.notifier)
                    .updateNewFollowers(value);
              },
            ),
            CustomNotificationOption(
              title: 'Friend Requests',
              description: 'Get notified when someone sends a friend request',
              isEnabled: state.friendRequestsEnabled ?? true,
              onChanged: (value) {
                ref
                    .read(notificationSettingsNotifier.notifier)
                    .updateFriendRequests(value);
              },
            ),
            CustomNotificationOption(
              title: 'Group Invites',
              description: 'Get notified when invited to a group',
              isEnabled: state.groupInvitesEnabled ?? true,
              onChanged: (value) {
                ref
                    .read(notificationSettingsNotifier.notifier)
                    .updateGroupInvites(value);
              },
            ),
          ],
          backgroundColor: appTheme.gray_900_01,
          borderRadius: 20.h,
          padding: EdgeInsets.all(24.h),
          margin: EdgeInsets.only(
              left: 16.h,
              right: 24.h), // Modified: Removed duplicate 'left' parameter
        );
      },
    );
  }

  /// Navigates to the notifications screen when the bell icon is tapped.
  void onTapNotificationBell(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.notificationsScreen);
  }
}