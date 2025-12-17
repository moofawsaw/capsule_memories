import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_image_view.dart';
import 'notifier/video_call_notifier.dart';

class VideoCallScreen extends ConsumerStatefulWidget {
  VideoCallScreen({Key? key}) : super(key: key);

  @override
  VideoCallScreenState createState() => VideoCallScreenState();
}

class VideoCallScreenState extends ConsumerState<VideoCallScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray_900_02,
        body: Container(
          width: double.maxFinite,
          child: Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 8.h),
                      padding:
                          EdgeInsets.symmetric(vertical: 6.h, horizontal: 8.h),
                      child: Column(
                        spacing: 8.h,
                        children: [
                          _buildStatusLines(context),
                          _buildUserInfoSection(context),
                        ],
                      ),
                    ),
                    _buildParticipantsSection(context),
                    Spacer(),
                    _buildControlButtons(context),
                    _buildBottomActions(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildStatusLines(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        spacing: 6.h,
        children: [
          Expanded(
            child: Container(
              height: 3.h,
              margin: EdgeInsets.only(top: 2.h),
              decoration: BoxDecoration(
                color: appTheme.color3BD81E,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 3.h,
              decoration: BoxDecoration(
                color: appTheme.color3BD81E,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildUserInfoSection(BuildContext context) {
    return Row(
      spacing: 12.h,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            onTapUserProfile(context);
          },
          child: Container(
            width: 54.h,
            height: 58.h,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: CustomImageView(
                    imagePath: ImageConstant.imgEllipse852x52,
                    height: 52.h,
                    width: 52.h,
                    radius: BorderRadius.circular(26.h),
                  ),
                ),
                Container(
                  height: 24.h,
                  width: 24.h,
                  padding: EdgeInsets.all(4.h),
                  decoration: BoxDecoration(
                    color: appTheme.deep_purple_A100,
                    border: Border.all(color: appTheme.gray_900_02, width: 2),
                    borderRadius: BorderRadius.circular(12.h),
                  ),
                  child: CustomImageView(
                    imagePath: ImageConstant.imgIcon20x20,
                    height: 20.h,
                    width: 20.h,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Column(
            spacing: 2.h,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sarah Smith',
                style: TextStyleHelper.instance.title18BoldPlusJakartaSans
                    .copyWith(color: appTheme.gray_50),
              ),
              Text(
                '2 mins ago',
                style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            onTapHangoutButton(context);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 8.h),
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
          ),
        ),
      ],
    );
  }

  /// Section Widget
  Widget _buildParticipantsSection(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(top: 16.h, right: 16.h),
        padding: EdgeInsets.all(8.h),
        decoration: BoxDecoration(
          color: appTheme.gray_900_01,
          borderRadius: BorderRadius.circular(26.h),
        ),
        child: Column(
          spacing: 8.h,
          children: [
            CustomImageView(
              imagePath: ImageConstant.imgEllipse826x26,
              height: 40.h,
              width: 40.h,
            ),
            CustomImageView(
              imagePath: ImageConstant.imgEllipse8DeepOrange10001,
              height: 40.h,
              width: 40.h,
            ),
          ],
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildControlButtons(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: EdgeInsets.only(right: 16.h),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                onTapVolumeButton(context);
              },
              child: Container(
                height: 48.h,
                width: 48.h,
                padding: EdgeInsets.all(12.h),
                decoration: BoxDecoration(
                  color: appTheme.color3B8E1E,
                  borderRadius: BorderRadius.circular(24.h),
                ),
                child: CustomImageView(
                  imagePath: ImageConstant.imgButtonsVolume,
                  height: 24.h,
                  width: 24.h,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                onTapShareButton(context);
              },
              child: Container(
                height: 48.h,
                width: 48.h,
                margin: EdgeInsets.only(top: 24.h),
                padding: EdgeInsets.all(12.h),
                decoration: BoxDecoration(
                  color: appTheme.color3B8E1E,
                  borderRadius: BorderRadius.circular(24.h),
                ),
                child: CustomImageView(
                  imagePath: ImageConstant.imgShare,
                  height: 24.h,
                  width: 24.h,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                onTapOptionsButton(context);
              },
              child: Container(
                height: 48.h,
                width: 48.h,
                margin: EdgeInsets.only(top: 24.h),
                padding: EdgeInsets.all(12.h),
                decoration: BoxDecoration(
                  color: appTheme.color3B8E1E,
                  borderRadius: BorderRadius.circular(24.h),
                ),
                child: CustomImageView(
                  imagePath: ImageConstant.imgIcon6,
                  height: 24.h,
                  width: 24.h,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildBottomActions(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(6.h, 16.h, 6.h, 4.h),
      child: Column(
        spacing: 28.h,
        children: [
          _buildReactionButtons(context),
          _buildEmojiReactions(context),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildReactionButtons(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(videoCallNotifier);

        return Row(
          children: [
            GestureDetector(
              onTap: () {
                ref.read(videoCallNotifier.notifier).onReactionTap('LOL');
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 18.h, vertical: 12.h),
                decoration: BoxDecoration(
                  color: appTheme.color418724,
                  borderRadius: BorderRadius.circular(20.h),
                ),
                child: Text(
                  'LOL',
                  style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                ),
              ),
            ),
            SizedBox(width: 16.h),
            GestureDetector(
              onTap: () {
                ref.read(videoCallNotifier.notifier).onReactionTap('HOTT');
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 18.h, vertical: 12.h),
                decoration: BoxDecoration(
                  color: appTheme.color418724,
                  borderRadius: BorderRadius.circular(20.h),
                ),
                child: Text(
                  'HOTT',
                  style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                ),
              ),
            ),
            SizedBox(width: 16.h),
            GestureDetector(
              onTap: () {
                ref.read(videoCallNotifier.notifier).onReactionTap('WILD');
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 18.h, vertical: 12.h),
                decoration: BoxDecoration(
                  color: appTheme.color418724,
                  borderRadius: BorderRadius.circular(20.h),
                ),
                child: Text(
                  'WILD',
                  style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                ),
              ),
            ),
            SizedBox(width: 16.h),
            GestureDetector(
              onTap: () {
                ref.read(videoCallNotifier.notifier).onReactionTap('OMG');
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 18.h, vertical: 12.h),
                decoration: BoxDecoration(
                  color: appTheme.color418724,
                  borderRadius: BorderRadius.circular(20.h),
                ),
                child: Text(
                  'OMG',
                  style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Section Widget
  Widget _buildEmojiReactions(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(videoCallNotifier);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildEmojiItem(
                context,
                ImageConstant.imgHeart,
                '2',
                () => ref.read(videoCallNotifier.notifier).onEmojiTap('heart'),
              ),
              _buildEmojiItem(
                context,
                null,
                '2',
                () => ref
                    .read(videoCallNotifier.notifier)
                    .onEmojiTap('heart_eyes'),
                backgroundColor: appTheme.red_600,
              ),
              _buildEmojiItem(
                context,
                ImageConstant.imgLaughing,
                '2',
                () =>
                    ref.read(videoCallNotifier.notifier).onEmojiTap('laughing'),
              ),
              _buildEmojiItem(
                context,
                ImageConstant.imgThumbsup,
                '2',
                () =>
                    ref.read(videoCallNotifier.notifier).onEmojiTap('thumbsup'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmojiItem(
    BuildContext context,
    String? imagePath,
    String count,
    VoidCallback onTap, {
    Color? backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        spacing: 10.h,
        children: [
          if (imagePath != null)
            CustomImageView(
              imagePath: imagePath,
              height: 56.h,
              width: 56.h,
            )
          else
            Container(
              height: 64.h,
              width: 64.h,
              decoration: BoxDecoration(
                color: backgroundColor ?? appTheme.transparentCustom,
                borderRadius: BorderRadius.circular(32.h),
              ),
            ),
          Container(
            width: 34.h,
            padding: EdgeInsets.symmetric(vertical: 4.h),
            decoration: BoxDecoration(
              color: appTheme.gray_900_01,
              borderRadius: BorderRadius.circular(16.h),
            ),
            child: Text(
              count,
              textAlign: TextAlign.center,
              style: TextStyleHelper.instance.title18BoldPlusJakartaSans
                  .copyWith(color: appTheme.gray_50),
            ),
          ),
        ],
      ),
    );
  }

  /// Navigates to user profile screen when the user profile is tapped
  void onTapUserProfile(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.profileScreen);
  }

  /// Handles hangout button tap
  void onTapHangoutButton(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.homeScreen);
  }

  /// Handles volume/audio button tap
  void onTapVolumeButton(BuildContext context) {
    ref.read(videoCallNotifier.notifier).toggleAudio();
  }

  /// Handles share button tap
  void onTapShareButton(BuildContext context) {
    ref.read(videoCallNotifier.notifier).shareCall();
  }

  /// Handles options button tap
  void onTapOptionsButton(BuildContext context) {
    ref.read(videoCallNotifier.notifier).showCallOptions();
  }
}