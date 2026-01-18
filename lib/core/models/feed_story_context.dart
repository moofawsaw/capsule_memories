class FeedStoryContext {
  final String feedType;
  final String initialStoryId;
  final List<String> storyIds;
  final String? memoryId;  // NEW: Optional memory context

  FeedStoryContext({
    required this.feedType,
    required this.initialStoryId,
    required this.storyIds,
    this.memoryId,  // NEW: Optional parameter
  });
}