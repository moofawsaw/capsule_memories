import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_notification_card.dart';
import '../../widgets/custom_user_card.dart';
import '../../widgets/custom_info_row.dart';
import '../../widgets/custom_button.dart';
import 'notifier/memory_invitation_notifier.dart';

class MemoryInvitationScreen extends ConsumerStatefulWidget {
  MemoryInvitationScreen({Key? key}) : super(key: key);

  @override
  MemoryInvitationScreenState createState() => MemoryInvitationScreenState();
}

class MemoryInvitationScreenState
    extends ConsumerState<MemoryInvitationScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            backgroundColor: appTheme.gray_900_02,
            body: Container(
                width: double.maxFinite,
                child: Column(children: [
                  Expanded(
                      child: SingleChildScrollView(
                          child: Container(
                              width: double.maxFinite,
                              height: 848.h,
                              child:
                                  Stack(alignment: Alignment.center, children: [
                                Container(
                                    width: double.maxFinite,
                                    height: 562.h,
                                    margin: EdgeInsets.only(top: 286.h),
                                    decoration: BoxDecoration(
                                        color: appTheme.gray_900_02,
                                        borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(26.h),
                                            topRight: Radius.circular(26.h)))),
                                Container(
                                    width: double.maxFinite,
                                    height: 848.h,
                                    padding:
                                        EdgeInsets.symmetric(vertical: 28.h),
                                    decoration: BoxDecoration(
                                        color: appTheme.color5B0000),
                                    child: Stack(
                                        alignment: Alignment.bottomCenter,
                                        children: [
                                          Container(
                                              width: double.maxFinite,
                                              height: 96.h,
                                              margin:
                                                  EdgeInsets.only(top: 258.h),
                                              decoration: BoxDecoration(
                                                  color: appTheme.gray_900_03,
                                                  borderRadius:
                                                      BorderRadius.only(
                                                          topLeft:
                                                              Radius.circular(
                                                                  26.h),
                                                          topRight:
                                                              Radius.circular(
                                                                  26.h)))),
                                          Container(
                                              width: double.maxFinite,
                                              margin: EdgeInsets.symmetric(
                                                  horizontal: 22.h),
                                              child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                        width: 116.h,
                                                        height: 12.h,
                                                        decoration: BoxDecoration(
                                                            color: appTheme
                                                                .color3BD81E,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        6.h))),
                                                    CustomNotificationCard(
                                                        iconPath: ImageConstant
                                                            .imgFrameDeepOrangeA700,
                                                        title:
                                                            'Fmaily Xmas 2025',
                                                        description:
                                                            'You\'ve been invited to join this memory',
                                                        margin: EdgeInsets.only(
                                                            top: 32.h,
                                                            left: 60.h,
                                                            right: 60.h)),
                                                    CustomUserCard(
                                                        userName: 'Jane Doe',
                                                        profileImagePath:
                                                            ImageConstant
                                                                .imgEllipse81,
                                                        margin: EdgeInsets.only(
                                                            top: 26.h)),
                                                    _buildMemoryStats(context),
                                                    CustomButton(
                                                        text: 'Join Memory',
                                                        width: double.infinity,
                                                        leftIcon: ImageConstant
                                                            .imgIcon8,
                                                        onPressed: () =>
                                                            onTapJoinMemory(
                                                                context),
                                                        buttonStyle:
                                                            CustomButtonStyle
                                                                .fillPrimary,
                                                        buttonTextStyle:
                                                            CustomButtonTextStyle
                                                                .bodyMedium,
                                                        margin: EdgeInsets.only(
                                                            top: 38.h)),
                                                    CustomInfoRow(
                                                        iconPath: ImageConstant
                                                            .imgIconBlueGray30048x48,
                                                        text:
                                                            'You\'ll be able to add your own stories',
                                                        margin: EdgeInsets.only(
                                                            top: 20.h)),
                                                  ])),
                                        ])),
                              ])))),
                ]))));
  }

  /// Section Widget
  Widget _buildMemoryStats(BuildContext context) {
    return Container(
        width: double.maxFinite,
        margin: EdgeInsets.only(top: 38.h, left: 20.h, right: 20.h),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
              width: 72.h,
              height: 60.h,
              child: Stack(alignment: Alignment.bottomCenter, children: [
                Align(
                    alignment: Alignment.topCenter,
                    child: Text('2',
                        style: TextStyleHelper
                            .instance.headline28ExtraBoldPlusJakartaSans
                            .copyWith(height: 1.29))),
                Text('Members',
                    style: TextStyleHelper
                        .instance.title16RegularPlusJakartaSans
                        .copyWith(color: appTheme.blue_gray_300, height: 1.31)),
              ])),
          Container(
              width: 54.h,
              height: 60.h,
              child: Stack(alignment: Alignment.bottomCenter, children: [
                Align(
                    alignment: Alignment.topCenter,
                    child: Text('0',
                        style: TextStyleHelper
                            .instance.headline28ExtraBoldPlusJakartaSans
                            .copyWith(height: 1.29))),
                Text('Stories',
                    style: TextStyleHelper
                        .instance.title16RegularPlusJakartaSans
                        .copyWith(color: appTheme.blue_gray_300, height: 1.31)),
              ])),
          Container(
              width: 78.h,
              margin: EdgeInsets.only(top: 2.h),
              child: Column(children: [
                Text('Open',
                    style: TextStyleHelper
                        .instance.headline28ExtraBoldPlusJakartaSans
                        .copyWith(height: 1.29)),
                Text('Status',
                    style: TextStyleHelper
                        .instance.title16RegularPlusJakartaSans
                        .copyWith(color: appTheme.blue_gray_300, height: 1.31)),
              ])),
        ]));
  }

  /// Navigates to user profile when the user card is tapped
  void onTapUserProfile(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.userProfileScreen);
  }

  /// Handles joining the memory invitation
  void onTapJoinMemory(BuildContext context) {
    final notifier = ref.read(memoryInvitationNotifier.notifier);
    notifier.joinMemory();

    // Listen for success state and navigate
    ref.listen(memoryInvitationNotifier, (previous, current) {
      if (current.isJoined ?? false) {
        NavigatorService.pushNamed(AppRoutes.memoriesDashboardScreen);
      }
    });
  }
}
