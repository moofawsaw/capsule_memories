import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_fab.dart';
import 'notifier/hangout_call_notifier.dart';

class HangoutCallScreen extends ConsumerStatefulWidget {
  HangoutCallScreen({Key? key}) : super(key: key);

  @override
  HangoutCallScreenState createState() => HangoutCallScreenState();
}

class HangoutCallScreenState extends ConsumerState<HangoutCallScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray_900_02,
        body: Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(hangoutCallNotifier);

            ref.listen(
              hangoutCallNotifier,
              (previous, current) {
                if (current.shouldExitCall ?? false) {
                  NavigatorService.goBack();
                }
              },
            );

            return Container(
              width: double.maxFinite,
              height: double.maxFinite,
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Container(
                            width: double.maxFinite,
                            height: 848.h,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                _buildMainCallArea(context),
                                _buildBottomRightControl(context),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  _buildBottomLeftControl(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildMainCallArea(BuildContext context) {
    return Container(
      width: double.maxFinite,
      height: double.maxFinite,
      padding: EdgeInsets.fromLTRB(20.h, 28.h, 20.h, 28.h),
      decoration: BoxDecoration(
        color: appTheme.gray_900_02,
      ),
      child: Column(
        children: [
          _buildTopSection(context),
          Spacer(),
          _buildCenterVideoPlaceholder(context),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildTopSection(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              margin: EdgeInsets.only(top: 6.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHangoutButton(context),
                  SizedBox(height: 16.h),
                  _buildParticipantsSection(context),
                ],
              ),
            ),
          ),
          _buildCloseButton(context),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildHangoutButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(8.h, 8.h, 8.h, 8.h),
      decoration: BoxDecoration(
        color: appTheme.gray_900_02,
        borderRadius: BorderRadius.circular(18.h),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomImageView(
            imagePath: ImageConstant.imgEmojiMemorycategory,
            height: 24.h,
            width: 24.h,
          ),
          SizedBox(width: 4.h),
          Text(
            'Hangout',
            style: TextStyleHelper.instance.body12BoldPlusJakartaSans
                .copyWith(color: appTheme.gray_50),
          ),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildParticipantsSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(hangoutCallNotifier);
        final participants = state.hangoutCallModel?.participants ?? [];

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12.h),
          decoration: BoxDecoration(
            color: appTheme.gray_900_01,
            borderRadius: BorderRadius.circular(28.h),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 58.h,
                child: Stack(
                  children: [
                    if (participants.isNotEmpty)
                      Positioned(
                        left: 0,
                        child: CustomImageView(
                          imagePath: participants.length > 0
                              ? participants[0]
                              : ImageConstant.imgEllipse81,
                          height: 40.h,
                          width: 40.h,
                          radius: BorderRadius.circular(20.h),
                        ),
                      ),
                    if (participants.length > 1)
                      Positioned(
                        left: 31.h,
                        child: CustomImageView(
                          imagePath: participants.length > 1
                              ? participants[1]
                              : ImageConstant.imgFrame3,
                          height: 40.h,
                          width: 40.h,
                          radius: BorderRadius.circular(20.h),
                        ),
                      ),
                    if (participants.length > 2)
                      Positioned(
                        left: 62.h,
                        child: CustomImageView(
                          imagePath: participants.length > 2
                              ? participants[2]
                              : ImageConstant.imgFrame2,
                          height: 40.h,
                          width: 40.h,
                          radius: BorderRadius.circular(20.h),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: 21.h),
              if ((state.hangoutCallModel?.additionalParticipants ?? 0) > 0)
                Container(
                  width: 38.h,
                  height: 36.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: appTheme.gray_900_02,
                    borderRadius: BorderRadius.circular(18.h),
                  ),
                  child: Text(
                    '+${state.hangoutCallModel?.additionalParticipants ?? 3}',
                    style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                        .copyWith(color: appTheme.blue_gray_300),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Section Widget
  Widget _buildCloseButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTapCloseButton(context);
      },
      child: CustomImageView(
        imagePath: ImageConstant.imgFrame19,
        height: 40.h,
        width: 40.h,
      ),
    );
  }

  /// Section Widget
  Widget _buildCenterVideoPlaceholder(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 18.h),
      child: Container(
        height: 124.h,
        width: 124.h,
        decoration: BoxDecoration(
          color: appTheme.blue_gray_100,
          border: Border.all(
            color: appTheme.gray_400,
            width: 9.h,
          ),
          borderRadius: BorderRadius.circular(62.h),
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildBottomRightControl(BuildContext context) {
    return CustomFab(
      iconPath: ImageConstant.imgButtonsGray5064x64,
      alignment: Alignment.bottomRight,
      backgroundColor: appTheme.color418724,
      size: 64.h,
      margin: EdgeInsets.only(right: 28.h, bottom: 46.h),
      onTap: () {
        onTapMenuButton(context);
      },
    );
  }

  /// Section Widget
  Widget _buildBottomLeftControl(BuildContext context) {
    return CustomFab(
      iconPath: ImageConstant.imgButtonsVolume,
      alignment: Alignment.bottomLeft,
      backgroundColor: appTheme.color418724,
      size: 64.h,
      margin: EdgeInsets.only(left: 28.h, bottom: 46.h),
      onTap: () {
        onTapSpeakerButton(context);
      },
    );
  }

  /// Handles close button tap to exit the call
  void onTapCloseButton(BuildContext context) {
    ref.read(hangoutCallNotifier.notifier).exitCall();
  }

  /// Handles speaker/audio button tap
  void onTapSpeakerButton(BuildContext context) {
    ref.read(hangoutCallNotifier.notifier).toggleSpeaker();
  }

  /// Handles menu/options button tap
  void onTapMenuButton(BuildContext context) {
    ref.read(hangoutCallNotifier.notifier).openMenu();
  }
}
