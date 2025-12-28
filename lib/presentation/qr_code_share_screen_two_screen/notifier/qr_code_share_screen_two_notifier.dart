import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/qr_code_share_screen_two_model.dart';
import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';

part 'qr_code_share_screen_two_state.dart';

final qrCodeShareScreenTwoNotifier = StateNotifierProvider.autoDispose<
    QRCodeShareScreenTwoNotifier, QRCodeShareScreenTwoState>(
  (ref) => QRCodeShareScreenTwoNotifier(
    QRCodeShareScreenTwoState(
      qrCodeShareScreenTwoModel: QRCodeShareScreenTwoModel(),
    ),
  ),
);

class QRCodeShareScreenTwoNotifier
    extends StateNotifier<QRCodeShareScreenTwoState> {
  QRCodeShareScreenTwoNotifier(QRCodeShareScreenTwoState state) : super(state);

  Future<void> loadUserFriendCode() async {
    try {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
      );

      final userId = SupabaseService.instance.client?.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await SupabaseService.instance.client!
          .from('user_profiles')
          .select('friend_code, display_name, username')
          .eq('id', userId)
          .single();

      final friendCode = response['friend_code'] as String;
      final displayName = response['display_name'] as String?;
      final username = response['username'] as String?;

      final shareUrl = 'https://capapp.co/add-friend/$friendCode';

      state = state.copyWith(
        qrCodeShareScreenTwoModel: QRCodeShareScreenTwoModel(
          friendCode: friendCode,
          displayName: displayName ?? username ?? 'User',
          qrCodeData: shareUrl,
          shareUrl: shareUrl,
        ),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void copyUrlToClipboard() async {
    try {
      final url = state.qrCodeShareScreenTwoModel?.shareUrl ?? '';

      await Clipboard.setData(ClipboardData(text: url));

      state = state.copyWith(isUrlCopied: true);

      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          state = state.copyWith(isUrlCopied: false);
        }
      });
    } catch (e) {
      print('Error copying to clipboard: $e');
    }
  }

  void downloadQRCode() async {
    try {
      state = state.copyWith(isLoading: true);

      await Future.delayed(Duration(seconds: 1));

      state = state.copyWith(
        isLoading: false,
        isDownloadSuccess: true,
      );

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
      final url = state.qrCodeShareScreenTwoModel?.shareUrl ?? '';
      final displayName =
          state.qrCodeShareScreenTwoModel?.displayName ?? 'Friend';

      await Share.share(
        url,
        subject: 'Add $displayName as friend on Capsule',
      );

      state = state.copyWith(isShareSuccess: true);

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
