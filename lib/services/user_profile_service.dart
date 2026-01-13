import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import './supabase_service.dart';

class UserProfileService {
  static UserProfileService? _instance;
  static UserProfileService get instance =>
      _instance ??= UserProfileService._();

  UserProfileService._();

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

      final response = await client
          .from('user_profiles_public')
          .select('id, username, display_name, avatar_url, follower_count, following_count, is_verified')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        debugPrint('⚠️ No PUBLIC profile found for user: $userId');
        return null;
      }

      debugPrint('✅ Public user profile fetched successfully for: $userId');
      return response;
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
      final profile = await client
          .from('user_profiles_public')
          .select('follower_count, following_count')
          .eq('id', userId)
          .maybeSingle();

      final storiesCount = await client
          .from('stories')
          .select('id')
          .eq('contributor_id', userId)
          .count(CountOption.exact);

      return {
        'followers': (profile?['follower_count'] as int?) ?? 0,
        'following': (profile?['following_count'] as int?) ?? 0,
        'posts': storiesCount.count ?? 0,
      };
    } catch (e) {
      print('❌ Error fetching user stats: $e');
      return {'followers': 0, 'following': 0, 'posts': 0};
    }
  }

}
