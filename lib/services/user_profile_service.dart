import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import './supabase_service.dart';
import './story_service.dart';

class UserProfileService {
  static UserProfileService? _instance;
  static UserProfileService get instance =>
      _instance ??= UserProfileService._();

  UserProfileService._();

  final StreamController<String> _storyDeletedController =
      StreamController<String>.broadcast();

  /// Emits story IDs when the current user deletes a story.
  Stream<String> get storyDeletedStream => _storyDeletedController.stream;

  void _emitStoryDeleted(String storyId) {
    final id = storyId.trim();
    if (id.isEmpty) return;
    if (_storyDeletedController.isClosed) return;
    _storyDeletedController.add(id);
  }

  /// Delete a story and notify listeners (e.g. profile story grid).
  ///
  /// NOTE: This is a convenience wrapper around `StoryService.deleteStory()`
  /// that also broadcasts deletion so any listening UI can update immediately.
  Future<bool> deleteStory(String storyId) async {
    final id = storyId.trim();
    if (id.isEmpty) return false;

    final ok = await StoryService().deleteStory(id);
    if (ok) _emitStoryDeleted(id);
    return ok;
  }

  /// Upload avatar to Supabase Storage and return file path
  /// Works on both web and mobile platforms
  Future<String?> uploadAvatar(Uint8List imageBytes, String fileName) async {
    try {
      final client = SupabaseService.instance.client;
      if (client == null) {
        print('⚠️ Supabase client not available');
        return null;
      }

      final user = client.auth.currentUser;
      if (user == null) {
        print('⚠️ No authenticated user');
        return null;
      }

      final fileExtension = fileName.split('.').last;
      final filePath =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      // Upload bytes directly - works on both web and mobile
      await client.storage.from('avatars').uploadBinary(filePath, imageBytes);

      print('✅ Avatar uploaded successfully: $filePath');
      return filePath;
    } catch (e) {
      print('❌ Error uploading avatar: $e');
      return null;
    }
  }

  /// Get signed URL for private avatar
  Future<String?> getAvatarUrl(String filePath) async {
    try {
      final client = SupabaseService.instance.client;
      if (client == null) return null;

      final signedUrl =
          await client.storage.from('avatars').createSignedUrl(filePath, 3600);
      return signedUrl;
    } catch (e) {
      print('❌ Error getting avatar URL: $e');
      return null;
    }
  }

