import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/qr_code_share_model.dart';
import '../../../core/app_export.dart';

part 'qr_code_share_state.dart';

final qrCodeShareNotifier =
    StateNotifierProvider.autoDispose<QRCodeShareNotifier, QRCodeShareState>(
  (ref) => QRCodeShareNotifier(
    QRCodeShareState(
      qrCodeShareModel: QRCodeShareModel(),
    ),
  ),
);

class QRCodeShareNotifier extends StateNotifier<QRCodeShareState> {
  QRCodeShareNotifier(QRCodeShareState state) : super(state) {
    initialize();
  }

  void initialize() {
    state = state.copyWith(
      isLoading: false,
      isUrlCopied: false,
      isDownloadSuccess: false,
      isShareSuccess: false,
    );
  }

  void copyUrlToClipboard() async {
    try {
      final url = state.qrCodeShareModel?.shareUrl ??
          'https://129r812309r72309r572093t72-2323t23t23t08';

      await Clipboard.setData(ClipboardData(text: url));

      state = state.copyWith(isUrlCopied: true);

      // Reset the copied state after a short delay
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          state = state.copyWith(isUrlCopied: false);
        }
      });
    } catch (e) {
      // Handle error silently or show error message
      print('Error copying to clipboard: $e');
    }
  }

  void downloadQRCode() async {
    try {
      state = state.copyWith(isLoading: true);

      // Simulate QR code download functionality
      // In real implementation, this would generate and save the QR code image
      await Future.delayed(Duration(seconds: 1));

      state = state.copyWith(
        isLoading: false,
        isDownloadSuccess: true,
      );

      // Reset the success state
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          state = state.copyWith(isDownloadSuccess: false);
        }
      });
    } catch (e) {
      state = state.copyWith(isLoading: false);
      print('Error downloading QR code: $e');
    }
  }

  void shareLink() async {
    try {
      final url = state.qrCodeShareModel?.shareUrl ??
          'https://129r812309r72309r572093t72-2323t23t23t08';
      final title = state.qrCodeShareModel?.memoryTitle ?? 'Family Xmas 2025';

      await Share.share(
        url,
        subject: 'Join $title memory collection',
      );

      state = state.copyWith(isShareSuccess: true);

      // Reset the success state
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          state = state.copyWith(isShareSuccess: false);
        }
      });
    } catch (e) {
      print('Error sharing link: $e');
    }
  }
}
