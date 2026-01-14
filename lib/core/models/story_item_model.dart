import 'package:equatable/equatable.dart';

class StoryItemModel extends Equatable {
  final String? id;
  final String? backgroundImage; // thumbnail/preview
  final String? profileImage; // avatar
  final String? timestamp;
  final String? navigateTo; // route/id used by list
  final bool? isRead;

  const StoryItemModel({
    this.id,
    this.backgroundImage,
    this.profileImage,
    this.timestamp,
    this.navigateTo,
    this.isRead,
  });

  StoryItemModel copyWith({
    String? id,
    String? backgroundImage,
    String? profileImage,
    String? timestamp,
    String? navigateTo,
    bool? isRead,
  }) {
    return StoryItemModel(
      id: id ?? this.id,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      profileImage: profileImage ?? this.profileImage,
      timestamp: timestamp ?? this.timestamp,
      navigateTo: navigateTo ?? this.navigateTo,
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
    isRead,
  ];
}
