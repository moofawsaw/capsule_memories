import '../../../core/app_export.dart';

/// This class is used in the [MemoryMembersScreen] screen.

// ignore_for_file: must_be_immutable
class MemoryMembersModel extends Equatable {
  MemoryMembersModel({
    this.members,
    this.memoryTitle,
    this.memoryId,
  }) {
    members = members ?? [];
    memoryTitle = memoryTitle ?? "Family Memory";
    memoryId = memoryId ?? "";
  }

  List<MemberModel>? members;
  String? memoryTitle;
  String? memoryId;

  MemoryMembersModel copyWith({
    List<MemberModel>? members,
    String? memoryTitle,
    String? memoryId,
  }) {
    return MemoryMembersModel(
      members: members ?? this.members,
      memoryTitle: memoryTitle ?? this.memoryTitle,
      memoryId: memoryId ?? this.memoryId,
    );
  }

  @override
  List<Object?> get props => [members, memoryTitle, memoryId];
}

// ignore_for_file: must_be_immutable
class MemberModel extends Equatable {
  MemberModel({
    this.name,
    this.profileImagePath,
    this.role,
    this.status,
    this.userId,
  }) {
    name = name ?? "";
    profileImagePath = profileImagePath ?? "";
    role = role ?? "Member";
    status = status ?? "Active";
    userId = userId ?? "";
  }

  String? name;
  String? profileImagePath;
  String? role;
  String? status;
  String? userId;

  MemberModel copyWith({
    String? name,
    String? profileImagePath,
    String? role,
    String? status,
    String? userId,
  }) {
    return MemberModel(
      name: name ?? this.name,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      role: role ?? this.role,
      status: status ?? this.status,
      userId: userId ?? this.userId,
    );
  }

  @override
  List<Object?> get props => [name, profileImagePath, role, status, userId];
}
