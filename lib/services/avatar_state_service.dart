import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';
import './user_profile_service.dart';

/// Global avatar state notifier that broadcasts avatar changes across the app
/// All widgets displaying user avatars should listen to this provider
class AvatarState {
  final String? avatarUrl;
  final String? userEmail;
  final bool isLoading;
  final String? userId;

  AvatarState({
    this.avatarUrl,
    this.userEmail,
    this.isLoading = false,
    this.userId,
  });

  AvatarState copyWith({
    String? avatarUrl,
    String? userEmail,
    bool? isLoading,
    String? userId,
  }) {
    return AvatarState(
      avatarUrl: avatarUrl ?? this.avatarUrl,
      userEmail: userEmail ?? this.userEmail,
      isLoading: isLoading ?? this.isLoading,
      userId: userId ?? this.userId,
    );
  }
}

class AvatarStateNotifier extends StateNotifier<AvatarState> {
  AvatarStateNotifier() : super(AvatarState());

  RealtimeChannel? _channel;

  @override
  void dispose() {
    _unsubscribeRealtime();
    super.dispose();
  }

  void _unsubscribeRealtime() {
    final client = SupabaseService.instance.client;
    if (client == null) return;

    try {
      if (_channel != null) {
        client.removeChannel(_channel!);
        _channel = null;
      }
    } catch (_) {
      // ignore
    }
  }

  /// Start listening for avatar changes for the current user
  Future<void> _subscribeToAvatarChanges(String userId) async {
    final client = SupabaseService.instance.client;
    if (client == null) return;

    // avoid duplicate subscriptions
    if (_channel != null) return;

    _channel = client.channel('avatar_changes_$userId');

    _channel!
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'user_profiles',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: userId,
      ),
      callback: (payload) async {
        try {
          final newRow = payload.newRecord;
          final oldRow = payload.oldRecord;

          final newPath = newRow['avatar_url'] as String?;
          final oldPath = oldRow['avatar_url'] as String?;

          // avatar removed
          if (newPath == null || newPath.isEmpty) {
            state = state.copyWith(avatarUrl: null);
            return;
          }

          // ✅ Ignore updates that didn't actually change avatar_url (e.g., updated_at)
          if (oldPath != null && oldPath == newPath) return;

          String? displayReadyUrl;

          // If already a full URL (e.g., Google OAuth), use directly
          if (newPath.startsWith('http://') || newPath.startsWith('https://')) {
            displayReadyUrl = newPath;
          } else {
            // Supabase storage key -> signed URL
            displayReadyUrl = await UserProfileService.instance.getAvatarUrl(newPath);
          }

          if (displayReadyUrl != null && displayReadyUrl.isNotEmpty) {
            // ✅ Stable URL; cache eviction happens inside updateAvatar()
            updateAvatar(displayReadyUrl);
          }
        } catch (e) {
          print('❌ Avatar realtime update error: $e');
        }
      },
    )
        .subscribe();
  }

  /// Load current user's avatar from database
  /// 🎯 HANDLES BOTH GOOGLE OAUTH URLS AND SUPABASE STORAGE KEYS
  Future<void> loadCurrentUserAvatar() async {
    state = state.copyWith(isLoading: true);

    try {
      final client = SupabaseService.instance.client;
      if (client == null) {
        state = AvatarState(isLoading: false);
        return;
      }

      final user = client.auth.currentUser;
      if (user == null) {
        state = AvatarState(isLoading: false);
        _unsubscribeRealtime();
        return;
      }

      final userProfile = await UserProfileService.instance.getCurrentUserProfile();

      if (userProfile != null) {
        final avatarStoragePath = userProfile['avatar_url'] as String?;
        String? displayReadyUrl;

        if (avatarStoragePath != null && avatarStoragePath.isNotEmpty) {
          if (avatarStoragePath.startsWith('http://') ||
              avatarStoragePath.startsWith('https://')) {
            displayReadyUrl = avatarStoragePath;
          } else {
            displayReadyUrl =
            await UserProfileService.instance.getAvatarUrl(avatarStoragePath);
          }
        }

        state = AvatarState(
          avatarUrl: displayReadyUrl,
          userEmail: userProfile['email'] as String?,
          isLoading: false,
          userId: user.id,
        );

        // ✅ Start realtime listening for cross-device changes
        await _subscribeToAvatarChanges(user.id);
      } else {
        state = AvatarState(isLoading: false, userId: user.id);
        await _subscribeToAvatarChanges(user.id);
      }
    } catch (e) {
      print('❌ Error loading avatar: $e');
      state = AvatarState(isLoading: false);
    }
  }

  /// Update avatar URL after successful upload (local immediate broadcast)
  void updateAvatar(String newAvatarUrl, {String? userEmail}) {
    final oldUrl = state.avatarUrl;

    // ✅ Evict old image from Flutter image cache so UI reloads immediately
    if (oldUrl != null && oldUrl.isNotEmpty) {
      final oldBase = oldUrl.split('?').first;
      PaintingBinding.instance.imageCache.evict(NetworkImage(oldUrl));
      PaintingBinding.instance.imageCache.evict(NetworkImage(oldBase));
    }

    final newBase = newAvatarUrl.split('?').first;
    PaintingBinding.instance.imageCache.evict(NetworkImage(newAvatarUrl));
    PaintingBinding.instance.imageCache.evict(NetworkImage(newBase));

    state = state.copyWith(
      avatarUrl: newAvatarUrl, // ✅ keep stable, no ?t=
      userEmail: userEmail ?? state.userEmail,
      isLoading: false,
    );
  }

  /// Clear avatar state on logout
  void clearAvatar() {
    _unsubscribeRealtime();
    state = AvatarState();
  }

  /// Refresh avatar from database - call when needed
  Future<void> refreshAvatar() async {
    _unsubscribeRealtime();
    state = AvatarState();
    await loadCurrentUserAvatar();
  }
}

/// Global avatar state provider
final avatarStateProvider =
StateNotifierProvider<AvatarStateNotifier, AvatarState>(
      (ref) => AvatarStateNotifier(),
);
