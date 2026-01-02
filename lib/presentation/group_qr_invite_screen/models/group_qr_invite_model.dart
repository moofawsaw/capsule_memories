/// This class is used in the [GroupQRInviteScreen] screen.

// ignore_for_file: must_be_immutable
class GroupQRInviteModel {
  String? id;
  String? groupName;
  String? invitationUrl;
  String? qrCodeData;
  String? qrCodeUrl;
  String? groupDescription;
  String? iconPath;

  GroupQRInviteModel({
    this.id,
    this.groupName,
    this.invitationUrl,
    this.qrCodeData,
    this.qrCodeUrl,
    this.groupDescription,
    this.iconPath,
  });

  GroupQRInviteModel copyWith({
    String? id,
    String? groupName,
    String? invitationUrl,
    String? qrCodeData,
    String? qrCodeUrl,
    String? groupDescription,
    String? iconPath,
  }) {
    return GroupQRInviteModel(
      id: id ?? this.id,
      groupName: groupName ?? this.groupName,
      invitationUrl: invitationUrl ?? this.invitationUrl,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      groupDescription: groupDescription ?? this.groupDescription,
      iconPath: iconPath ?? this.iconPath,
    );
  }
}
