import '../../../core/app_export.dart';

/// This class is used in the [memory_details_screen] screen.

// ignore_for_file: must_be_immutable
class MemoryDetailsModel extends Equatable {
  MemoryDetailsModel({
    this.title,
    this.inviteLink,
    this.isPublic,
    this.members,
  }) {
    title = title ?? "Family Xmas 2025";
    inviteLink = inviteLink ??
        ImageConstant.imgNetworkR812309r72309r572093t722323t23t23t08;
    isPublic = isPublic ?? true;
    members = members ?? [];
  }

  String? title;
  String? inviteLink;
  bool? isPublic;
  List<MemberModel>? members;

  MemoryDetailsModel copyWith({
    String? title,
    String? inviteLink,
    bool? isPublic,
    List<MemberModel>? members,
  }) {
    return MemoryDetailsModel(
      title: title ?? this.title,
      inviteLink: inviteLink ?? this.inviteLink,
      isPublic: isPublic ?? this.isPublic,
      members: members ?? this.members,
    );
  }

  @override
  List<Object?> get props => [title, inviteLink, isPublic, members];
}

// ignore_for_file: must_be_immutable
class MemberModel extends Equatable {
  MemberModel({
    this.name,
    this.profileImagePath,
    this.role,
    this.isCreator,
  }) {
    name = name ?? "";
    profileImagePath = profileImagePath ?? "";
    role = role ?? "";
    isCreator = isCreator ?? false;
  }

  String? name;
  String? profileImagePath;
  String? role;
  bool? isCreator;

  MemberModel copyWith({
    String? name,
    String? profileImagePath,
    String? role,
    bool? isCreator,
  }) {
    return MemberModel(
      name: name ?? this.name,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      role: role ?? this.role,
      isCreator: isCreator ?? this.isCreator,
    );
  }

  @override
  List<Object?> get props => [name, profileImagePath, role, isCreator];
}
