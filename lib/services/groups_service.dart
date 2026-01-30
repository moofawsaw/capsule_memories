import './supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GroupsService {
  static SupabaseClient get _client => SupabaseService.instance.client!;

  // In-memory cache for resolved avatar URLs (especially signed URLs).
  // Keyed by normalized storage key (or raw http(s) URL).
  static final Map<String, _AvatarUrlCacheEntry> _avatarUrlCache = {};

  static String _cleanStoragePath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return '';
    var p = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;

    // Some installs store bucket-prefixed keys like "avatars/<key>".
    if (p.startsWith('avatars/')) {
      p = p.substring('avatars/'.length);
    }
    if (p.startsWith('public/avatars/')) {
      p = p.substring('public/avatars/'.length);
    }

    return p;
  }

  /// Resolve an avatar reference into a displayable URL.
  ///
  /// Supports:
  /// - Full http(s) URLs (returned as-is)
  /// - Storage keys/paths in the `avatars` bucket (returns a signed URL)
  static Future<String> _resolveAvatarToDisplayUrl(String? avatarRef) async {
    final raw = (avatarRef ?? '').trim();
    if (raw.isEmpty) return '';

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      final cached = _avatarUrlCache[raw];
      if (cached != null && !cached.isExpired) return cached.url;
      _avatarUrlCache[raw] = _AvatarUrlCacheEntry(url: raw);
      return raw;
    }

    final cleanPath = _cleanStoragePath(raw);
    if (cleanPath.isEmpty) return '';

    final cached = _avatarUrlCache[cleanPath];
    if (cached != null && !cached.isExpired) return cached.url;

    // Prefer signed URLs (works even when bucket is private).
    try {
      final signed = await _client.storage.from('avatars').createSignedUrl(
            cleanPath,
            3600,
          );
      if (signed.trim().isNotEmpty) {
        _avatarUrlCache[cleanPath] = _AvatarUrlCacheEntry(
          url: signed.trim(),
          ttl: const Duration(minutes: 55),
        );
        return signed.trim();
      }
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ GroupsService: createSignedUrl failed for "$cleanPath": $e');
    }

    // Fallback: if bucket is public, a public URL will work.
    try {
      final publicUrl = _client.storage.from('avatars').getPublicUrl(cleanPath);
      if (publicUrl.trim().isNotEmpty) {
        _avatarUrlCache[cleanPath] = _AvatarUrlCacheEntry(
          url: publicUrl.trim(),
          ttl: const Duration(hours: 12),
        );
        return publicUrl.trim();
      }
    } catch (_) {}

    return '';
  }

  static Future<Map<String, Map<String, dynamic>>> _fetchProfilesByIds(
    List<String> userIds,
  ) async {
    final ids = userIds.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    if (ids.isEmpty) return {};

    Future<List<Map<String, dynamic>>> tryTable(
      String table,
    ) async {
      final res = await _client
          .from(table)
          .select('id, display_name, username, avatar_url')
          .inFilter('id', ids.toList());
      return List<Map<String, dynamic>>.from(res as List);
    }

    List<Map<String, dynamic>> rows = const [];

    // Prefer the public-safe view/table if it exists in this project.
    try {
      rows = await tryTable('user_profiles_public');
    } catch (_) {
      rows = const [];
    }

    // Fallback to main profiles table
    if (rows.isEmpty) {
      try {
        rows = await tryTable('user_profiles');
      } catch (_) {
        rows = const [];
      }
    }

    // Final fallback for older installs
    if (rows.isEmpty) {
      try {
        rows = await tryTable('profiles');
      } catch (_) {
        rows = const [];
      }
    }

    final Map<String, Map<String, dynamic>> byId = {};
    for (final r in rows) {
      final id = (r['id'] as String?)?.trim();
      if (id == null || id.isEmpty) continue;
      byId[id] = r;
    }
    return byId;
  }

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
  /// ✅ Includes creator even if creator is missing from group_members (legacy groups)
  static Future<List<Map<String, dynamic>>> fetchGroupMembers(
      String groupId) async {
    try {
      // A) Get creator_id (so we can ensure creator is present)
      final group = await _client
          .from('groups')
          .select('creator_id')
          .eq('id', groupId)
          .maybeSingle();
      final creatorId = (group?['creator_id'] as String?)?.trim();

      // B) Fetch member IDs from group_members (no join, more resilient to RLS changes)
      final response = await _client
          .from('group_members')
          .select('user_id, joined_at')
          .eq('group_id', groupId)
          .order('joined_at', ascending: true);

      final rows = List<Map<String, dynamic>>.from(response as List);
      final memberIds = <String>[];
      final joinedAtById = <String, String?>{};

      for (final r in rows) {
        final uid = (r['user_id'] as String?)?.trim();
        if (uid == null || uid.isEmpty) continue;
        memberIds.add(uid);
        joinedAtById[uid] = r['joined_at'] as String?;
      }

      // Ensure creator is included (legacy groups may not include creator row)
      if (creatorId != null &&
          creatorId.isNotEmpty &&
          !memberIds.contains(creatorId)) {
        memberIds.insert(0, creatorId);
        joinedAtById[creatorId] = null;

        // Best-effort backfill: only if current user is the creator.
        final currentUserId = _client.auth.currentUser?.id;
        if (currentUserId != null && currentUserId == creatorId) {
          try {
            await _client.from('group_members').insert({
              'group_id': groupId,
              'user_id': creatorId,
            });
          } catch (_) {}
        }
      }

      // C) Fetch profiles for all member IDs (public view first, then fallbacks)
      final profilesById = await _fetchProfilesByIds(memberIds);

      final Map<String, Map<String, dynamic>> byUserId = {};
      // Resolve avatar URLs in parallel (signing can be slow if done sequentially).
      final avatarFutures = <String, Future<String>>{};
      for (final uid in memberIds) {
        final profile = profilesById[uid];
        final avatarRef = (profile?['avatar_url'] as String?)?.trim();
        avatarFutures[uid] = _resolveAvatarToDisplayUrl(avatarRef);
      }

      final resolvedAvatarUrls = <String, String>{};
      await Future.wait(
        avatarFutures.entries.map((e) async {
          resolvedAvatarUrls[e.key] = await e.value;
        }),
      );

      for (final uid in memberIds) {
        final profile = profilesById[uid];

        final displayName = (profile?['display_name'] as String?)?.trim();
        final username = (profile?['username'] as String?)?.trim();
        final avatarUrl = resolvedAvatarUrls[uid] ?? '';

        byUserId[uid] = {
          'id': uid,
          'profile_id': profile?['id'],
          'name': (displayName == null || displayName.isEmpty)
              ? 'Unknown User'
              : displayName,
          'username':
              (username == null || username.isEmpty) ? 'username' : username,
          'avatar': avatarUrl,
          'joined_at': joinedAtById[uid],
          'is_creator': (creatorId != null && uid == creatorId),
        };
      }

      final members = byUserId.values.toList();

      // D) Sort: creator first, then joined_at
      members.sort((a, b) {
        final aCreator = (a['is_creator'] as bool?) ?? false;
        final bCreator = (b['is_creator'] as bool?) ?? false;
        if (aCreator && !bCreator) return -1;
        if (!aCreator && bCreator) return 1;

        final aJoined = a['joined_at'];
        final bJoined = b['joined_at'];

        if (aJoined == null && bJoined != null) return 1;
        if (aJoined != null && bJoined == null) return -1;
        if (aJoined == null && bJoined == null) return 0;

        return (aJoined as String).compareTo(bJoined as String);
      });

      return members;
    } catch (e) {
      print('Error fetching group members: $e');
      return [];
    }
  }

  /// Fetches member avatars for a specific group
  /// ✅ Includes creator if group_members is missing creator (legacy groups)
  static Future<List<String>> fetchGroupMemberAvatars(
    String groupId, {
    int limit = 3,
  }) async {
    try {
      // A) Read creator_id
      final group = await _client
          .from('groups')
          .select('creator_id')
          .eq('id', groupId)
          .maybeSingle();
      final creatorId = (group?['creator_id'] as String?)?.trim();

      // B) Fetch member IDs from group_members (no join)
      final response = await _client
          .from('group_members')
          .select('user_id, joined_at')
          .eq('group_id', groupId)
          .order('joined_at', ascending: true)
          .limit(limit);

      final rows = List<Map<String, dynamic>>.from(response as List);
      final memberIds = <String>[];
      for (final r in rows) {
        final uid = (r['user_id'] as String?)?.trim();
        if (uid == null || uid.isEmpty) continue;
        memberIds.add(uid);
      }

      // If creator missing (legacy), add creator to the front (and keep limit)
      if (creatorId != null &&
          creatorId.isNotEmpty &&
          !memberIds.contains(creatorId)) {
        memberIds.insert(0, creatorId);
        if (memberIds.length > limit) memberIds.removeLast();
      }

      // C) Fetch profiles and resolve avatar URLs
      final profilesById = await _fetchProfilesByIds(memberIds);
      final avatars = <String>[];

      final resolved = await Future.wait(
        memberIds.map((uid) async {
          final profile = profilesById[uid];
          final avatarRef = (profile?['avatar_url'] as String?)?.trim();
          return _resolveAvatarToDisplayUrl(avatarRef);
        }),
      );
      for (final url in resolved) {
        if (url.isNotEmpty) avatars.add(url);
      }

      return avatars;
    } catch (e) {
      print('Error fetching group member avatars: $e');
      return [];
    }
  }

  /// Creates a new group and returns the group ID
  /// ✅ Ensures creator is also inserted into group_members
  static Future<String?> createGroup(String groupName) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // 1) Create group
      final response = await _client
          .from('groups')
          .insert({
            'name': groupName,
            'creator_id': userId,
          })
          .select('id')
          .single();

      final groupId = response['id'] as String?;

      if (groupId == null || groupId.isEmpty) {
        return null;
      }

      // 2) Add creator as a member (idempotent-ish)
      // If you have a unique constraint on (group_id, user_id), this will be safe.
      try {
        await _client.from('group_members').insert({
          'group_id': groupId,
          'user_id': userId,
        });
      } catch (e) {
        // Non-fatal: group exists; member insert may fail if already present
        print('⚠️ createGroup: could not add creator to group_members: $e');
      }

      // 3) Optional: keep member_count accurate if you use it
      // Only do this if your schema doesn't already update member_count via trigger.
      try {
        await _client
            .from('groups')
            .update({'member_count': 1}).eq('id', groupId);
      } catch (e) {
        // Non-fatal
        print('⚠️ createGroup: could not update member_count: $e');
      }

      return groupId;
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

class _AvatarUrlCacheEntry {
  final String url;
  final DateTime expiresAt;

  _AvatarUrlCacheEntry({
    required this.url,
    Duration ttl = const Duration(minutes: 55),
  }) : expiresAt = DateTime.now().add(ttl);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
