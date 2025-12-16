import '../../../core/app_export.dart';

/// This class is used in the [QRCodeShareScreen] screen.

// ignore_for_file: must_be_immutable
class QRCodeShareModel extends Equatable {
  QRCodeShareModel({
    this.memoryTitle,
    this.memoryDescription,
    this.qrCodeData,
    this.shareUrl,
    this.iconPath,
  }) {
    memoryTitle = memoryTitle ?? "Family Xmas 2025";
    memoryDescription = memoryDescription ?? "Scan to join memory";
    qrCodeData = qrCodeData ??
        ImageConstant.imgNetworkR812309r72309r572093t722323t23t23t08;
    shareUrl = shareUrl ??
        ImageConstant.imgNetworkR812309r72309r572093t722323t23t23t08;
    iconPath = iconPath ?? ImageConstant.imgFrameDeepOrangeA700;
  }

  String? memoryTitle;
  String? memoryDescription;
  String? qrCodeData;
  String? shareUrl;
  String? iconPath;

  QRCodeShareModel copyWith({
    String? memoryTitle,
    String? memoryDescription,
    String? qrCodeData,
    String? shareUrl,
    String? iconPath,
  }) {
    return QRCodeShareModel(
      memoryTitle: memoryTitle ?? this.memoryTitle,
      memoryDescription: memoryDescription ?? this.memoryDescription,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      shareUrl: shareUrl ?? this.shareUrl,
      iconPath: iconPath ?? this.iconPath,
    );
  }

  @override
  List<Object?> get props => [
        memoryTitle,
        memoryDescription,
        qrCodeData,
        shareUrl,
        iconPath,
      ];
}
