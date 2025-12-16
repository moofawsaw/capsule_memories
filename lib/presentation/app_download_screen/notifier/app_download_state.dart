part of 'app_download_notifier.dart';

class AppDownloadState extends Equatable {
  final AppDownloadModel? appDownloadModel;
  final bool? isLoading;
  final bool? isShareSuccess;
  final String? shareError;

  AppDownloadState({
    this.appDownloadModel,
    this.isLoading = false,
    this.isShareSuccess = false,
    this.shareError,
  });

  @override
  List<Object?> get props => [
        appDownloadModel,
        isLoading,
        isShareSuccess,
        shareError,
      ];

  AppDownloadState copyWith({
    AppDownloadModel? appDownloadModel,
    bool? isLoading,
    bool? isShareSuccess,
    String? shareError,
  }) {
    return AppDownloadState(
      appDownloadModel: appDownloadModel ?? this.appDownloadModel,
      isLoading: isLoading ?? this.isLoading,
      isShareSuccess: isShareSuccess ?? this.isShareSuccess,
      shareError: shareError,
    );
  }
}
