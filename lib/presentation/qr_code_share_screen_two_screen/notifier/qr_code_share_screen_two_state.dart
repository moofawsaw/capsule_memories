part of 'qr_code_share_screen_two_notifier.dart';

class QrCodeShareScreenTwoState extends Equatable {
  final TextEditingController? urlController;
  final bool? showCopySuccess;
  final bool? isLoading;
  final QrCodeShareScreenTwoModel? qrCodeShareScreenTwoModel;

  QrCodeShareScreenTwoState({
    this.urlController,
    this.showCopySuccess = false,
    this.isLoading = false,
    this.qrCodeShareScreenTwoModel,
  });

  @override
  List<Object?> get props => [
        urlController,
        showCopySuccess,
        isLoading,
        qrCodeShareScreenTwoModel,
      ];

  QrCodeShareScreenTwoState copyWith({
    TextEditingController? urlController,
    bool? showCopySuccess,
    bool? isLoading,
    QrCodeShareScreenTwoModel? qrCodeShareScreenTwoModel,
  }) {
    return QrCodeShareScreenTwoState(
      urlController: urlController ?? this.urlController,
      showCopySuccess: showCopySuccess ?? this.showCopySuccess,
      isLoading: isLoading ?? this.isLoading,
      qrCodeShareScreenTwoModel:
          qrCodeShareScreenTwoModel ?? this.qrCodeShareScreenTwoModel,
    );
  }
}
