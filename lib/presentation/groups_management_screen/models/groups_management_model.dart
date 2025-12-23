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
  final String? id;
  final String? name;
  final int? memberCount;
  final String? creatorId;
  final String? inviteCode;
  final String? qrCodeUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String>? memberImages;

  GroupModel({
    this.id,
    this.name,
    this.memberCount,
    this.creatorId,
    this.inviteCode,
    this.qrCodeUrl,
    this.createdAt,
    this.updatedAt,
    this.memberImages,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] as String?,
      name: json['name'] as String?,
      memberCount: json['member_count'] as int? ?? 0,
      creatorId: json['creator_id'] as String?,
      inviteCode: json['invite_code'] as String?,
      qrCodeUrl: json['qr_code_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      memberImages: [],
    );
  }

  GroupModel copyWith({
    String? id,
    String? name,
    int? memberCount,
    String? creatorId,
    String? inviteCode,
    String? qrCodeUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? memberImages,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      memberCount: memberCount ?? this.memberCount,
      creatorId: creatorId ?? this.creatorId,
      inviteCode: inviteCode ?? this.inviteCode,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      memberImages: memberImages ?? this.memberImages,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        memberCount,
        creatorId,
        inviteCode,
        qrCodeUrl,
        createdAt,
        updatedAt,
        memberImages,
      ];
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
