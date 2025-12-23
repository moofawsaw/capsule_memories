import './supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GroupsService {
  static SupabaseClient get _client => SupabaseService.instance.client!;

  /// Fetches all groups that the current user is a member of or created
  static Future<List<Map<String, dynamic>>> fetchUserGroups() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Fetch groups where user is the creator
      final createdGroupsResponse = await _client.from('groups').select('''
            id,
            name,
            member_count,
            creator_id,
            invite_code,
            qr_code_url,
            created_at,
            updated_at
          ''').eq('creator_id', userId);

      // Fetch group IDs where user is a member
      final membershipResponse = await _client
          .from('group_members')
          .select('group_id')
          .eq('user_id', userId);

      final memberGroupIds = (membershipResponse as List)
          .map((m) => m['group_id'] as String)
          .toList();

      List<Map<String, dynamic>> allGroups =
          List<Map<String, dynamic>>.from(createdGroupsResponse);

      // Fetch groups where user is a member (but not creator to avoid duplicates)
      if (memberGroupIds.isNotEmpty) {
        final memberGroupsResponse = await _client.from('groups').select('''
              id,
              name,
              member_count,
              creator_id,
              invite_code,
              qr_code_url,
              created_at,
              updated_at
            ''').inFilter('id', memberGroupIds).neq('creator_id', userId);

        allGroups.addAll(List<Map<String, dynamic>>.from(memberGroupsResponse));
      }

      // Sort by created_at descending
      allGroups.sort((a, b) {
        final aDate = DateTime.parse(a['created_at'] ?? '');
        final bDate = DateTime.parse(b['created_at'] ?? '');
        return bDate.compareTo(aDate);
      });

      return allGroups;
    } catch (e) {
      print('Error fetching groups: $e');
      return [];
    }
  }

  /// Fetches group members with their profile information
  static Future<List<Map<String, dynamic>>> fetchGroupMembers(
      String groupId) async {
    try {
      final response = await _client
          .from('group_members')
          .select(
              'user_id, user_profiles!inner(id, display_name, username, avatar_url)')
          .eq('group_id', groupId);

      final members = <Map<String, dynamic>>[];
      for (final member in response) {
        final profile = member['user_profiles'];
        if (profile != null) {
          final avatarPath = profile['avatar_url'];
          String avatarUrl = '';

          if (avatarPath != null && avatarPath.isNotEmpty) {
            if (avatarPath.startsWith('http://') ||
                avatarPath.startsWith('https://')) {
              avatarUrl = avatarPath;
            } else {
              try {
                final cleanPath = avatarPath.startsWith('/')
                    ? avatarPath.substring(1)
                    : avatarPath;
                avatarUrl =
                    _client.storage.from('avatars').getPublicUrl(cleanPath);
              } catch (e) {
                print('Error generating avatar URL: $e');
              }
            }
          }

          members.add({
            'id': profile['id'],
            'name': profile['display_name'] ?? 'Unknown User',
            'username': profile['username'] ?? 'username',
            'avatar': avatarUrl,
          });
        }
      }

      return members;
    } catch (e) {
      print('Error fetching group members: $e');
      return [];
    }
  }

  /// Fetches member avatars for a specific group
  static Future<List<String>> fetchGroupMemberAvatars(String groupId,
      {int limit = 3}) async {
    try {
      final response = await _client
          .from('group_members')
          .select('user_id, user_profiles!inner(avatar_url)')
          .eq('group_id', groupId)
          .limit(limit);

      final List<String> avatars = [];
      for (final member in response) {
        final avatarPath = member['user_profiles']?['avatar_url'];
        if (avatarPath != null && avatarPath.isNotEmpty) {
          // Use same inline URL conversion logic as current user
          String avatarUrl = '';
          if (avatarPath.startsWith('http://') ||
              avatarPath.startsWith('https://')) {
            avatarUrl = avatarPath;
          } else {
            try {
              final cleanPath = avatarPath.startsWith('/')
                  ? avatarPath.substring(1)
                  : avatarPath;
              avatarUrl =
                  _client.storage.from('avatars').getPublicUrl(cleanPath);
            } catch (e) {
              print('Error generating avatar URL: $e');
            }
          }

          if (avatarUrl.isNotEmpty) {
            avatars.add(avatarUrl);
          }
        }
      }

      return avatars;
    } catch (e) {
      print('Error fetching group member avatars: $e');
      return [];
    }
  }

  /// Creates a new group and returns the group ID
  static Future<String?> createGroup(String groupName) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client
          .from('groups')
          .insert({
            'name': groupName,
            'creator_id': userId,
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      print('Error creating group: $e');
      return null;
    }
  }

  /// Adds a member to a group
  static Future<bool> addGroupMember(String groupId, String userId) async {
    try {
      await _client.from('group_members').insert({
        'group_id': groupId,
        'user_id': userId,
      });

      return true;
    } catch (e) {
      print('Error adding group member: $e');
      return false;
    }
  }

  /// Removes a member from a group (creator only)
  static Future<bool> removeGroupMember(String groupId, String userId) async {
    try {
      await _client
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('Error removing group member: $e');
      return false;
    }
  }

  /// Deletes a group (only creator can delete)
  static Future<bool> deleteGroup(String groupId) async {
    try {
      await _client.from('groups').delete().eq('id', groupId);
      return true;
    } catch (e) {
      print('Error deleting group: $e');
      return false;
    }
  }

  /// Updates a group's name (creator only)
  static Future<bool> updateGroupName(String groupId, String newName) async {
    try {
      await _client.from('groups').update({
        'name': newName,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', groupId);

      return true;
    } catch (e) {
      print('Error updating group name: $e');
      return false;
    }
  }

  /// Leaves a group (for members who are not creators)
  static Future<bool> leaveGroup(String groupId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      await _client
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('Error leaving group: $e');
      return false;
    }
  }
}