  /// Delete old avatar from storage
  Future<bool> deleteAvatar(String filePath) async {
    try {
      final client = SupabaseService.instance.client;
      if (client == null) return false;

      await client.storage.from('avatars').remove([filePath]);

      print('✅ Avatar deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting avatar: $e');
      return false;
    }
  }
  /// ✅ PUBLIC profile by ID (for viewing other users) - NO email
  Future<Map<String, dynamic>?> getPublicUserProfileById(String userId) async {
    try {
      final client = SupabaseService.instance.client;
      if (client == null) return null;

      // Prefer the PUBLIC view/table first (RLS-safe).
      Map<String, dynamic>? response;
      try {
        response = await client
            .from('user_profiles_public')
            .select(
              'id, username, display_name, avatar_url, follower_count, following_count, is_verified',
            )
            .eq('id', userId)
            .maybeSingle();
      } catch (e) {
        debugPrint('⚠️ Public profile lookup failed: $e');
        response = null;
      }

      if (response != null) {
        debugPrint('✅ Public user profile fetched successfully for: $userId');
        return response;
      }

      // Fallback: some installations/views can exclude users who haven't posted yet.
      // We only select public-safe fields (no email) from the private table.
      debugPrint(
        '⚠️ No PUBLIC profile found for user: $userId. Falling back to user_profiles.',
      );

      Map<String, dynamic>? fallback;
      try {
        fallback = await client
            .from('user_profiles')
            .select(
              'id, username, display_name, avatar_url, follower_count, following_count, is_verified',
            )
            .eq('id', userId)
            .maybeSingle();
      } catch (e) {
        debugPrint('⚠️ user_profiles fallback lookup failed: $e');
        fallback = null;
      }

      if (fallback != null) {
        debugPrint('✅ Fallback profile fetched successfully for: $userId');
        return fallback;
      }

      // Final fallback: many parts of the app use the `profiles` table for avatar/name.
      // Keep this PUBLIC-safe: only fetch id/username/display_name/avatar_url.
      debugPrint(
        '⚠️ No profile found in user_profiles for user: $userId. Falling back to profiles.',
      );

      try {
        final res = await client
            .from('profiles')
            .select('id, username, display_name, avatar_url')
            .eq('id', userId)
            .maybeSingle();

        if (res == null) {
          debugPrint('⚠️ No profile found in profiles for user: $userId');
          return null;
        }

        // Normalize shape to match callers expecting follower/following keys sometimes.
        return {
          ...res,
          'follower_count': 0,
          'following_count': 0,
          'is_verified': false,
        };
      } catch (e) {
        debugPrint('⚠️ profiles fallback lookup failed: $e');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error fetching PUBLIC user profile by ID: $e');
      return null;
    }
  }

  /// Get current authenticated user profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final client = SupabaseService.instance.client;
      if (client == null) {
        print('⚠️ Supabase client not available');
        return null;
      }

      final user = client.auth.currentUser;
      if (user == null) {
        print('⚠️ No authenticated user');
        return null;
      }

      final response = await client
          .from('user_profiles')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      print('❌ Error fetching user profile: $e');
      return null;
    }
  }

  /// Update current user profile
  Future<bool> updateUserProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? locationName,
    double? locationLat,
    double? locationLng,
  }) async {
    try {
      final client = SupabaseService.instance.client;
      if (client == null) return false;

      final user = client.auth.currentUser;
      if (user == null) return false;

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (displayName != null) updates['display_name'] = displayName;
      if (bio != null) updates['bio'] = bio;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (locationName != null) updates['location_name'] = locationName;
      if (locationLat != null) updates['location_lat'] = locationLat;
      if (locationLng != null) updates['location_lng'] = locationLng;

      await client.from('user_profiles').update(updates).eq('id', user.id);

      print('✅ User profile updated successfully');
      return true;
    } catch (e) {
      print('❌ Error updating user profile: $e');
      return false;
    }
  }

  /// Get user profile by specific user ID (for viewing other users' profiles)
  Future<Map<String, dynamic>?> getUserProfileById(String userId) async {
    try {
      final client = SupabaseService.instance.client;
      if (client == null) return null;

      final response = await client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        debugPrint('⚠️ No profile found for user: $userId');
        return null;
      }

      debugPrint('✅ User profile fetched successfully for: $userId');
      return response;
    } catch (e) {
      debugPrint('❌ Error fetching user profile by ID: $e');
      return null;
    }
  }

  /// Get user profile by username
  Future<Map<String, dynamic>?> getUserProfileByUsername(
      String username) async {
    try {
      final client = SupabaseService.instance.client;
      if (client == null) return null;

      final response = await client
          .from('user_profiles')
          .select('*')
          .eq('username', username)
          .maybeSingle();

      return response;
    } catch (e) {
      print('❌ Error fetching user profile by username: $e');
      return null;
    }
  }

  /// ✅ Search users (PUBLIC) by username or display name
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final client = SupabaseService.instance.client;
      if (client == null) return [];

      final response = await client
          .from('user_profiles_public')
          .select('id, username, display_name, avatar_url, is_verified')
          .or('username.ilike.%$query%,display_name.ilike.%$query%')
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error searching users: $e');
      return [];
    }
  }


  /// ✅ Get user stats (PUBLIC-safe): followers, following, posts
  Future<Map<String, int>> getUserStats(String userId) async {
    try {
      final client = SupabaseService.instance.client;
      if (client == null) {
        return {'followers': 0, 'following': 0, 'posts': 0};
      }

      // Use public table so we never touch private profile data for others
      Map<String, dynamic>? profile = await client
          .from('user_profiles_public')
          .select('follower_count, following_count')
          .eq('id', userId)
          .maybeSingle();

      // Fallback: same rationale as getPublicUserProfileById (users with 0 stories).
      if (profile == null) {
        profile = await client
            .from('user_profiles')
            .select('follower_count, following_count')
            .eq('id', userId)
            .maybeSingle();
      }

      final storiesCount = await client
          .from('stories')
          .select('id')
          .eq('contributor_id', userId)
          .count(CountOption.exact);

      return {
        'followers': (profile?['follower_count'] as int?) ?? 0,
        'following': (profile?['following_count'] as int?) ?? 0,
        'posts': storiesCount.count,
      };
    } catch (e) {
      print('❌ Error fetching user stats: $e');
      return {'followers': 0, 'following': 0, 'posts': 0};
    }
  }

}
