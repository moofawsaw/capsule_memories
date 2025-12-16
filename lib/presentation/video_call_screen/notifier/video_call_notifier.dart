import '../models/video_call_model.dart';
import '../../../core/app_export.dart';

part 'video_call_state.dart';

final videoCallNotifier =
    StateNotifierProvider.autoDispose<VideoCallNotifier, VideoCallState>(
  (ref) => VideoCallNotifier(
    VideoCallState(
      videoCallModel: VideoCallModel(),
    ),
  ),
);

class VideoCallNotifier extends StateNotifier<VideoCallState> {
  VideoCallNotifier(VideoCallState state) : super(state) {
    initialize();
  }

  void initialize() {
    state = state.copyWith(
      isAudioEnabled: true,
      isVideoEnabled: true,
      isCallActive: true,
      participantCount: 3,
    );
  }

  void onReactionTap(String reaction) {
    // Handle reaction button tap
    print('Reaction tapped: $reaction');

    // Update reaction counts
    final currentModel = state.videoCallModel;
    final updatedModel = currentModel?.copyWith();

    state = state.copyWith(
      videoCallModel: updatedModel,
      lastReaction: reaction,
    );
  }

  void onEmojiTap(String emoji) {
    // Handle emoji reaction tap
    print('Emoji tapped: $emoji');

    // Update emoji counts
    final currentModel = state.videoCallModel;
    final updatedModel = currentModel?.copyWith();

    state = state.copyWith(
      videoCallModel: updatedModel,
      lastEmojiReaction: emoji,
    );
  }

  void toggleAudio() {
    state = state.copyWith(
      isAudioEnabled: !(state.isAudioEnabled ?? true),
    );
  }

  void toggleVideo() {
    state = state.copyWith(
      isVideoEnabled: !(state.isVideoEnabled ?? true),
    );
  }

  void shareCall() {
    // Handle call sharing functionality
    print('Sharing call');

    state = state.copyWith(
      isSharing: true,
    );

    // Simulate sharing process
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        state = state.copyWith(
          isSharing: false,
        );
      }
    });
  }

  void showCallOptions() {
    // Handle showing call options
    print('Showing call options');

    state = state.copyWith(
      showOptions: true,
    );
  }

  void endCall() {
    state = state.copyWith(
      isCallActive: false,
    );
  }
}
