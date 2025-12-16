import '../../../core/app_export.dart';

/// This class is used in the [MemoryInvitationScreen] screen.

// ignore_for_file: must_be_immutable
class MemoryInvitationModel extends Equatable {
  MemoryInvitationModel({
    this.memoryTitle,
    this.creatorName,
    this.creatorImage,
    this.membersCount,
    this.storiesCount,
    this.status,
    this.invitationMessage,
    this.id,
  }) {
    memoryTitle = memoryTitle ?? "Fmaily Xmas 2025";
    creatorName = creatorName ?? "Jane Doe";
    creatorImage = creatorImage ?? ImageConstant.imgEllipse81;
    membersCount = membersCount ?? 2;
    storiesCount = storiesCount ?? 0;
    status = status ?? "Open";
    invitationMessage =
        invitationMessage ?? "You've been invited to join this memory";
    id = id ?? "";
  }

  String? memoryTitle;
  String? creatorName;
  String? creatorImage;
  int? membersCount;
  int? storiesCount;
  String? status;
  String? invitationMessage;
  String? id;

  MemoryInvitationModel copyWith({
    String? memoryTitle,
    String? creatorName,
    String? creatorImage,
    int? membersCount,
    int? storiesCount,
    String? status,
    String? invitationMessage,
    String? id,
  }) {
    return MemoryInvitationModel(
      memoryTitle: memoryTitle ?? this.memoryTitle,
      creatorName: creatorName ?? this.creatorName,
      creatorImage: creatorImage ?? this.creatorImage,
      membersCount: membersCount ?? this.membersCount,
      storiesCount: storiesCount ?? this.storiesCount,
      status: status ?? this.status,
      invitationMessage: invitationMessage ?? this.invitationMessage,
      id: id ?? this.id,
    );
  }

  @override
  List<Object?> get props => [
        memoryTitle,
        creatorName,
        creatorImage,
        membersCount,
        storiesCount,
        status,
        invitationMessage,
        id,
      ];
}
