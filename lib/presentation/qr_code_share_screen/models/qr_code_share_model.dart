import '../../../core/app_export.dart';

/// This class is used in the [QRCodeShareScreen] screen.

// ignore_for_file: must_be_immutable
class QRCodeShareModel extends Equatable {
  QRCodeShareModel({
    this.memoryTitle,
    this.memoryDescription,
    this.qrCodeData,
    this.shareUrl,
  }) {
    memoryTitle = memoryTitle ?? "Family Xmas 2025";
    memoryDescription = memoryDescription ?? "Scan to join memory";
    qrCodeData = qrCodeData ?? 'https://capapp.co';
    shareUrl = shareUrl ?? 'https://capapp.co';
  }

  String? memoryTitle;
  String? memoryDescription;
  String? qrCodeData;
  String? shareUrl;

  QRCodeShareModel copyWith({
    String? memoryTitle,
    String? memoryDescription,
    String? qrCodeData,
    String? shareUrl,
  }) {
    return QRCodeShareModel(
      memoryTitle: memoryTitle ?? this.memoryTitle,
      memoryDescription: memoryDescription ?? this.memoryDescription,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      shareUrl: shareUrl ?? this.shareUrl,
    );
  }

  @override
  List<Object?> get props => [
        memoryTitle,
        memoryDescription,
        qrCodeData,
        shareUrl,
      ];
}
