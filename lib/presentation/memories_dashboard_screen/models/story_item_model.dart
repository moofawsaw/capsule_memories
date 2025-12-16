import '../../../core/app_export.dart';

/// This class is used for story items in the [memories_dashboard_screen] screen.

// ignore_for_file: must_be_immutable
class StoryItemModel extends Equatable {
  StoryItemModel({
    this.backgroundImage,
    this.profileImage,
    this.timestamp,
    this.navigateTo,
  }) {
    backgroundImage = backgroundImage ?? "";
    profileImage = profileImage ?? "";
    timestamp = timestamp ?? "2 mins ago";
    navigateTo = navigateTo ?? "";
  }

  String? backgroundImage;
  String? profileImage;
  String? timestamp;
  String? navigateTo;

  StoryItemModel copyWith({
    String? backgroundImage,
    String? profileImage,
    String? timestamp,
    String? navigateTo,
  }) {
    return StoryItemModel(
      backgroundImage: backgroundImage ?? this.backgroundImage,
      profileImage: profileImage ?? this.profileImage,
      timestamp: timestamp ?? this.timestamp,
      navigateTo: navigateTo ?? this.navigateTo,
    );
  }

  @override
  List<Object?> get props => [
        backgroundImage,
        profileImage,
        timestamp,
        navigateTo,
      ];
}
