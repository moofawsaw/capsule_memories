import '../../../core/app_export.dart';

/// This class is used in the [GroupsManagementScreen] screen.

// ignore_for_file: must_be_immutable
class GroupsManagementModel extends Equatable {
  GroupsManagementModel({this.id}) {
    id = id ?? "";
  }

  String? id;

  GroupsManagementModel copyWith({
    String? id,
  }) {
    return GroupsManagementModel(
      id: id ?? this.id,
    );
  }

  @override
  List<Object?> get props => [id];
}

class GroupModel extends Equatable {
  GroupModel({
    this.name,
    this.memberCount,
    this.memberImages,
  });

  String? name;
  int? memberCount;
  List<String>? memberImages;

  GroupModel copyWith({
    String? name,
    int? memberCount,
    List<String>? memberImages,
  }) {
    return GroupModel(
      name: name ?? this.name,
      memberCount: memberCount ?? this.memberCount,
      memberImages: memberImages ?? this.memberImages,
    );
  }

  @override
  List<Object?> get props => [name, memberCount, memberImages];
}

class GroupInvitationModel extends Equatable {
  GroupInvitationModel({
    this.groupName,
    this.memberCount,
    this.avatarImage,
  });

  String? groupName;
  int? memberCount;
  String? avatarImage;

  GroupInvitationModel copyWith({
    String? groupName,
    int? memberCount,
    String? avatarImage,
  }) {
    return GroupInvitationModel(
      groupName: groupName ?? this.groupName,
      memberCount: memberCount ?? this.memberCount,
      avatarImage: avatarImage ?? this.avatarImage,
    );
  }

  @override
  List<Object?> get props => [groupName, memberCount, avatarImage];
}
