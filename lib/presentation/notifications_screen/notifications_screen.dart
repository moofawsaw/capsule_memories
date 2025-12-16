import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_notification_card.dart';
import '../../widgets/custom_notification_item.dart';
import 'notifier/notifications_notifier.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  NotificationsScreen({Key? key}) : super(key: key);

  @override
  NotificationsScreenState createState() => NotificationsScreenState();
}

class NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsNotifier.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            backgroundColor: appTheme.gray_900_02,
            appBar: CustomAppBar(
                logoImagePath: ImageConstant.imgLogo,
                showIconButton: true,
                iconButtonImagePath: ImageConstant.imgFrame19,
                iconButtonBackgroundColor: appTheme.color3BD81E,
                onIconButtonTap: () => _onIconButtonTap(),
                actionIcons: [
                  ImageConstant.imgIconGray50,
                  ImageConstant.imgIconDeepPurpleA10032x32
                ],
                showProfileImage: true,
                profileImagePath: ImageConstant.imgEllipse8,
                isProfileCircular: true,
                onProfileTap: () => _onProfileTap(),
                showBottomBorder: true),
            body: Container(
                width: double.maxFinite,
                child: Column(children: [
                  SizedBox(height: 26.h),
                  Expanded(
                      child: Container(
                          margin: EdgeInsets.fromLTRB(16.h, 0, 20.h, 62.h),
                          child: Column(spacing: 32.h, children: [
                            _buildNotificationsHeader(context),
                            _buildNotificationsList(context)
                          ]))),
                ]))));
  }

  /// Section Widget
  Widget _buildNotificationsHeader(BuildContext context) {
    return Container(
        margin: EdgeInsets.only(right: 10.h),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          CustomImageView(
              imagePath: ImageConstant.imgIconDeepPurpleA10032x32,
              height: 26.h,
              width: 26.h),
          SizedBox(width: 6.h),
          Text('Notifications',
              style: TextStyleHelper.instance.title20ExtraBoldPlusJakartaSans),
          Spacer(),
          GestureDetector(
              onTap: () => _onMarkAsReadTap(),
              child: Container(
                  margin: EdgeInsets.only(top: 4.h),
                  child: Text('mark as read',
                      style: TextStyleHelper
                          .instance.body14RegularPlusJakartaSans
                          .copyWith(color: appTheme.gray_50)))),
        ]));
  }

  /// Section Widget
  Widget _buildNotificationsList(BuildContext context) {
    return Expanded(
        child: Container(
            margin: EdgeInsets.only(left: 4.h),
            child: Consumer(builder: (context, ref, _) {
              final state = ref.watch(notificationsNotifier);

              ref.listen(notificationsNotifier, (previous, current) {
                if (current.isMarkAsReadSuccess ?? false) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('All notifications marked as read'),
                      backgroundColor: appTheme.colorFF52D1));
                }
              });

              if (state.isLoading ?? false) {
                return Center(
                    child:
                        CircularProgressIndicator(color: appTheme.colorFF52D1));
              }

              return ListView.separated(
                  padding: EdgeInsets.zero,
                  physics: BouncingScrollPhysics(),
                  shrinkWrap: true,
                  separatorBuilder: (context, index) => SizedBox(height: 8.h),
                  itemCount:
                      state.notificationsModel?.notificationsList?.length ?? 0,
                  itemBuilder: (context, index) {
                    final notification =
                        state.notificationsModel?.notificationsList?[index];

                    if (index < 2) {
                      return CustomNotificationCard(
                          title: notification?.title ??
                              'Notification', // Modified: Added null check and default value
                          description: notification?.subtitle ??
                              'Notification description', // Modified: Added required description parameter
                          iconPath: notification?.iconPath ??
                              '', // Modified: Added null check and default value

                          onIconTap: () => _onNotificationIconTap(index));
                    } else {
                      return CustomNotificationItem(
                          title: notification?.title,
                          subtitle: notification?.subtitle,
                          timestamp: notification?.timestamp,
                          iconPath: notification?.iconPath,
                          onIconTap: () => _onNotificationIconTap(index),
                          margin: EdgeInsets.symmetric(horizontal: 20.h));
                    }
                  });
            })));
  }

  /// Handles icon button tap in app bar
  void _onIconButtonTap() {
    // Handle add/plus button tap
  }

  /// Navigates to profile screen
  void _onProfileTap() {
    NavigatorService.pushNamed(AppRoutes.userProfileScreen);
  }

  /// Handles mark as read functionality
  void _onMarkAsReadTap() {
    ref.read(notificationsNotifier.notifier).markAllAsRead();
  }

  /// Handles notification icon tap
  void _onNotificationIconTap(int index) {
    ref.read(notificationsNotifier.notifier).handleNotificationTap(index);
  }
}
