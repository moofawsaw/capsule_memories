import '../../../core/app_export.dart';

/// This class is used in the [VideoCallScreen] screen.

// ignore_for_file: must_be_immutable
class VideoCallModel extends Equatable {
  VideoCallModel({
    this.storyId,
    this.memoryId,
    this.memoryTitle,
    this.memoryCategoryName,
    this.memoryCategoryIcon,
    this.contributorName,
    this.contributorAvatar,
    this.contributorsList,
    this.lastSeen,
    this.reactionCounts,
    this.emojiCounts,
  }) {
    storyId = storyId ?? "";
    memoryId = memoryId ?? "";
    memoryTitle = memoryTitle ?? "";
    memoryCategoryName = memoryCategoryName ?? "";
    memoryCategoryIcon = memoryCategoryIcon ?? "";
    contributorName = contributorName ?? "";
    contributorAvatar = contributorAvatar ?? "";
    contributorsList = contributorsList ?? [];
    lastSeen = lastSeen ?? "";
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
  }

  String? storyId;
  String? memoryId;
  String? memoryTitle;
  String? memoryCategoryName;
  String? memoryCategoryIcon;
  String? contributorName;
  String? contributorAvatar;
  List<Map<String, dynamic>>? contributorsList;
  String? lastSeen;
  Map<String, int>? reactionCounts;
  Map<String, int>? emojiCounts;

  VideoCallModel copyWith({
    String? storyId,
    String? memoryId,
    String? memoryTitle,
    String? memoryCategoryName,
    String? memoryCategoryIcon,
    String? contributorName,
    String? contributorAvatar,
    List<Map<String, dynamic>>? contributorsList,
    String? lastSeen,
    Map<String, int>? reactionCounts,
    Map<String, int>? emojiCounts,
  }) {
    return VideoCallModel(
      storyId: storyId ?? this.storyId,
      memoryId: memoryId ?? this.memoryId,
      memoryTitle: memoryTitle ?? this.memoryTitle,
      memoryCategoryName: memoryCategoryName ?? this.memoryCategoryName,
      memoryCategoryIcon: memoryCategoryIcon ?? this.memoryCategoryIcon,
      contributorName: contributorName ?? this.contributorName,
      contributorAvatar: contributorAvatar ?? this.contributorAvatar,
      contributorsList: contributorsList ?? this.contributorsList,
      lastSeen: lastSeen ?? this.lastSeen,
      reactionCounts: reactionCounts ?? this.reactionCounts,
      emojiCounts: emojiCounts ?? this.emojiCounts,
    );
  }

  @override
  List<Object?> get props => [
        storyId,
        memoryId,
        memoryTitle,
        memoryCategoryName,
        memoryCategoryIcon,
        contributorName,
        contributorAvatar,
        contributorsList,
        lastSeen,
        reactionCounts,
        emojiCounts,
      ];
}
