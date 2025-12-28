import '../../../core/app_export.dart';

class QRCodeShareScreenTwoModel extends Equatable {
  QRCodeShareScreenTwoModel({
    this.friendCode,
    this.displayName,
    this.qrCodeData,
    this.shareUrl,
  });

  String? friendCode;
  String? displayName;
  String? qrCodeData;
  String? shareUrl;

  QRCodeShareScreenTwoModel copyWith({
    String? friendCode,
    String? displayName,
    String? qrCodeData,
    String? shareUrl,
  }) {
    return QRCodeShareScreenTwoModel(
      friendCode: friendCode ?? this.friendCode,
      displayName: displayName ?? this.displayName,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      shareUrl: shareUrl ?? this.shareUrl,
    );
  }

  @override
  List<Object?> get props => [
        friendCode,
        displayName,
        qrCodeData,
        shareUrl,
      ];
}
