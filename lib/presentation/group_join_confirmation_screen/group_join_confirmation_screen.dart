import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_user_card.dart';
import '../../widgets/custom_user_profile_item.dart';
import '../../widgets/custom_header_row.dart';
import '../../widgets/custom_notification_card.dart';
import '../../widgets/custom_button.dart';
import 'notifier/group_join_confirmation_notifier.dart';
// Modified: Removed non-existent import 'widgets/member_list_item_widget.dart'

class GroupJoinConfirmationScreen extends ConsumerStatefulWidget {
  GroupJoinConfirmationScreen({Key? key}) : super(key: key);

  @override
  GroupJoinConfirmationScreenState createState() =>
      GroupJoinConfirmationScreenState();
}

class GroupJoinConfirmationScreenState
    extends ConsumerState<GroupJoinConfirmationScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            backgroundColor: appTheme.black_900,
            body: Container(
                width: double.maxFinite,
                child: SingleChildScrollView(
                    child: Container(
                        width: double.infinity,
                        height: 848.h,
                        child: Stack(alignment: Alignment.center, children: [
                          Container(
                              width: 356.h,
                              height: 756.h,
                              margin: EdgeInsets.only(top: 47.h),
                              decoration: BoxDecoration(
                                  color: appTheme.gray_900_02,
                                  borderRadius: BorderRadius.circular(30.h))),
                          Container(
                              width: double.infinity,
                              height: double.infinity,
                              padding: EdgeInsets.all(40.h),
                              decoration:
                                  BoxDecoration(color: appTheme.color5B0000),
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildHeaderSection(context),
                                    SizedBox(height: 38.h),
                                    _buildNotificationCard(context),
                                    SizedBox(height: 14.h),
                                    _buildMembersSection(context),
                                    SizedBox(height: 12.h),
                                    _buildMembersList(context),
                                    SizedBox(height: 20.h),
                                    _buildInfoText(context),
                                    SizedBox(height: 90.h),
                                    _buildActionButtons(context),
                                  ])),
                        ]))))));
  }

  /// Section Widget
  Widget _buildHeaderSection(BuildContext context) {
    return CustomHeaderRow(
        title: "You're in!",
        textAlignment: TextAlign.left,
        margin: EdgeInsets.symmetric(horizontal: 12.h, vertical: 18.h),
        onIconTap: () {
          onTapCloseButton(context);
        });
  }

  /// Section Widget
  Widget _buildNotificationCard(BuildContext context) {
    return CustomNotificationCard(
        iconPath: ImageConstant.imgFrameDeepOrangeA700,
        title: 'Fmaily Xmas 2025',
        description: 'You have successfully joined Family Xmas 2025',
        margin: EdgeInsets.symmetric(horizontal: 46.h),
        onIconTap: () {});
  }

  /// Section Widget
  Widget _buildMembersSection(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 0.h),
        child: Row(children: [
          CustomImageView(
              imagePath: ImageConstant.imgIconBlueGray30018x18,
              height: 18.h,
              width: 18.h),
          SizedBox(width: 6.h),
          Text('Members',
              style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                  .copyWith(color: appTheme.blue_gray_300)),
        ]));
  }

  /// Section Widget
  Widget _buildMembersList(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(groupJoinConfirmationNotifier);

      return Column(spacing: 6.h, children: [
        CustomUserCard(
            userName: 'Ki Jones',
            profileImagePath: ImageConstant.imgEllipse826x26),
        CustomUserProfileItem(
            profileImagePath: ImageConstant.imgFrame2,
            userName: 'Dillon Brooks',
            onTap: () {
              onTapUserProfile(context);
            }),
        CustomUserProfileItem(
            profileImagePath: ImageConstant.imgFrame48x48,
            userName: 'Leslie Thomas',
            onTap: () {
              onTapUserProfile(context);
            }),
        CustomUserProfileItem(
            profileImagePath: ImageConstant.imgFrame1,
            userName: 'Kalvin Smith',
            onTap: () {
              onTapUserProfile(context);
            }),
      ]);
    });
  }

  /// Section Widget
  Widget _buildInfoText(BuildContext context) {
    return Align(
        alignment: Alignment.centerLeft,
        child: Container(
            margin: EdgeInsets.only(left: 12.h),
            child: Text(
                'You can now start posting to the memory timeline. This memory has 12 hours remaining',
                style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300, height: 1.21))));
  }

  /// Section Widget
  Widget _buildActionButtons(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(groupJoinConfirmationNotifier);

      ref.listen(groupJoinConfirmationNotifier, (previous, current) {
        if (current.shouldNavigateToCreateMemory ?? false) {
          NavigatorService.pushNamed(AppRoutes.createMemoryScreen);
        }
        if (current.shouldClose ?? false) {
          NavigatorService.pushNamed(AppRoutes.createMemoryScreen);
        }
      });

      return Row(spacing: 12.h, children: [
        Expanded(
            child: CustomButton(
                text: 'Close',
                buttonStyle: CustomButtonStyle.fillDark,
                buttonTextStyle: CustomButtonTextStyle.bodyMediumGray,
                onPressed: () {
                  onTapCloseButton(context);
                })),
        Expanded(
            child: CustomButton(
                text: 'Create Story',
                buttonStyle: CustomButtonStyle.fillPrimary,
                buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                onPressed: () {
                  onTapCreateStory(context);
                })),
      ]);
    });
  }

  /// Navigates to the user profile screen
  void onTapUserProfile(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.userProfileScreen);
  }

  /// Handles close button tap
  void onTapCloseButton(BuildContext context) {
    ref.read(groupJoinConfirmationNotifier.notifier).onClosePressed();
  }

  /// Handles create story button tap
  void onTapCreateStory(BuildContext context) {
    ref.read(groupJoinConfirmationNotifier.notifier).onCreateStoryPressed();
  }
}
