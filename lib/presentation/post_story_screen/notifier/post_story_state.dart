part of 'post_story_notifier.dart';

class PostStoryState extends Equatable {
  final bool? isLoading;
  final bool? isShared;
  final bool? isSharing;
  final String? selectedTool;
  final String? selectedImagePath;
  final PostStoryModel? postStoryModel;

  PostStoryState({
    this.isLoading = false,
    this.isShared = false,
    this.isSharing = false,
    this.selectedTool,
    this.selectedImagePath,
    this.postStoryModel,
  });

  @override
  List<Object?> get props => [
        isLoading,
        isShared,
        isSharing,
        selectedTool,
        selectedImagePath,
        postStoryModel,
      ];

  PostStoryState copyWith({
    bool? isLoading,
    bool? isShared,
    bool? isSharing,
    String? selectedTool,
    String? selectedImagePath,
    PostStoryModel? postStoryModel,
  }) {
    return PostStoryState(
      isLoading: isLoading ?? this.isLoading,
      isShared: isShared ?? this.isShared,
      isSharing: isSharing ?? this.isSharing,
      selectedTool: selectedTool ?? this.selectedTool,
      selectedImagePath: selectedImagePath ?? this.selectedImagePath,
      postStoryModel: postStoryModel ?? this.postStoryModel,
    );
  }
}
