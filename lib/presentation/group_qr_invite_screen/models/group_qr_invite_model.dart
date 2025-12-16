import '../../../core/app_export.dart';

/// This class is used in the [GroupQRInviteScreen] screen.

// ignore_for_file: must_be_immutable
class GroupQRInviteModel extends Equatable {
  GroupQRInviteModel({
    this.groupName,
    this.invitationUrl,
    this.groupDescription,
    this.qrCodeData,
    this.iconPath,
    this.id,
  }) {
    groupName = groupName ?? "Jones Family";
    invitationUrl = invitationUrl ??
        ImageConstant.imgNetworkR812309r72309r572093t722323t23t23t08;
    groupDescription = groupDescription ?? "Scan to join the group";
    qrCodeData = qrCodeData ??
        ImageConstant.imgNetworkR812309r72309r572093t722323t23t23t08;
    iconPath = iconPath ?? ImageConstant.imgButtons;
    id = id ?? "";
  }

  String? groupName;
  String? invitationUrl;
  String? groupDescription;
  String? qrCodeData;
  String? iconPath;
  String? id;

  GroupQRInviteModel copyWith({
    String? groupName,
    String? invitationUrl,
    String? groupDescription,
    String? qrCodeData,
    String? iconPath,
    String? id,
  }) {
    return GroupQRInviteModel(
      groupName: groupName ?? this.groupName,
      invitationUrl: invitationUrl ?? this.invitationUrl,
      groupDescription: groupDescription ?? this.groupDescription,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      iconPath: iconPath ?? this.iconPath,
      id: id ?? this.id,
    );
  }

  @override
  List<Object?> get props => [
        groupName,
        invitationUrl,
        groupDescription,
        qrCodeData,
        iconPath,
        id,
      ];
}
