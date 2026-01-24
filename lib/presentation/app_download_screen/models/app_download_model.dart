import '../../../core/app_export.dart';

/// This class is used in the [app_download_screen] screen.

// ignore_for_file: must_be_immutable
class AppDownloadModel extends Equatable {
  static const String capsuleDownloadUrl = 'https://capapp.co/download';

  AppDownloadModel({
    this.qrData,
    this.shareText,
    this.isLoading,
    this.id,
  }) {
    qrData = qrData ?? capsuleDownloadUrl;
    shareText = shareText ??
        "Download the Capsule App and start creating memories together! https://capapp.co/download";
    isLoading = isLoading ?? false;
    id = id ?? "";
  }

  String? qrData;
  String? shareText;
  bool? isLoading;
  String? id;

  AppDownloadModel copyWith({
    String? qrData,
    String? shareText,
    bool? isLoading,
    String? id,
  }) {
    return AppDownloadModel(
      qrData: qrData ?? this.qrData,
      shareText: shareText ?? this.shareText,
      isLoading: isLoading ?? this.isLoading,
      id: id ?? this.id,
    );
  }

  @override
  List<Object?> get props => [qrData, shareText, isLoading, id];
}
