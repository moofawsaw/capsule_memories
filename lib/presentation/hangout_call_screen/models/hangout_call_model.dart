import '../../../core/app_export.dart';

/// This class is used in the [hangout_call_screen] screen.

// ignore_for_file: must_be_immutable
class HangoutCallModel extends Equatable {
  HangoutCallModel({
    this.participants,
    this.additionalParticipants,
    this.isSpeakerOn,
    this.isCallActive,
    this.id,
  }) {
    participants = participants ??
        [
          ImageConstant.imgEllipse81,
          ImageConstant.imgFrame3,
          ImageConstant.imgFrame2,
        ];
    additionalParticipants = additionalParticipants ?? 3;
    isSpeakerOn = isSpeakerOn ?? true;
    isCallActive = isCallActive ?? true;
    id = id ?? "";
  }

  List<String>? participants;
  int? additionalParticipants;
  bool? isSpeakerOn;
  bool? isCallActive;
  String? id;

  HangoutCallModel copyWith({
    List<String>? participants,
    int? additionalParticipants,
    bool? isSpeakerOn,
    bool? isCallActive,
    String? id,
  }) {
    return HangoutCallModel(
      participants: participants ?? this.participants,
      additionalParticipants:
          additionalParticipants ?? this.additionalParticipants,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isCallActive: isCallActive ?? this.isCallActive,
      id: id ?? this.id,
    );
  }

  @override
  List<Object?> get props => [
        participants,
        additionalParticipants,
        isSpeakerOn,
        isCallActive,
        id,
      ];
}
