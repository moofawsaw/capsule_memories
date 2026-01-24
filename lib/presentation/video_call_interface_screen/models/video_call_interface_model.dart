import '../../../core/app_export.dart';

/// This class is used in the [video_call_interface_screen] screen.

// ignore_for_file: must_be_immutable
class VideoCallInterfaceModel extends Equatable {
  VideoCallInterfaceModel({
    this.userProfileImage,
    this.userName,
    this.timestamp,
    this.participants,
    this.reactionChips,
    this.reactionCounters,
    this.id,
  }) {
    userProfileImage = userProfileImage ?? '';
    userName = userName ?? "Sarah Smith";
    timestamp = timestamp ?? "2 mins ago";
    participants = participants ?? [];
    reactionChips = reactionChips ?? [];
    reactionCounters = reactionCounters ?? [];
    id = id ?? "";
  }

  String? userProfileImage;
  String? userName;
  String? timestamp;
  List<ParticipantModel>? participants;
  List<ReactionChipModel>? reactionChips;
  List<ReactionCounterModel>? reactionCounters;
  String? id;

  VideoCallInterfaceModel copyWith({
    String? userProfileImage,
    String? userName,
    String? timestamp,
    List<ParticipantModel>? participants,
    List<ReactionChipModel>? reactionChips,
    List<ReactionCounterModel>? reactionCounters,
    String? id,
  }) {
    return VideoCallInterfaceModel(
      userProfileImage: userProfileImage ?? this.userProfileImage,
      userName: userName ?? this.userName,
      timestamp: timestamp ?? this.timestamp,
      participants: participants ?? this.participants,
      reactionChips: reactionChips ?? this.reactionChips,
      reactionCounters: reactionCounters ?? this.reactionCounters,
      id: id ?? this.id,
    );
  }

  @override
  List<Object?> get props => [
        userProfileImage,
        userName,
        timestamp,
        participants,
        reactionChips,
        reactionCounters,
        id,
      ];
}

// ignore_for_file: must_be_immutable
class ParticipantModel extends Equatable {
  ParticipantModel({
    this.id,
    this.profileImage,
    this.name,
    this.isActive,
  }) {
    id = id ?? "";
    profileImage = profileImage ?? "";
    name = name ?? "";
    isActive = isActive ?? false;
  }

  String? id;
  String? profileImage;
  String? name;
  bool? isActive;

  ParticipantModel copyWith({
    String? id,
    String? profileImage,
    String? name,
    bool? isActive,
  }) {
    return ParticipantModel(
      id: id ?? this.id,
      profileImage: profileImage ?? this.profileImage,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [id, profileImage, name, isActive];
}

// ignore_for_file: must_be_immutable
class ReactionChipModel extends Equatable {
  ReactionChipModel({
    this.label,
    this.isSelected,
  }) {
    label = label ?? "";
    isSelected = isSelected ?? false;
  }

  String? label;
  bool? isSelected;

  ReactionChipModel copyWith({
    String? label,
    bool? isSelected,
  }) {
    return ReactionChipModel(
      label: label ?? this.label,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  List<Object?> get props => [label, isSelected];
}

// ignore_for_file: must_be_immutable
class ReactionCounterModel extends Equatable {
  ReactionCounterModel({
    this.type,
    this.iconPath,
    this.count,
    this.isCustomView,
  }) {
    type = type ?? "";
    iconPath = iconPath ?? "";
    count = count ?? 0;
    isCustomView = isCustomView ?? false;
  }

  String? type;
  String? iconPath;
  int? count;
  bool? isCustomView;

  ReactionCounterModel copyWith({
    String? type,
    String? iconPath,
    int? count,
    bool? isCustomView,
  }) {
    return ReactionCounterModel(
      type: type ?? this.type,
      iconPath: iconPath ?? this.iconPath,
      count: count ?? this.count,
      isCustomView: isCustomView ?? this.isCustomView,
    );
  }

  @override
  List<Object?> get props => [type, iconPath, count, isCustomView];
}
