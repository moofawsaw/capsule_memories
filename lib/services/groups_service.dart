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

  /// Subscribes to real-time changes for groups table
  /// Returns a RealtimeChannel that can be used to unsubscribe
  static RealtimeChannel subscribeToGroupChanges({
    required Function(Map<String, dynamic>) onInsert,
    required Function(Map<String, dynamic>) onUpdate,
    required Function(Map<String, dynamic>) onDelete,
  }) {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final channel = _client
        .channel('groups_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'groups',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'creator_id',
            value: userId,
          ),
          callback: (payload) {
            onInsert(payload.newRecord);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'groups',
          callback: (payload) {
            final record = payload.newRecord;
            // Only trigger if user is creator or member
            if (record['creator_id'] == userId) {
              onUpdate(record);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'groups',
          callback: (payload) {
            onDelete(payload.oldRecord);
          },
        )
        .subscribe();

    return channel;
  }

  /// Subscribes to real-time changes for group_members table
  /// Returns a RealtimeChannel that can be used to unsubscribe
  static RealtimeChannel subscribeToGroupMembersChanges({
    required String groupId,
    required Function(Map<String, dynamic>) onMemberAdded,
    required Function(Map<String, dynamic>) onMemberRemoved,
  }) {
    final channel = _client
        .channel('group_members_$groupId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'group_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (payload) {
            onMemberAdded(payload.newRecord);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'group_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (payload) {
            onMemberRemoved(payload.oldRecord);
          },
        )
        .subscribe();

    return channel;
  }

  /// Subscribes to member count changes for user's groups
  /// This listens to group_members changes and refetches group data
  static RealtimeChannel subscribeToUserGroupMembershipChanges({
    required Function() onMembershipChanged,
  }) {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final channel = _client
        .channel('user_group_membership')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'group_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            onMembershipChanged();
          },
        )
        .subscribe();

    return channel;
  }

  /// Fetches group members with their profile information
  /// Fetches group members with their profile information
  static Future<List<Map<String, dynamic>>> fetchGroupMembers(
      String groupId) async {
    try {
      final response = await _client
          .from('group_members')
          .select(
        'user_id, joined_at, user_profiles!inner(id, display_name, username, avatar_url)',
      )
          .eq('group_id', groupId)
      // Optional but useful: deterministic ordering
          .order('joined_at', ascending: true);

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
            // Keep what your UI already expects
            'id': profile['id'],
            'name': profile['display_name'] ?? 'Unknown User',
            'username': profile['username'] ?? 'username',
            'avatar': avatarUrl,

            // IMPORTANT: add joined_at as top-level so UI can read it
            'joined_at': member['joined_at'],
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

  /// Fetches a single group by ID with invite code
  static Future<Map<String, dynamic>?> fetchGroupById(String groupId) async {
    try {
      final response = await _client.from('groups').select('''
            id,
            name,
            member_count,
            creator_id,
            invite_code,
            qr_code_url,
            created_at,
            updated_at
          ''').eq('id', groupId).single();
      print('✅ GROUP FETCH: Loaded group');
      print('   - Name: ${response['name']}');
      print('   - Invite Code: ${response['invite_code']}');
      print('   - QR Code URL: ${response['qr_code_url']}');
      print('🔍 GROUP DEBUG qr_code_url analysis:');
      final rawQr = response['qr_code_url'];
      print('   - Raw value: $rawQr');
      print('   - Type: ${rawQr.runtimeType}');
      print('   - Is null: ${rawQr == null}');
      print('   - Is empty string: ${rawQr == ""}');
      print('   - Keys: ${response.keys.toList()}');

      return response;

    } catch (e) {
      print('Error fetching group: $e');
      return null;
    }
  }
}
