import '../../../core/app_export.dart';

/// This class is used in the [PostStoryScreen] screen.

// ignore_for_file: must_be_immutable
class PostStoryModel extends Equatable {
  PostStoryModel({
    this.selectedImagePath,
    this.selectedTool,
    this.storyDestination,
    this.profileImagePath,
    this.id,
  }) {
    selectedImagePath = selectedImagePath ?? ImageConstant.imgImage8542x342;
    selectedTool = selectedTool ?? '';
    storyDestination = storyDestination ?? 'Vacation';
    profileImagePath = profileImagePath ?? ImageConstant.imgEllipse826x26;
    id = id ?? '';
  }

  String? selectedImagePath;
  String? selectedTool;
  String? storyDestination;
  String? profileImagePath;
  String? id;

  PostStoryModel copyWith({
    String? selectedImagePath,
    String? selectedTool,
    String? storyDestination,
    String? profileImagePath,
    String? id,
  }) {
    return PostStoryModel(
      selectedImagePath: selectedImagePath ?? this.selectedImagePath,
      selectedTool: selectedTool ?? this.selectedTool,
      storyDestination: storyDestination ?? this.storyDestination,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      id: id ?? this.id,
    );
  }

  @override
  List<Object?> get props => [
        selectedImagePath,
        selectedTool,
        storyDestination,
        profileImagePath,
        id,
      ];
}
