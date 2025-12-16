part of 'qr_code_share_notifier.dart';

class QRCodeShareState extends Equatable {
  final QRCodeShareModel? qrCodeShareModel;
  final bool? isLoading;
  final bool? isUrlCopied;
  final bool? isDownloadSuccess;
  final bool? isShareSuccess;

  QRCodeShareState({
    this.qrCodeShareModel,
    this.isLoading = false,
    this.isUrlCopied = false,
    this.isDownloadSuccess = false,
    this.isShareSuccess = false,
  });

  @override
  List<Object?> get props => [
        qrCodeShareModel,
        isLoading,
        isUrlCopied,
        isDownloadSuccess,
        isShareSuccess,
      ];

  QRCodeShareState copyWith({
    QRCodeShareModel? qrCodeShareModel,
    bool? isLoading,
    bool? isUrlCopied,
    bool? isDownloadSuccess,
    bool? isShareSuccess,
  }) {
    return QRCodeShareState(
      qrCodeShareModel: qrCodeShareModel ?? this.qrCodeShareModel,
      isLoading: isLoading ?? this.isLoading,
      isUrlCopied: isUrlCopied ?? this.isUrlCopied,
      isDownloadSuccess: isDownloadSuccess ?? this.isDownloadSuccess,
      isShareSuccess: isShareSuccess ?? this.isShareSuccess,
    );
  }
}
