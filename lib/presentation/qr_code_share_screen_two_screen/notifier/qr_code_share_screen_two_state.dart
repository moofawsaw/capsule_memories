part of 'qr_code_share_screen_two_notifier.dart';

class QRCodeShareScreenTwoState extends Equatable {
  QRCodeShareScreenTwoState({
    this.qrCodeShareScreenTwoModel,
    this.isLoading,
    this.isUrlCopied,
    this.isDownloadSuccess,
    this.isShareSuccess,
    this.errorMessage,
  });

  QRCodeShareScreenTwoModel? qrCodeShareScreenTwoModel;
  bool? isLoading;
  bool? isUrlCopied;
  bool? isDownloadSuccess;
  bool? isShareSuccess;
  String? errorMessage;

  @override
  List<Object?> get props => [
        qrCodeShareScreenTwoModel,
        isLoading,
        isUrlCopied,
        isDownloadSuccess,
        isShareSuccess,
        errorMessage,
      ];

  QRCodeShareScreenTwoState copyWith({
    QRCodeShareScreenTwoModel? qrCodeShareScreenTwoModel,
    bool? isLoading,
    bool? isUrlCopied,
    bool? isDownloadSuccess,
    bool? isShareSuccess,
    String? errorMessage,
  }) {
    return QRCodeShareScreenTwoState(
      qrCodeShareScreenTwoModel:
          qrCodeShareScreenTwoModel ?? this.qrCodeShareScreenTwoModel,
      isLoading: isLoading ?? this.isLoading,
      isUrlCopied: isUrlCopied ?? this.isUrlCopied,
      isDownloadSuccess: isDownloadSuccess ?? this.isDownloadSuccess,
      isShareSuccess: isShareSuccess ?? this.isShareSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
