import 'package:share_plus/share_plus.dart';

import '../../../core/app_export.dart';
import '../models/app_download_model.dart';

part 'app_download_state.dart';

final appDownloadNotifier =
    StateNotifierProvider.autoDispose<AppDownloadNotifier, AppDownloadState>(
  (ref) => AppDownloadNotifier(
    AppDownloadState(
      appDownloadModel: AppDownloadModel(),
    ),
  ),
);

class AppDownloadNotifier extends StateNotifier<AppDownloadState> {
  AppDownloadNotifier(AppDownloadState state) : super(state) {
    initialize();
  }

  void initialize() {
    state = state.copyWith(
      appDownloadModel: AppDownloadModel(
        qrData: AppDownloadModel.capsuleDownloadUrl,
        shareText:
            'Download the Capsule App and start creating memories together! https://capapp.co/download',
        isLoading: false,
      ),
    );
  }

  Future<void> shareApp() async {
    try {
      state = state.copyWith(
        isLoading: true,
        shareError: null,
        isShareSuccess: false,
      );

      final shareText = state.appDownloadModel?.shareText ??
          'Download the Capsule App and start creating memories together! https://capapp.co/download';

      await Share.share(
        shareText,
        subject: 'Download Capsule App',
      );

      state = state.copyWith(
        isLoading: false,
        isShareSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        shareError: 'Failed to share app link. Please try again.',
      );
    }
  }

  void updateQRData(String newData) {
    state = state.copyWith(
      appDownloadModel: state.appDownloadModel?.copyWith(
        qrData: newData,
      ),
    );
  }
}
