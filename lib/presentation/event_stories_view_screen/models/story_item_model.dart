import '../../../core/app_export.dart';

/// This class is used for the story item widget.

// ignore_for_file: must_be_immutable
class StoryItemModel extends Equatable {
  StoryItemModel({
    this.storyId,
    this.storyImage,
    this.timeAgo,
  }) {
    storyId = storyId ?? "";
    storyImage = storyImage ?? "";
    timeAgo = timeAgo ?? "";
  }

  String? storyId;
  String? storyImage;
  String? timeAgo;

  StoryItemModel copyWith({
    String? storyId,
    String? storyImage,
    String? timeAgo,
  }) {
    return StoryItemModel(
      storyId: storyId ?? this.storyId,
      storyImage: storyImage ?? this.storyImage,
      timeAgo: timeAgo ?? this.timeAgo,
    );
  }

  @override
  List<Object?> get props => [
        storyId,
        storyImage,
        timeAgo,
      ];
}
