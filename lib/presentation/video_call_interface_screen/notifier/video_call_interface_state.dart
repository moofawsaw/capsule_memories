part of 'video_call_interface_notifier.dart';

class VideoCallInterfaceState extends Equatable {
  final VideoCallInterfaceModel? videoCallInterfaceModel;
  final bool? isFollowingSelected;
  final String? selectedParticipantId;
  final bool? isVolumeOn;
  final bool? isScreenShared;
  final bool? isSharing;
  final String? lastReaction;

  VideoCallInterfaceState({
    this.videoCallInterfaceModel,
    this.isFollowingSelected = true,
    this.selectedParticipantId,
    this.isVolumeOn = true,
    this.isScreenShared = false,
    this.isSharing = false,
    this.lastReaction,
  });

  @override
  List<Object?> get props => [
        videoCallInterfaceModel,
        isFollowingSelected,
        selectedParticipantId,
        isVolumeOn,
        isScreenShared,
        isSharing,
        lastReaction,
      ];

  VideoCallInterfaceState copyWith({
    VideoCallInterfaceModel? videoCallInterfaceModel,
    bool? isFollowingSelected,
    String? selectedParticipantId,
    bool? isVolumeOn,
    bool? isScreenShared,
    bool? isSharing,
    String? lastReaction,
  }) {
    return VideoCallInterfaceState(
      videoCallInterfaceModel:
          videoCallInterfaceModel ?? this.videoCallInterfaceModel,
      isFollowingSelected: isFollowingSelected ?? this.isFollowingSelected,
      selectedParticipantId:
          selectedParticipantId ?? this.selectedParticipantId,
      isVolumeOn: isVolumeOn ?? this.isVolumeOn,
      isScreenShared: isScreenShared ?? this.isScreenShared,
      isSharing: isSharing ?? this.isSharing,
      lastReaction: lastReaction ?? this.lastReaction,
    );
  }
}
