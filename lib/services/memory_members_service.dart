import './avatar_helper_service.dart';
import './supabase_service.dart';

class MemoryMembersService {
  final SupabaseService _supabaseService = SupabaseService.instance;
  final AvatarHelperService _avatarHelper = AvatarHelperService();

  /// Fetch memory members with their profile information
  Future<List<Map<String, dynamic>>> fetchMemoryMembers(String memoryId) async {
    try {
      final response = await _supabaseService.client
          ?.from('memory_contributors')
          .select('''
            id,
            user_id,
            joined_at,
            user_profiles!inner(
              id,
              display_name,
              username,
              avatar_url,
              is_verified
            )
          ''')
          .eq('memory_id', memoryId)
          .order('joined_at', ascending: true);

      if (response == null) return [];

      final List<Map<String, dynamic>> members = [];

      for (final contributor in response) {
        final userProfile =
        contributor['user_profiles'] as Map<String, dynamic>?;
        if (userProfile == null) continue;

        final avatarUrl = AvatarHelperService.getAvatarUrl(
          userProfile['avatar_url'] as String?,
        );

        members.add({
          'id': contributor['id'],
          // ✅ contributor membership user_id is the real user id
          'user_id': contributor['user_id'],
          // (optional) keep profile id separately if you ever need it
          'profile_id': userProfile['id'],
          'display_name': userProfile['display_name'] ??
              userProfile['username'] ??
              'Unknown User',
          'username': userProfile['username'] ?? '',
          'avatar_url': avatarUrl,
          'joined_at': contributor['joined_at'],
          'is_verified': userProfile['is_verified'] ?? false,
          'is_creator': false, // default
        });
      }

      return members;
    } catch (e) {
      print('Error fetching memory members: $e');
      rethrow;
    }
  }

  /// Fetch memory creator information
  Future<Map<String, dynamic>?> fetchMemoryCreator(String memoryId) async {
    try {
      final response = await _supabaseService.client
          ?.from('memories')
          .select('''
            creator_id,
            user_profiles!inner(
              id,
              display_name,
              username,
              avatar_url,
              is_verified
            )
          ''')
          .eq('id', memoryId)
          .single();

      if (response == null) return null;

      final userProfile = response['user_profiles'] as Map<String, dynamic>?;
      if (userProfile == null) return null;

      final avatarUrl = AvatarHelperService.getAvatarUrl(
        userProfile['avatar_url'] as String?,
      );

      // ✅ always use creator_id as the user_id for consistency
      final creatorId = response['creator_id'] as String? ?? userProfile['id'];

      return {
        'user_id': creatorId,
        'profile_id': userProfile['id'],
        'display_name':
        userProfile['display_name'] ?? userProfile['username'] ?? 'Creator',
        'username': userProfile['username'] ?? '',
        'avatar_url': avatarUrl,
        'joined_at': null,
        'is_creator': true,
        'is_verified': userProfile['is_verified'] ?? false,
      };
    } catch (e) {
      print('Error fetching memory creator: $e');
      return null;
    }
  }

  /// Get complete members list including creator and contributors (DEDUPED by user_id)
  Future<List<Map<String, dynamic>>> fetchAllMemoryMembers(
      String memoryId) async {
    try {
      // Fetch contributors first (these have joined_at ordering)
      final contributors = await fetchMemoryMembers(memoryId);

      // Index by user_id (this prevents duplicates)
      final Map<String, Map<String, dynamic>> byUserId = {};

      for (final c in contributors) {
        final uid = (c['user_id'] as String?) ?? '';
        if (uid.isEmpty) continue;
        byUserId[uid] = c;
      }

      // Fetch creator and merge into same entry if already present
      final creator = await fetchMemoryCreator(memoryId);
      if (creator != null) {
        final creatorUid = (creator['user_id'] as String?) ?? '';
        if (creatorUid.isNotEmpty) {
          if (byUserId.containsKey(creatorUid)) {
            // Promote creator flag + fill any missing fields
            final existing = byUserId[creatorUid]!;
            byUserId[creatorUid] = {
              ...existing,
              // keep contributor's joined_at if present
              'is_creator': true,
              // only overwrite display fields if existing is empty
              'display_name': (existing['display_name'] as String?)?.isNotEmpty ==
                  true
                  ? existing['display_name']
                  : creator['display_name'],
              'username': (existing['username'] as String?)?.isNotEmpty == true
                  ? existing['username']
                  : creator['username'],
              'avatar_url':
              (existing['avatar_url'] as String?)?.isNotEmpty == true
                  ? existing['avatar_url']
                  : creator['avatar_url'],
              'is_verified': existing['is_verified'] ?? creator['is_verified'],
              'profile_id': existing['profile_id'] ?? creator['profile_id'],
            };
          } else {
            // Creator is not in contributors list, add them
            byUserId[creatorUid] = creator;
          }
        }
      }

      // Return list with creator first, then by joined_at (nulls last)
      final list = byUserId.values.toList();

      list.sort((a, b) {
        final aIsCreator = (a['is_creator'] as bool?) ?? false;
        final bIsCreator = (b['is_creator'] as bool?) ?? false;

        if (aIsCreator && !bIsCreator) return -1;
        if (!aIsCreator && bIsCreator) return 1;

        final aJoined = a['joined_at'];
        final bJoined = b['joined_at'];

        // nulls last
        if (aJoined == null && bJoined != null) return 1;
        if (aJoined != null && bJoined == null) return -1;
        if (aJoined == null && bJoined == null) return 0;

        // joined_at is usually an ISO string from supabase
        return (aJoined as String).compareTo(bJoined as String);
      });

      return list;
    } catch (e) {
      print('Error fetching all memory members: $e');
      rethrow;
    }
  }

  /// Fetch group information for a memory if it was created from a group
  Future<Map<String, dynamic>?> fetchMemoryGroupInfo(String memoryId) async {
    try {
      final response = await _supabaseService.client
          ?.from('memories')
          .select('''
            group_id,
            groups!inner(
              id,
              name
            )
          ''')
          .eq('id', memoryId)
          .maybeSingle();

      if (response == null || response['group_id'] == null) return null;

      final groupData = response['groups'] as Map<String, dynamic>?;
      if (groupData == null) return null;

      return {
        'group_id': groupData['id'],
        'group_name': groupData['name'],
      };
    } catch (e) {
      print('Error fetching memory group info: $e');
      return null;
    }
  }
}
