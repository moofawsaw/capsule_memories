import '../../../core/app_export.dart';
import '../../../widgets/custom_story_list.dart'; // ✅ for CustomStoryItem
import './timeline_detail_model.dart';

class MemoryDetailsViewModel extends Equatable {
  final String? memoryId;
  final String? eventTitle;
  final String? eventDate;
  final String? eventLocation;
  final bool? isPrivate;
  final String? categoryIcon;
  final List<String>? participantImages;

  // ✅ FIX: feed list items must be CustomStoryItem (used by CustomStoryList)
  final List<CustomStoryItem>? customStoryItems;

  final TimelineDetailModel? timelineDetail;
  final bool? isMemorySealed;
  final String? sealedDate;
  final int? storiesCount;

  const MemoryDetailsViewModel({
    this.memoryId,
    this.eventTitle,
    this.eventDate,
    this.eventLocation,
    this.isPrivate,
    this.categoryIcon,
    this.participantImages,
    this.customStoryItems,
    this.timelineDetail,
    this.isMemorySealed,
    this.sealedDate,
    this.storiesCount,
  });

  MemoryDetailsViewModel copyWith({
    String? memoryId,
    String? eventTitle,
    String? eventDate,
    String? eventLocation,
    bool? isPrivate,
    String? categoryIcon,
    List<String>? participantImages,
    List<CustomStoryItem>? customStoryItems,
    TimelineDetailModel? timelineDetail,
    bool? isMemorySealed,
    String? sealedDate,
    int? storiesCount,
  }) {
    return MemoryDetailsViewModel(
      memoryId: memoryId ?? this.memoryId,
      eventTitle: eventTitle ?? this.eventTitle,
      eventDate: eventDate ?? this.eventDate,
      eventLocation: eventLocation ?? this.eventLocation,
      isPrivate: isPrivate ?? this.isPrivate,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      participantImages: participantImages ?? this.participantImages,
      customStoryItems: customStoryItems ?? this.customStoryItems,
      timelineDetail: timelineDetail ?? this.timelineDetail,
      isMemorySealed: isMemorySealed ?? this.isMemorySealed,
      sealedDate: sealedDate ?? this.sealedDate,
      storiesCount: storiesCount ?? this.storiesCount,
    );
  }

  @override
  List<Object?> get props => [
    memoryId,
    eventTitle,
    eventDate,
    eventLocation,
    isPrivate,
    categoryIcon,
    participantImages,
    customStoryItems,
    timelineDetail,
    isMemorySealed,
    sealedDate,
    storiesCount,
  ];
}
