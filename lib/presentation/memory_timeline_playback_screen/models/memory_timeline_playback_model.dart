
class MemoryTimelinePlaybackModel {
  String? memoryId;
  String? memoryTitle;
  List<PlaybackStoryModel>? stories;
  int? totalStories;
  String? memoryDuration;

  MemoryTimelinePlaybackModel({
    this.memoryId,
    this.memoryTitle,
    this.stories,
    this.totalStories,
    this.memoryDuration,
  });

  MemoryTimelinePlaybackModel copyWith({
    String? memoryId,
    String? memoryTitle,
    List<PlaybackStoryModel>? stories,
    int? totalStories,
    String? memoryDuration,
  }) {
    return MemoryTimelinePlaybackModel(
      memoryId: memoryId ?? this.memoryId,
      memoryTitle: memoryTitle ?? this.memoryTitle,
      stories: stories ?? this.stories,
      totalStories: totalStories ?? this.totalStories,
      memoryDuration: memoryDuration ?? this.memoryDuration,
    );
  }

  factory MemoryTimelinePlaybackModel.fromJson(Map<String, dynamic> json) {
    return MemoryTimelinePlaybackModel(
      memoryId: json['memory_id'],
      memoryTitle: json['memory_title'],
      stories: json['stories'] != null
          ? (json['stories'] as List)
              .map((story) => PlaybackStoryModel.fromJson(story))
              .toList()
          : null,
      totalStories: json['total_stories'],
      memoryDuration: json['memory_duration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'memory_id': memoryId,
      'memory_title': memoryTitle,
      'stories': stories?.map((story) => story.toJson()).toList(),
      'total_stories': totalStories,
      'memory_duration': memoryDuration,
    };
  }
}

class PlaybackStoryModel {
  String? storyId;
  String? contributorId;
  String? contributorName;
  String? contributorAvatar;
  String? mediaType;
  String? imageUrl;
  String? videoUrl;
  String? thumbnailUrl;
  String? timestamp;
  DateTime? captureTimestamp;
  bool? isFavorite;
  int? reactionCount;

  PlaybackStoryModel({
    this.storyId,
    this.contributorId,
    this.contributorName,
    this.contributorAvatar,
    this.mediaType,
    this.imageUrl,
    this.videoUrl,
    this.thumbnailUrl,
    this.timestamp,
    this.captureTimestamp,
    this.isFavorite,
    this.reactionCount,
  });

  PlaybackStoryModel copyWith({
    String? storyId,
    String? contributorId,
    String? contributorName,
    String? contributorAvatar,
    String? mediaType,
    String? imageUrl,
    String? videoUrl,
    String? thumbnailUrl,
    String? timestamp,
    DateTime? captureTimestamp,
    bool? isFavorite,
    int? reactionCount,
  }) {
    return PlaybackStoryModel(
      storyId: storyId ?? this.storyId,
      contributorId: contributorId ?? this.contributorId,
      contributorName: contributorName ?? this.contributorName,
      contributorAvatar: contributorAvatar ?? this.contributorAvatar,
      mediaType: mediaType ?? this.mediaType,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      timestamp: timestamp ?? this.timestamp,
      captureTimestamp: captureTimestamp ?? this.captureTimestamp,
      isFavorite: isFavorite ?? this.isFavorite,
      reactionCount: reactionCount ?? this.reactionCount,
    );
  }

  factory PlaybackStoryModel.fromJson(Map<String, dynamic> json) {
    return PlaybackStoryModel(
      storyId: json['story_id'] ?? json['id'],
      contributorId: json['contributor_id'],
      contributorName: json['contributor_name'],
      contributorAvatar: json['contributor_avatar'],
      mediaType: json['media_type'],
      imageUrl: json['image_url'],
      videoUrl: json['video_url'],
      thumbnailUrl: json['thumbnail_url'],
      timestamp: json['timestamp'],
      captureTimestamp: json['capture_timestamp'] != null
          ? DateTime.parse(json['capture_timestamp'])
          : null,
      isFavorite: json['is_favorite'] ?? false,
      reactionCount: json['reaction_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'story_id': storyId,
      'contributor_id': contributorId,
      'contributor_name': contributorName,
      'contributor_avatar': contributorAvatar,
      'media_type': mediaType,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'timestamp': timestamp,
      'capture_timestamp': captureTimestamp?.toIso8601String(),
      'is_favorite': isFavorite,
      'reaction_count': reactionCount,
    };
  }
}
