import '../../../core/app_export.dart';
import '../models/video_call_interface_model.dart';

part 'video_call_interface_state.dart';

final videoCallInterfaceNotifier = StateNotifierProvider.autoDispose<
    VideoCallInterfaceNotifier, VideoCallInterfaceState>(
  (ref) => VideoCallInterfaceNotifier(
    VideoCallInterfaceState(
      videoCallInterfaceModel: VideoCallInterfaceModel(),
    ),
  ),
);

class VideoCallInterfaceNotifier
    extends StateNotifier<VideoCallInterfaceState> {
  VideoCallInterfaceNotifier(VideoCallInterfaceState state) : super(state) {
    initialize();
  }

  void initialize() {
    final participants = [
      ParticipantModel(
        id: 'p1',
        profileImage: ImageConstant.imgFrame48x48,
        name: 'Alex Johnson',
      ),
      ParticipantModel(
        id: 'p2',
        profileImage: ImageConstant.imgEllipse826x26,
        name: 'Maria Garcia',
      ),
      ParticipantModel(
        id: 'p3',
        profileImage: ImageConstant.imgFrame1,
        name: 'David Chen',
      ),
    ];

    final reactionChips = [
      ReactionChipModel(label: 'LOL'),
      ReactionChipModel(label: 'HOTT'),
      ReactionChipModel(label: 'WILD'),
      ReactionChipModel(label: 'OMG'),
    ];

    final reactionCounters = [
      ReactionCounterModel(
        type: 'heart',
        iconPath: ImageConstant.imgHeart,
        count: 2,
        isCustomView: false,
      ),
      ReactionCounterModel(
        type: 'heart_eyes',
        iconPath: '',
        count: 2,
        isCustomView: true,
      ),
      ReactionCounterModel(
        type: 'laugh',
        iconPath: ImageConstant.imgLaughing,
        count: 2,
        isCustomView: false,
      ),
      ReactionCounterModel(
        type: 'thumbs_up',
        iconPath: ImageConstant.imgThumbsup,
        count: 2,
        isCustomView: false,
      ),
    ];

    state = state.copyWith(
      videoCallInterfaceModel: VideoCallInterfaceModel(
        userProfileImage: ImageConstant.imgEllipse852x52,
        userName: 'Sarah Smith',
        timestamp: '2 mins ago',
        participants: participants,
        reactionChips: reactionChips,
        reactionCounters: reactionCounters,
      ),
      isFollowingSelected: true,
      isVolumeOn: true,
      isScreenShared: false,
    );
  }

  void toggleFollowing(bool isFollowing) {
    state = state.copyWith(isFollowingSelected: isFollowing);
  }

  void selectParticipant(String participantId) {
    state = state.copyWith(selectedParticipantId: participantId);
  }

  void toggleVolume() {
    state = state.copyWith(isVolumeOn: !(state.isVolumeOn ?? true));
  }

  void shareCall() {
    // Implement share functionality
    state = state.copyWith(isSharing: true);

    // Reset sharing state after action
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        state = state.copyWith(isSharing: false);
      }
    });
  }

  void toggleScreenShare() {
    state = state.copyWith(isScreenShared: !(state.isScreenShared ?? false));
  }

  void sendQuickReaction(String chipLabel) {
    // Handle quick reaction
    final currentReactions = List<ReactionChipModel>.from(
        state.videoCallInterfaceModel?.reactionChips ?? []);

    // Add animation or feedback logic here
    state = state.copyWith(lastReaction: chipLabel);
  }

  void addReaction(String reactionType) {
    final currentCounters = List<ReactionCounterModel>.from(
        state.videoCallInterfaceModel?.reactionCounters ?? []);

    final updatedCounters = currentCounters.map((counter) {
      if (counter.type == reactionType) {
        return counter.copyWith(count: (counter.count ?? 0) + 1);
      }
      return counter;
    }).toList();

    state = state.copyWith(
      videoCallInterfaceModel: state.videoCallInterfaceModel?.copyWith(
        reactionCounters: updatedCounters,
      ),
    );
  }
}
