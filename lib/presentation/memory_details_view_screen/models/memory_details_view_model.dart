import '../../../core/app_export.dart';

/// This class is used in the [MemoryDetailsViewScreen] screen.

// ignore_for_file: must_be_immutable
class MemoryDetailsViewModel extends Equatable {
  MemoryDetailsViewModel({
    this.memoryTitle,
    this.memoryDate,
    this.isPublic,
    this.participantImages,
    this.timelineEntries,
    this.storyItems,
    this.isMemorySealed,
    this.sealedDate,
    this.storiesCount,
    this.id,
  }) {
    memoryTitle = memoryTitle ?? "Boyz Golf Trip";
    memoryDate = memoryDate ?? "Sept 21, 2025";
    isPublic = isPublic ?? true;
    participantImages = participantImages ?? [];
    timelineEntries = timelineEntries ?? [];
    storyItems = storyItems ?? [];
    isMemorySealed = isMemorySealed ?? true;
    sealedDate = sealedDate ?? "Dec 4, 2025";
    storiesCount = storiesCount ?? 6;
    id = id ?? "";
  }

  String? memoryTitle;
  String? memoryDate;
  bool? isPublic;
  List<String>? participantImages;
  List<TimelineEntryModel>? timelineEntries;
  List<StoryItemModel>? storyItems;
  bool? isMemorySealed;
  String? sealedDate;
  int? storiesCount;
  String? id;

  MemoryDetailsViewModel copyWith({
    String? memoryTitle,
    String? memoryDate,
    bool? isPublic,
    List<String>? participantImages,
    List<TimelineEntryModel>? timelineEntries,
    List<StoryItemModel>? storyItems,
    bool? isMemorySealed,
    String? sealedDate,
    int? storiesCount,
    String? id,
  }) {
    return MemoryDetailsViewModel(
      memoryTitle: memoryTitle ?? this.memoryTitle,
      memoryDate: memoryDate ?? this.memoryDate,
      isPublic: isPublic ?? this.isPublic,
      participantImages: participantImages ?? this.participantImages,
      timelineEntries: timelineEntries ?? this.timelineEntries,
      storyItems: storyItems ?? this.storyItems,
      isMemorySealed: isMemorySealed ?? this.isMemorySealed,
      sealedDate: sealedDate ?? this.sealedDate,
      storiesCount: storiesCount ?? this.storiesCount,
      id: id ?? this.id,
    );
  }

  @override
  List<Object?> get props => [
        memoryTitle,
        memoryDate,
        isPublic,
        participantImages,
        timelineEntries,
        storyItems,
        isMemorySealed,
        sealedDate,
        storiesCount,
        id,
      ];
}

// ignore_for_file: must_be_immutable
class TimelineEntryModel extends Equatable {
  TimelineEntryModel({
    this.date,
    this.time,
    this.location,
    this.distance,
    this.id,
  }) {
    date = date ?? "";
    time = time ?? "";
    location = location ?? "";
    distance = distance ?? "";
    id = id ?? "";
  }

  String? date;
  String? time;
  String? location;
  String? distance;
  String? id;

  TimelineEntryModel copyWith({
    String? date,
    String? time,
    String? location,
    String? distance,
    String? id,
  }) {
    return TimelineEntryModel(
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
      distance: distance ?? this.distance,
      id: id ?? this.id,
    );
  }

  @override
  List<Object?> get props => [
        date,
        time,
        location,
        distance,
        id,
      ];
}

// ignore_for_file: must_be_immutable
class StoryItemModel extends Equatable {
  StoryItemModel({
    this.backgroundImage,
    this.profileImage,
    this.timestamp,
    this.navigateTo,
    this.id,
  }) {
    backgroundImage = backgroundImage ?? "";
    profileImage = profileImage ?? "";
    timestamp = timestamp ?? "";
    navigateTo = navigateTo ?? "";
    id = id ?? "";
  }

  String? backgroundImage;
  String? profileImage;
  String? timestamp;
  String? navigateTo;
  String? id;

  StoryItemModel copyWith({
    String? backgroundImage,
    String? profileImage,
    String? timestamp,
    String? navigateTo,
    String? id,
  }) {
    return StoryItemModel(
      backgroundImage: backgroundImage ?? this.backgroundImage,
      profileImage: profileImage ?? this.profileImage,
      timestamp: timestamp ?? this.timestamp,
      navigateTo: navigateTo ?? this.navigateTo,
      id: id ?? this.id,
    );
  }

  @override
  List<Object?> get props => [
        backgroundImage,
        profileImage,
        timestamp,
        navigateTo,
        id,
      ];
}
