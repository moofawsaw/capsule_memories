part of 'share_story_notifier.dart';

class ShareStoryState extends Equatable {
  final TextEditingController? searchController;
  final bool? isLoading;
  final bool? isDownloadComplete;
  final ShareStoryModel? shareStoryModel;

  ShareStoryState({
    this.searchController,
    this.isLoading = false,
    this.isDownloadComplete = false,
    this.shareStoryModel,
  });

  @override
  List<Object?> get props => [
        searchController,
        isLoading,
        isDownloadComplete,
        shareStoryModel,
      ];

  ShareStoryState copyWith({
    TextEditingController? searchController,
    bool? isLoading,
    bool? isDownloadComplete,
    ShareStoryModel? shareStoryModel,
  }) {
    return ShareStoryState(
      searchController: searchController ?? this.searchController,
      isLoading: isLoading ?? this.isLoading,
      isDownloadComplete: isDownloadComplete ?? this.isDownloadComplete,
      shareStoryModel: shareStoryModel ?? this.shareStoryModel,
    );
  }
}
