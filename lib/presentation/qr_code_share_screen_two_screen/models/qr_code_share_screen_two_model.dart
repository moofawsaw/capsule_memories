class QRCodeShareScreenTwoModel {
  String? friendCode;
  String? displayName;
  String? qrCodeData;
  String? shareUrl;
  String? qrCodeUrl;
  String? avatarUrl;

  QRCodeShareScreenTwoModel({
    this.friendCode,
    this.displayName,
    this.qrCodeData,
    this.shareUrl,
    this.qrCodeUrl,
  });

  QRCodeShareScreenTwoModel copyWith({
    String? friendCode,
    String? displayName,
    String? qrCodeData,
    String? shareUrl,
    String? qrCodeUrl,
  }) {
    return QRCodeShareScreenTwoModel(
      friendCode: friendCode ?? this.friendCode,
      displayName: displayName ?? this.displayName,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      shareUrl: shareUrl ?? this.shareUrl,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
    );
  }
}
