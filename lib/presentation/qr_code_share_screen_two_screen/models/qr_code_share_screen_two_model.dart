import '../../../core/app_export.dart';

/// This class is used in the [QrCodeShareScreenTwo] screen.

// ignore_for_file: must_be_immutable
class QrCodeShareScreenTwoModel extends Equatable {
  QrCodeShareScreenTwoModel({
    this.qrData,
    this.shareUrl,
    this.title,
    this.description,
    this.id,
  }) {
    qrData =
        qrData ?? ImageConstant.imgNetworkR812309r72309r572093t722323t23t23t08;
    shareUrl = shareUrl ??
        ImageConstant.imgNetworkR812309r72309r572093t722323t23t23t08;
    title = title ?? "Share QR code";
    description = description ??
        "Share this QR code to become friends with other Memry users";
    id = id ?? "";
  }

  String? qrData;
  String? shareUrl;
  String? title;
  String? description;
  String? id;

  QrCodeShareScreenTwoModel copyWith({
    String? qrData,
    String? shareUrl,
    String? title,
    String? description,
    String? id,
  }) {
    return QrCodeShareScreenTwoModel(
      qrData: qrData ?? this.qrData,
      shareUrl: shareUrl ?? this.shareUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      id: id ?? this.id,
    );
  }

  @override
  List<Object?> get props => [
        qrData,
        shareUrl,
        title,
        description,
        id,
      ];
}
