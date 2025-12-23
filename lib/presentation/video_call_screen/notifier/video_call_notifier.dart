import '../../../core/app_export.dart';
import '../models/video_call_model.dart';

part 'video_call_state.dart';

final videoCallProvider =
    StateNotifierProvider<VideoCallNotifier, VideoCallState>((ref) {
  return VideoCallNotifier(VideoCallState());
});

/// A notifier that manages the state of the VideoCall screen
class VideoCallNotifier extends StateNotifier<VideoCallState> {
  VideoCallNotifier(VideoCallState state) : super(state);

  void initializeWithStoryData(Map<String, dynamic>? args) {
    if (args == null) return;

    final model = VideoCallModel(
      storyId: args['storyId'] as String? ?? '',
      memoryId: args['memoryId'] as String? ?? '',
      memoryTitle: args['memoryTitle'] as String? ?? '',
      memoryCategoryName: args['memoryCategoryName'] as String? ?? '',
      memoryCategoryIcon: args['memoryCategoryIcon'] as String? ?? '',
      contributorName: args['contributorName'] as String? ?? '',
      contributorAvatar: args['contributorAvatar'] as String? ?? '',
      contributorsList:
          args['contributorsList'] as List<Map<String, dynamic>>? ?? [],
      lastSeen: args['lastSeen'] as String? ?? '',
    );

    state = VideoCallState(videoCallModel: model);
  }

  void onReactionTap(String reaction) {
    final currentCounts = state.videoCallModel?.reactionCounts ?? {};
    final updatedCounts = Map<String, int>.from(currentCounts);
    updatedCounts[reaction] = (updatedCounts[reaction] ?? 0) + 1;

    state = VideoCallState(
      videoCallModel: state.videoCallModel?.copyWith(
        reactionCounts: updatedCounts,
      ),
    );
  }

  void onEmojiTap(String emoji) {
    final currentCounts = state.videoCallModel?.emojiCounts ?? {};
    final updatedCounts = Map<String, int>.from(currentCounts);
    updatedCounts[emoji] = (updatedCounts[emoji] ?? 0) + 1;

    state = VideoCallState(
      videoCallModel: state.videoCallModel?.copyWith(
        emojiCounts: updatedCounts,
      ),
    );
  }

  void toggleAudio() {
    // Audio toggle logic
  }

  void shareCall() {
    // Share call logic
  }

  void showCallOptions() {
    // Show call options logic
  }
}
