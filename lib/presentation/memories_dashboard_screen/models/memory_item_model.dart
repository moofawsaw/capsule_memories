import 'package:equatable/equatable.dart';

class MemoryItemModel extends Equatable {
  final String? id;
  final String? title;
  final String? date;
  final String? eventDate;
  final String? eventTime;
  final String? endDate;
  final String? endTime;
  final String? location;
  final String? distance;
  final List<String>? participantAvatars;
  final List<String>? memoryThumbnails;
  final bool? isLive;
  final bool? isSealed;
  final String? state;
  final String? visibility;
  final String? categoryName;
  final String? categoryIconUrl;
  final String? creatorId;
  final String? creatorName;
  final String? creatorAvatar;
  final int? contributorCount;
  final DateTime? expiresAt;
  final DateTime? sealedAt;
  final DateTime? createdAt;

  const MemoryItemModel({
    this.id,
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
    this.isLive = false,
    this.isSealed = false,
    this.state,
    this.visibility,
    this.categoryName,
    this.categoryIconUrl,
    this.creatorId,
    this.creatorName,
    this.creatorAvatar,
    this.contributorCount,
    this.expiresAt,
    this.sealedAt,
    this.createdAt,
  });

  MemoryItemModel copyWith({
    String? id,
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
    String? state,
    String? visibility,
    String? categoryName,
    String? categoryIconUrl,
    String? creatorId,
    String? creatorName,
    String? creatorAvatar,
    int? contributorCount,
    DateTime? expiresAt,
    DateTime? sealedAt,
    DateTime? createdAt,
  }) {
    return MemoryItemModel(
      id: id ?? this.id,
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
      state: state ?? this.state,
      visibility: visibility ?? this.visibility,
      categoryName: categoryName ?? this.categoryName,
      categoryIconUrl: categoryIconUrl ?? this.categoryIconUrl,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      creatorAvatar: creatorAvatar ?? this.creatorAvatar,
      contributorCount: contributorCount ?? this.contributorCount,
      expiresAt: expiresAt ?? this.expiresAt,
      sealedAt: sealedAt ?? this.sealedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
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
        state,
        visibility,
        categoryName,
        categoryIconUrl,
        creatorId,
        creatorName,
        creatorAvatar,
        contributorCount,
        expiresAt,
        sealedAt,
        createdAt,
      ];
}
