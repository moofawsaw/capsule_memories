import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/qr_code_share_screen_two_model.dart';
import '../../../core/app_export.dart';

part 'qr_code_share_screen_two_state.dart';

final qrCodeShareScreenTwoNotifier = StateNotifierProvider.autoDispose<
    QrCodeShareScreenTwoNotifier, QrCodeShareScreenTwoState>(
  (ref) => QrCodeShareScreenTwoNotifier(
    QrCodeShareScreenTwoState(
      qrCodeShareScreenTwoModel: QrCodeShareScreenTwoModel(),
    ),
  ),
);

class QrCodeShareScreenTwoNotifier
    extends StateNotifier<QrCodeShareScreenTwoState> {
  QrCodeShareScreenTwoNotifier(QrCodeShareScreenTwoState state) : super(state) {
    initialize();
  }

  void initialize() {
    final urlController = TextEditingController();
    urlController.text =
        ImageConstant.imgNetworkR812309r72309r572093t722323t23t23t08;

    state = state.copyWith(
      urlController: urlController,
      qrCodeShareScreenTwoModel: state.qrCodeShareScreenTwoModel?.copyWith(
        qrData: ImageConstant.imgNetworkR812309r72309r572093t722323t23t23t08,
        shareUrl: ImageConstant.imgNetworkR812309r72309r572093t722323t23t23t08,
      ),
    );
  }

  void copyUrlToClipboard() {
    final url = state.qrCodeShareScreenTwoModel?.shareUrl ?? '';
    if (url.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: url));
      state = state.copyWith(showCopySuccess: true);

      // Reset success message after showing
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          state = state.copyWith(showCopySuccess: false);
        }
      });
    }
  }

  void shareUrl() {
    final url = state.qrCodeShareScreenTwoModel?.shareUrl ?? '';
    if (url.isNotEmpty) {
      Share.share(
        url,
        subject: 'Connect with me on Memry',
      );
    }
  }

  @override
  void dispose() {
    state.urlController?.dispose();
    super.dispose();
  }
}
