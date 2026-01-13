import '../../../core/app_export.dart';

// lib/presentation/memories_dashboard_screen/models/story_item_model.dart

class StoryItemModel extends Equatable {
  const StoryItemModel({
    this.id,
    this.backgroundImage,
    this.profileImage,
    this.timestamp,
    this.navigateTo,
    this.memoryId,
    this.memoryTitle,
    this.isRead = false,
  });

  final String? id;
  final String? backgroundImage;
  final String? profileImage;
  final String? timestamp;
  final String? navigateTo;
  final String? memoryId;
  final String? memoryTitle; // ADDED: Memory title for story viewer display
  final bool isRead;

  StoryItemModel copyWith({
    String? id,
    String? backgroundImage,
    String? profileImage,
    String? timestamp,
    String? navigateTo,
    String? memoryId,
    String? memoryTitle,
    bool? isRead,
  }) {
    return StoryItemModel(
      id: id ?? this.id,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      profileImage: profileImage ?? this.profileImage,
      timestamp: timestamp ?? this.timestamp,
      navigateTo: navigateTo ?? this.navigateTo,
      memoryId: memoryId ?? this.memoryId,
      memoryTitle: memoryTitle ?? this.memoryTitle,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object?> get props => [
        id,
        backgroundImage,
        profileImage,
        timestamp,
        navigateTo,
        memoryId,
        memoryTitle,
        isRead,
      ];
}
