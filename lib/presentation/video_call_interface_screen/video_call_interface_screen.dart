import '../../core/app_export.dart';
import '../../widgets/custom_image_view.dart';
import './notifier/video_call_interface_notifier.dart';

class VideoCallInterfaceScreen extends ConsumerStatefulWidget {
  VideoCallInterfaceScreen({Key? key}) : super(key: key);

  @override
  VideoCallInterfaceScreenState createState() =>
      VideoCallInterfaceScreenState();
}

class VideoCallInterfaceScreenState
    extends ConsumerState<VideoCallInterfaceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(videoCallInterfaceNotifier.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: appTheme.gray_900_02,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.h)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Expanded(
              child: _buildMainContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(videoCallInterfaceNotifier);

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 16.h),
          decoration: BoxDecoration(
            color: appTheme.gray_900,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.h)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => ref
                        .read(videoCallInterfaceNotifier.notifier)
                        .toggleFollowing(true),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: (state.isFollowingSelected ?? true)
                            ? Color(0xFF52D1C6)
                            : appTheme.transparentCustom,
                        borderRadius: BorderRadius.circular(20.h),
                      ),
                      child: Text(
                        'following',
                        style: TextStyleHelper.instance.body14SemiBold,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.h),
                  GestureDetector(
                    onTap: () => ref
                        .read(videoCallInterfaceNotifier.notifier)
                        .toggleFollowing(false),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: !(state.isFollowingSelected ?? true)
                            ? Color(0xFF52D1C6)
                            : appTheme.transparentCustom,
                        borderRadius: BorderRadius.circular(20.h),
                      ),
                      child: Text(
                        'everyone',
                        style: TextStyleHelper.instance.body14SemiBold,
                      ),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.all(8.h),
                  child: Icon(
                    Icons.close,
                    size: 24.h,
                    color: appTheme.gray_50,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    return Container(
      padding: EdgeInsets.all(16.h),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 200.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildUserInfoSection(),
              SizedBox(height: 16.h),
              _buildParticipantsColumn(),
              SizedBox(height: 24.h),
              _buildControlButtons(),
              SizedBox(height: 16.h),
              _buildReactionSection(),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(videoCallInterfaceNotifier);

        return Row(
          children: [
            GestureDetector(
              onTap: () => onTapUserProfile(),
              child: Stack(
                children: [
                  CustomImageView(
                    imagePath:
                        state.videoCallInterfaceModel?.userProfileImage ??
                            '',
                    height: 52.h,
                    width: 52.h,
                    radius: BorderRadius.circular(26.h),
                    isCircular: true,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      height: 24.h,
                      width: 24.h,
                      decoration: BoxDecoration(
                        color: appTheme.deep_purple_A100,
                        borderRadius: BorderRadius.circular(12.h),
                        border:
                            Border.all(color: appTheme.gray_900_02, width: 2.h),
                      ),
                      child: CustomImageView(
                        imagePath: '',
                        height: 12.h,
                        width: 12.h,
                        placeholderWidget: Icon(
                          Icons.person,
                          size: 12.h,
                          color: appTheme.gray_50,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.h),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.videoCallInterfaceModel?.userName ?? 'Sarah Smith',
                    style: TextStyleHelper.instance.title18Bold,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    state.videoCallInterfaceModel?.timestamp ?? '2 mins ago',
                    style: TextStyleHelper.instance.body14Regular,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => onTapHangoutButton(),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 8.h),
                decoration: BoxDecoration(
                  color: appTheme.gray_900_02,
                  borderRadius: BorderRadius.circular(18.h),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emoji_emotions_outlined,
                      size: 16.h,
                      color: appTheme.gray_50,
                    ),
                    SizedBox(width: 4.h),
                    Text(
                      'Hangout',
                      style: TextStyleHelper.instance.body12Bold,
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

  Widget _buildParticipantsColumn() {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(videoCallInterfaceNotifier);
        final participants = state.videoCallInterfaceModel?.participants ?? [];

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 6.h, vertical: 8.h),
          decoration: BoxDecoration(
            color: appTheme.gray_900_01,
            borderRadius: BorderRadius.circular(26.h),
          ),
          child: Column(
            children: participants.map((participant) {
              return Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: GestureDetector(
                  onTap: () => onTapParticipant(participant.id ?? ''),
                  child: CustomImageView(
                    imagePath: participant.profileImage ?? '',
                    height: 40.h,
                    width: 40.h,
                    isCircular: true,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildControlButtons() {
    return Column(
      children: [
        CustomIconButton(
          icon: Icons.volume_up,
          backgroundColor: appTheme.color3B8E1E,
          iconColor: appTheme.gray_50,
          onTap: () => onTapVolumeButton(),
        ),
        SizedBox(height: 24.h),
        CustomIconButton(
          icon: Icons.share,
          backgroundColor: appTheme.color3B8E1E,
          iconColor: appTheme.gray_50,
          onTap: () => onTapShareButton(),
        ),
        SizedBox(height: 24.h),
        CustomIconButton(
          icon: Icons.screen_share,
          backgroundColor: appTheme.color3B8E1E,
          iconColor: appTheme.gray_50,
          onTap: () => onTapScreenButton(),
        ),
      ],
    );
  }

  Widget _buildReactionSection() {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(videoCallInterfaceNotifier);

        return Column(
          children: [
            _buildReactionChips(state),
            SizedBox(height: 28.h),
            _buildReactionCounters(state),
          ],
        );
      },
    );
  }

  Widget _buildReactionChips(VideoCallInterfaceState state) {
    final reactionChips = state.videoCallInterfaceModel?.reactionChips ?? [];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: reactionChips.map((chip) {
        return GestureDetector(
          onTap: () => onTapReactionChip(chip.label ?? ''),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 18.h, vertical: 12.h),
            decoration: BoxDecoration(
              color: appTheme.color418724,
              borderRadius: BorderRadius.circular(20.h),
            ),
            child: Text(
              chip.label ?? '',
              style: TextStyleHelper.instance.body14Bold,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReactionCounters(VideoCallInterfaceState state) {
    final reactionCounters =
        state.videoCallInterfaceModel?.reactionCounters ?? [];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: reactionCounters.map((counter) {
        return GestureDetector(
          onTap: () => onTapReactionCounter(counter.type ?? ''),
          child: Column(
            children: [
              counter.isCustomView ?? false
                  ? Container(
                      height: 64.h,
                      width: 64.h,
                      decoration: BoxDecoration(
                        color: appTheme.red_600,
                        borderRadius: BorderRadius.circular(32.h),
                      ),
                    )
                  : Container(
                      height: 64.h,
                      width: 64.h,
                      decoration: BoxDecoration(
                        color: appTheme.gray_900_01,
                        borderRadius: BorderRadius.circular(32.h),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        _reactionIcon(counter.type),
                        size: 34.h,
                        color: appTheme.gray_50,
                      ),
                    ),
              SizedBox(height: 10.h),
              Container(
                width: 34.h,
                padding: EdgeInsets.symmetric(vertical: 4.h),
                decoration: BoxDecoration(
                  color: appTheme.gray_900_01,
                  borderRadius: BorderRadius.circular(16.h),
                ),
                child: Text(
                  '${counter.count ?? 0}',
                  textAlign: TextAlign.center,
                  style: TextStyleHelper.instance.title18Bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void onTapUserProfile() {
    NavigatorService.pushNamed(AppRoutes.appProfile);
  }

  void onTapHangoutButton() {
    // Handle hangout button tap
  }

  void onTapParticipant(String participantId) {
    ref
        .read(videoCallInterfaceNotifier.notifier)
        .selectParticipant(participantId);
  }

  void onTapVolumeButton() {
    ref.read(videoCallInterfaceNotifier.notifier).toggleVolume();
  }

  void onTapShareButton() {
    ref.read(videoCallInterfaceNotifier.notifier).shareCall();
  }

  void onTapScreenButton() {
    ref.read(videoCallInterfaceNotifier.notifier).toggleScreenShare();
  }

  void onTapReactionChip(String chipLabel) {
    ref.read(videoCallInterfaceNotifier.notifier).sendQuickReaction(chipLabel);
  }

  void onTapReactionCounter(String reactionType) {
    ref.read(videoCallInterfaceNotifier.notifier).addReaction(reactionType);
  }

  IconData _reactionIcon(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'heart':
        return Icons.favorite;
      case 'laugh':
        return Icons.sentiment_very_satisfied;
      case 'thumbs_up':
        return Icons.thumb_up;
      default:
        return Icons.emoji_emotions_outlined;
    }
  }
}
