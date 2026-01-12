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

      if (response == null) {
        return [];
      }

      final List<Map<String, dynamic>> members = [];

      for (final contributor in response) {
        final userProfile = contributor['user_profiles'] as Map<String, dynamic>?;
        if (userProfile == null) continue;

        final avatarUrl = AvatarHelperService.getAvatarUrl(
          userProfile['avatar_url'] as String?,
        );

        members.add({
          'id': contributor['id'],
          // ✅ use the contributor membership user_id as the real user id
          'user_id': contributor['user_id'],
          // (optional) keep profile id separately if you ever need it
          'profile_id': userProfile['id'],
          'display_name':
          userProfile['display_name'] ?? userProfile['username'] ?? 'Unknown User',
          'username': userProfile['username'] ?? '',
          'avatar_url': avatarUrl,
          'joined_at': contributor['joined_at'],
          'is_verified': userProfile['is_verified'] ?? false,
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
      final response =
      await _supabaseService.client?.from('memories').select('''
            creator_id,
            user_profiles!inner(
              id,
              display_name,
              username,
              avatar_url,
              is_verified
            )
          ''').eq('id', memoryId).single();

      if (response == null) {
        return null;
      }

      final userProfile = response['user_profiles'] as Map<String, dynamic>?;

      if (userProfile != null) {
        final avatarUrl = AvatarHelperService.getAvatarUrl(
          userProfile['avatar_url'] as String?,
        );

        return {
          'user_id': userProfile['id'],
          'display_name': userProfile['display_name'] ??
              userProfile['username'] ??
              'Creator',
          'username': userProfile['username'] ?? '',
          'avatar_url': avatarUrl,
          'is_creator': true,
          'is_verified': userProfile['is_verified'] ?? false,
        };
      }

      return null;
    } catch (e) {
      print('Error fetching memory creator: $e');
      return null;
    }
  }

  /// Get complete members list including creator and contributors (creator is NOT removed)
  Future<List<Map<String, dynamic>>> fetchAllMemoryMembers(String memoryId) async {
    try {
      final List<Map<String, dynamic>> allMembers = [];

      // Fetch creator first (if available)
      final creator = await fetchMemoryCreator(memoryId);
      if (creator != null) {
        allMembers.add(creator);
      }

      // Fetch contributors (do NOT filter out creator)
      final contributors = await fetchMemoryMembers(memoryId);
      allMembers.addAll(contributors);

      return allMembers;
    } catch (e) {
      print('Error fetching all memory members: $e');
      rethrow;
    }
  }

  /// Fetch group information for a memory if it was created from a group
  Future<Map<String, dynamic>?> fetchMemoryGroupInfo(String memoryId) async {
    try {
      final response =
      await _supabaseService.client?.from('memories').select('''
            group_id,
            groups!inner(
              id,
              name
            )
          ''').eq('id', memoryId).maybeSingle();

      if (response == null || response['group_id'] == null) {
        return null;
      }

      final groupData = response['groups'] as Map<String, dynamic>?;

      if (groupData != null) {
        return {
          'group_id': groupData['id'],
          'group_name': groupData['name'],
        };
      }

      return null;
    } catch (e) {
      print('Error fetching memory group info: $e');
      return null;
    }
  }
}
