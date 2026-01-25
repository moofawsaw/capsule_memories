import '../../../core/app_export.dart';

/// Lightweight story model for the Following screen "Latest Stories" row.
class FollowingStoryItemModel extends Equatable {
  const FollowingStoryItemModel({
    this.id,
    this.backgroundImage,
    this.profileImage,
    this.timestamp,
    this.isRead = false,
  });

  final String? id;
  final String? backgroundImage;
  final String? profileImage;
  final String? timestamp;
  final bool isRead;

  @override
  List<Object?> get props => [
        id,
        backgroundImage,
        profileImage,
        timestamp,
        isRead,
      ];
}

