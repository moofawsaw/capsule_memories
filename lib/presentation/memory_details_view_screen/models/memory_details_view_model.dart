import '../../../core/app_export.dart';
import '../../../widgets/custom_story_list.dart';
import './timeline_detail_model.dart';

class MemoryDetailsViewModel extends Equatable {
  final String? memoryId;
  final String? eventTitle;
  final String? eventDate;
  final bool? isPrivate;
  final String? categoryIcon;
  final List<String>? participantImages;
  final List<CustomStoryItem>? customStoryItems;
  final TimelineDetailModel? timelineDetail;
  final bool? isMemorySealed;
  final String? sealedDate;
  final int? storiesCount;

  MemoryDetailsViewModel({
    this.memoryId,
    this.eventTitle,
    this.eventDate,
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
