import '../../../core/app_export.dart';

/// This class is used in the [VideoCallScreen] screen.

// ignore_for_file: must_be_immutable
class VideoCallModel extends Equatable {
  VideoCallModel({
    this.userName,
    this.userImage,
    this.lastSeen,
    this.participantImages,
    this.reactionCounts,
    this.emojiCounts,
    this.id,
  }) {
    userName = userName ?? "Sarah Smith";
    userImage = userImage ?? ImageConstant.imgEllipse852x52;
    lastSeen = lastSeen ?? "2 mins ago";
    participantImages = participantImages ??
        [
          ImageConstant.imgEllipse826x26,
          ImageConstant.imgEllipse8DeepOrange10001
        ];
    reactionCounts = reactionCounts ??
        {
          "LOL": 0,
          "HOTT": 0,
          "WILD": 0,
          "OMG": 0,
        };
    emojiCounts = emojiCounts ??
        {
          "heart": 2,
          "heart_eyes": 2,
          "laughing": 2,
          "thumbsup": 2,
        };
    id = id ?? "";
  }

  String? userName;
  String? userImage;
  String? lastSeen;
  List<String>? participantImages;
  Map<String, int>? reactionCounts;
  Map<String, int>? emojiCounts;
  String? id;

  VideoCallModel copyWith({
    String? userName,
    String? userImage,
    String? lastSeen,
    List<String>? participantImages,
    Map<String, int>? reactionCounts,
    Map<String, int>? emojiCounts,
    String? id,
  }) {
    return VideoCallModel(
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      lastSeen: lastSeen ?? this.lastSeen,
      participantImages: participantImages ?? this.participantImages,
      reactionCounts: reactionCounts ?? this.reactionCounts,
      emojiCounts: emojiCounts ?? this.emojiCounts,
      id: id ?? this.id,
    );
  }

  @override
  List<Object?> get props => [
        userName,
        userImage,
        lastSeen,
        participantImages,
        reactionCounts,
        emojiCounts,
        id,
      ];
}
