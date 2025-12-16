import '../../../core/app_export.dart';

/// This class is used for memory items in the [memories_dashboard_screen] screen.

// ignore_for_file: must_be_immutable
class MemoryItemModel extends Equatable {
  MemoryItemModel({
    this.title,
    this.date,
    this.eventDate,
    this.eventTime,
    this.endDate,
    this.endTime,
    this.location,
    this.distance,
    this.participantAvatars,
    this.memoryThumbnails,
    this.isLive,
    this.isSealed,
  }) {
    title = title ?? "";
    date = date ?? "";
    eventDate = eventDate ?? "";
    eventTime = eventTime ?? "";
    endDate = endDate ?? "";
    endTime = endTime ?? "";
    location = location ?? "";
    distance = distance ?? "";
    participantAvatars = participantAvatars ?? [];
    memoryThumbnails = memoryThumbnails ?? [];
    isLive = isLive ?? false;
    isSealed = isSealed ?? false;
  }

  String? title;
  String? date;
  String? eventDate;
  String? eventTime;
  String? endDate;
  String? endTime;
  String? location;
  String? distance;
  List<String>? participantAvatars;
  List<String>? memoryThumbnails;
  bool? isLive;
  bool? isSealed;

  MemoryItemModel copyWith({
    String? title,
    String? date,
    String? eventDate,
    String? eventTime,
    String? endDate,
    String? endTime,
    String? location,
    String? distance,
    List<String>? participantAvatars,
    List<String>? memoryThumbnails,
    bool? isLive,
    bool? isSealed,
  }) {
    return MemoryItemModel(
      title: title ?? this.title,
      date: date ?? this.date,
      eventDate: eventDate ?? this.eventDate,
      eventTime: eventTime ?? this.eventTime,
      endDate: endDate ?? this.endDate,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      distance: distance ?? this.distance,
      participantAvatars: participantAvatars ?? this.participantAvatars,
      memoryThumbnails: memoryThumbnails ?? this.memoryThumbnails,
      isLive: isLive ?? this.isLive,
      isSealed: isSealed ?? this.isSealed,
    );
  }

  @override
  List<Object?> get props => [
        title,
        date,
        eventDate,
        eventTime,
        endDate,
        endTime,
        location,
        distance,
        participantAvatars,
        memoryThumbnails,
        isLive,
        isSealed,
      ];
}
