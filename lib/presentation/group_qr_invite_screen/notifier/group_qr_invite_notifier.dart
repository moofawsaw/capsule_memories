import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_export.dart';
import '../../../services/groups_service.dart';
import '../../../services/supabase_service.dart';
import '../models/group_qr_invite_model.dart';

part 'group_qr_invite_state.dart';

final groupQRInviteNotifier = StateNotifierProvider.autoDispose<
    GroupQRInviteNotifier, GroupQRInviteState>(
      (ref) => GroupQRInviteNotifier(
    GroupQRInviteState(
      groupQRInviteModel: GroupQRInviteModel(),
    ),
  ),
);

class GroupQRInviteNotifier extends StateNotifier<GroupQRInviteState> {
  GroupQRInviteNotifier(GroupQRInviteState state) : super(state);

  SupabaseClient get _client => SupabaseService.instance.client!;

  // Change this if your QR images live in a different bucket.
  static const String defaultQrBucket = 'group_qr';

  Future<void> initialize(String groupId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final groupData = await GroupsService.fetchGroupById(groupId);

      if (!mounted) return;

      if (groupData == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load group data',
        );
        return;
      }

      final inviteCode = (groupData['invite_code'] as String?)?.trim();
      final groupName = (groupData['name'] as String?)?.trim();
      final id = (groupData['id'] as String?)?.trim();

      if (id == null || id.isEmpty || inviteCode == null || inviteCode.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Group data missing required fields (id/invite_code)',
        );
        return;
      }

      final inviteUrl = 'https://share.capapp.co/join/group/$inviteCode';

      final resolvedQrUrl = await _resolveQrUrl(groupData['qr_code_url']);

      state = state.copyWith(
        isLoading: false,
        groupQRInviteModel: GroupQRInviteModel(
          id: id,
          groupName: groupName ?? 'Group',
          invitationUrl: inviteUrl,
          qrCodeData: inviteUrl,
          qrCodeUrl: resolvedQrUrl,
          groupDescription: 'Scan to join the group',
          iconPath: '',
        ),
      );
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Error loading group: ${e.toString()}',
        );
      }
    }
  }

  /// Converts whatever is stored in `qr_code_url` into a fetchable URL.
  /// Handles:
  /// - Full https Supabase storage URLs (public URLs that might still 403)
  /// - Raw storage paths (e.g. "folder/file.png")
  /// - Empty values
  Future<String?> _resolveQrUrl(dynamic raw) async {
    if (raw == null) return null;
    if (raw is! String) return null;

    final v = raw.trim();
    if (v.isEmpty) return null;

    // 1) If this looks like a Supabase Storage URL, extract bucket + path and sign it.
    // Example:
    // https://xyz.supabase.co/storage/v1/object/public/<bucket>/<path>
    if (v.startsWith('http://') || v.startsWith('https://')) {
      final uri = Uri.tryParse(v);
      if (uri != null) {
        final segments = uri.pathSegments;

        // Find ".../object/public/<bucket>/<path...>"
        final objectIdx = segments.indexOf('object');
        if (objectIdx != -1 && segments.length > objectIdx + 2) {
          final visibility = segments[objectIdx + 1]; // "public" or "sign" etc
          if (visibility == 'public' && segments.length > objectIdx + 3) {
            final bucket = segments[objectIdx + 2];
            final path = segments.sublist(objectIdx + 3).join('/');

            // Prefer signed URL even if a "public" URL exists (public URL can still 403 on private bucket).
            try {
              final signed = await _client.storage.from(bucket).createSignedUrl(
                path,
                60 * 60, // 1 hour
              );
              if (signed.trim().isNotEmpty) return signed.trim();
            } catch (_) {
              // If signing fails, fall back to the original URL.
              return v;
            }
          }
        }
      }

      // Not a Supabase storage URL; just return as-is.
      return v;
    }

    // 2) Otherwise treat it as a storage path in your default bucket and sign it.
    final cleanPath = v.startsWith('/') ? v.substring(1) : v;

    try {
      final signed = await _client.storage.from(defaultQrBucket).createSignedUrl(
        cleanPath,
        60 * 60, // 1 hour
      );
      if (signed.trim().isNotEmpty) return signed.trim();
    } catch (_) {
      // If signing fails, last resort: try public URL.
      try {
        final pub = _client.storage.from(defaultQrBucket).getPublicUrl(cleanPath);
        if (pub.trim().isNotEmpty) return pub.trim();
      } catch (_) {}
    }

    return null;
  }

  void updateUrl(String newUrl) {
    final updatedModel = state.groupQRInviteModel?.copyWith(
      invitationUrl: newUrl,
      qrCodeData: newUrl,
    );

    state = state.copyWith(groupQRInviteModel: updatedModel);
  }

  void onDownloadQR() {
    state = state.copyWith(isDownloading: true);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        state = state.copyWith(
          isDownloading: false,
          downloadSuccess: true,
        );
      }
    });
  }

  void onShareLink() {
    state = state.copyWith(isSharing: true);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        state = state.copyWith(
          isSharing: false,
          shareSuccess: true,
        );
      }
    });
  }

  void onCopyUrl() {
    state = state.copyWith(copySuccess: true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        state = state.copyWith(copySuccess: false);
      }
    });
  }

  void resetActions() {
    state = state.copyWith(
      downloadSuccess: false,
      shareSuccess: false,
      copySuccess: false,
    );
  }
}
