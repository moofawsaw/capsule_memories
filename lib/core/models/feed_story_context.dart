/// Context class for passing story data between feed and story viewer
class FeedStoryContext {
  final String feedType;
  final String initialStoryId;
  final List<String> storyIds;

  FeedStoryContext({
    required this.feedType,
    required this.initialStoryId,
    required this.storyIds,
  });
}
