part of 'video_call_notifier.dart';

class VideoCallState extends Equatable {
  final VideoCallModel? videoCallModel;
  final bool? isAudioEnabled;
  final bool? isVideoEnabled;
  final bool? isCallActive;
  final bool? isSharing;
  final bool? showOptions;
  final int? participantCount;
  final String? lastReaction;
  final String? lastEmojiReaction;

  VideoCallState({
    this.videoCallModel,
    this.isAudioEnabled = true,
    this.isVideoEnabled = true,
    this.isCallActive = false,
    this.isSharing = false,
    this.showOptions = false,
    this.participantCount = 0,
    this.lastReaction,
    this.lastEmojiReaction,
  });

  @override
  List<Object?> get props => [
        videoCallModel,
        isAudioEnabled,
        isVideoEnabled,
        isCallActive,
        isSharing,
        showOptions,
        participantCount,
        lastReaction,
        lastEmojiReaction,
      ];

  VideoCallState copyWith({
    VideoCallModel? videoCallModel,
    bool? isAudioEnabled,
    bool? isVideoEnabled,
    bool? isCallActive,
    bool? isSharing,
    bool? showOptions,
    int? participantCount,
    String? lastReaction,
    String? lastEmojiReaction,
  }) {
    return VideoCallState(
      videoCallModel: videoCallModel ?? this.videoCallModel,
      isAudioEnabled: isAudioEnabled ?? this.isAudioEnabled,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      isCallActive: isCallActive ?? this.isCallActive,
      isSharing: isSharing ?? this.isSharing,
      showOptions: showOptions ?? this.showOptions,
      participantCount: participantCount ?? this.participantCount,
      lastReaction: lastReaction ?? this.lastReaction,
      lastEmojiReaction: lastEmojiReaction ?? this.lastEmojiReaction,
    );
  }
}
