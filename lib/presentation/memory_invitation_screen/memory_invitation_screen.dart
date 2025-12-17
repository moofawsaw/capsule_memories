import 'package:flutter/material.dart';

import '../../core/app_export.dart';
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
    return Container(
      width: double.maxFinite,
      decoration: BoxDecoration(
        color: appTheme.gray_900_02,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.h),
          topRight: Radius.circular(20.h),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 12.h),
          // Drag handle indicator
          Container(
            width: 40.h,
            height: 4.h,
            decoration: BoxDecoration(
              color: appTheme.colorFF3A3A,
              borderRadius: BorderRadius.circular(2.h),
            ),
          ),
          SizedBox(height: 20.h),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.h),
              child: _buildContent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryInvitationNotifier);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInvitationHeader(context),
            SizedBox(height: 16.h),
            _buildInvitationDetails(context),
            SizedBox(height: 16.h),
            _buildActionButtons(context),
            SizedBox(height: 20.h),
          ],
        );
      },
    );
  }

  /// Section Widget
  Widget _buildInvitationHeader(BuildContext context) {
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

  /// Section Widget
  Widget _buildInvitationDetails(BuildContext context) {
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

  /// Section Widget
  Widget _buildActionButtons(BuildContext context) {
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
    NavigatorService.pushNamed(AppRoutes.profileScreen);
  }

  /// Handles joining the memory invitation
  void onTapJoinMemory(BuildContext context) {
    final notifier = ref.read(memoryInvitationNotifier.notifier);
    notifier.joinMemory();

    // Listen for success state and navigate
    ref.listen(memoryInvitationNotifier, (previous, current) {
      if (current.isJoined ?? false) {
        NavigatorService.pushNamed(AppRoutes.memoriesScreen);
      }
    });
  }
}
