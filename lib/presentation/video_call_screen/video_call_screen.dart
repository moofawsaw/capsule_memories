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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      ref.read(videoCallProvider.notifier).initializeWithStoryData(args);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 8.h),
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
    return Consumer(
      builder: (context, ref, _) {
        final model = ref.watch(videoCallProvider).videoCallModel;
        final contributorName = model?.contributorName ?? 'Unknown User';
        final contributorAvatar = model?.contributorAvatar ?? '';
        final lastSeen = model?.lastSeen ?? '';
        final memoryCategoryName = model?.memoryCategoryName ?? '';
        final memoryCategoryIcon = model?.memoryCategoryIcon ?? '';

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
                        imagePath: contributorAvatar.isNotEmpty
                            ? contributorAvatar
                            : '',
                        height: 52.h,
                        width: 52.h,
                        radius: BorderRadius.circular(26.h),
                        isCircular: true,
                      ),
                    ),
                    if (memoryCategoryIcon.isNotEmpty)
                      Container(
                        height: 24.h,
                        width: 24.h,
                        padding: EdgeInsets.all(4.h),
                        decoration: BoxDecoration(
                          color: appTheme.deep_purple_A100,
                          border:
                              Border.all(color: appTheme.gray_900_02, width: 2),
                          borderRadius: BorderRadius.circular(12.h),
                        ),
                        child: Text(
                          memoryCategoryIcon,
                          style: TextStyle(fontSize: 14.0),
                          textAlign: TextAlign.center,
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
                    contributorName,
                    style: TextStyleHelper.instance.title18BoldPlusJakartaSans
                        .copyWith(color: appTheme.gray_50),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    lastSeen,
                    style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                        .copyWith(color: appTheme.blue_gray_300),
                  ),
                ],
              ),
            ),
            if (memoryCategoryName.isNotEmpty)
              GestureDetector(
                onTap: () {
                  onTapMemoryCategory(context);
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
                      if (memoryCategoryIcon.isNotEmpty)
                        Text(
                          memoryCategoryIcon,
                          style: TextStyle(fontSize: 18.h),
                        ),
                      SizedBox(width: 4.h),
                      Text(
                        memoryCategoryName,
                        style: TextStyleHelper
                            .instance.body12BoldPlusJakartaSans
                            .copyWith(color: appTheme.gray_50),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Section Widget
  Widget _buildParticipantsSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final model = ref.watch(videoCallProvider).videoCallModel;
        final contributors = model?.contributorsList ?? [];

        if (contributors.isEmpty) {
          return SizedBox.shrink();
        }

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
              children: contributors.take(3).map((contributor) {
                final avatarUrl = contributor['avatar_url'] as String? ?? '';
                return CustomImageView(
                  imagePath: avatarUrl.isNotEmpty
                      ? avatarUrl
                      : '',
                  height: 40.h,
                  width: 40.h,
                  radius: BorderRadius.circular(20.h),
                  isCircular: true,
                );
              }).toList(),
            ),
          ),
        );
      },
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
                child: Icon(
                  Icons.volume_up,
                  size: 24.h,
                  color: appTheme.gray_50,
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
                child: Icon(
                  Icons.share,
                  size: 24.h,
                  color: appTheme.gray_50,
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
                child: Icon(
                  Icons.more_horiz,
                  size: 24.h,
                  color: appTheme.gray_50,
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
        final state = ref.watch(videoCallProvider);

        return Row(
          children: [
            GestureDetector(
              onTap: () {
                ref.read(videoCallProvider.notifier).onReactionTap('LOL');
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
                ref.read(videoCallProvider.notifier).onReactionTap('HOTT');
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
                ref.read(videoCallProvider.notifier).onReactionTap('WILD');
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
                ref.read(videoCallProvider.notifier).onReactionTap('OMG');
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
        final state = ref.watch(videoCallProvider);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildEmojiItem(
                context,
                Icons.favorite,
                '2',
                () => ref.read(videoCallProvider.notifier).onEmojiTap('heart'),
                iconColor: appTheme.red_500,
              ),
              _buildEmojiItem(
                context,
                Icons.favorite,
                '2',
                () => ref
                    .read(videoCallProvider.notifier)
                    .onEmojiTap('heart_eyes'),
                backgroundColor: appTheme.red_600,
                iconColor: appTheme.gray_50,
              ),
              _buildEmojiItem(
                context,
                Icons.sentiment_very_satisfied,
                '2',
                () =>
                    ref.read(videoCallProvider.notifier).onEmojiTap('laughing'),
                iconColor: appTheme.amber_600,
              ),
              _buildEmojiItem(
                context,
                Icons.thumb_up,
                '2',
                () =>
                    ref.read(videoCallProvider.notifier).onEmojiTap('thumbsup'),
                iconColor: appTheme.blue_A200,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmojiItem(
    BuildContext context,
    IconData? icon,
    String count,
    VoidCallback onTap, {
    Color? backgroundColor,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        spacing: 10.h,
        children: [
          Container(
            height: 64.h,
            width: 64.h,
            decoration: BoxDecoration(
              color: backgroundColor ?? appTheme.transparentCustom,
              borderRadius: BorderRadius.circular(32.h),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon ?? Icons.emoji_emotions_outlined,
              size: 34.h,
              color: iconColor ?? appTheme.gray_50,
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
    NavigatorService.pushNamed(AppRoutes.appProfile);
  }

  /// Handles memory category button tap
  void onTapMemoryCategory(BuildContext context) {
    final memoryId = ref.read(videoCallProvider).videoCallModel?.memoryId;
    if (memoryId != null && memoryId.isNotEmpty) {
      NavigatorService.pushNamed(
        AppRoutes.appBsDetails,
        arguments: {'memoryId': memoryId},
      );
    }
  }

  /// Handles volume/audio button tap
  void onTapVolumeButton(BuildContext context) {
    ref.read(videoCallProvider.notifier).toggleAudio();
  }

  /// Handles share button tap
  void onTapShareButton(BuildContext context) {
    ref.read(videoCallProvider.notifier).shareCall();
  }

  /// Handles options button tap
  void onTapOptionsButton(BuildContext context) {
    ref.read(videoCallProvider.notifier).showCallOptions();
  }
}
