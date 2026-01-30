import '../models/group_join_confirmation_model.dart';
import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';
import '../../../utils/storage_utils.dart';

part 'group_join_confirmation_state.dart';

final groupJoinConfirmationNotifier = StateNotifierProvider.autoDispose<
    GroupJoinConfirmationNotifier, GroupJoinConfirmationState>(
  (ref) => GroupJoinConfirmationNotifier(
    GroupJoinConfirmationState(
      groupJoinConfirmationModel: GroupJoinConfirmationModel(),
    ),
  ),
);

class GroupJoinConfirmationNotifier
    extends StateNotifier<GroupJoinConfirmationState> {
  GroupJoinConfirmationNotifier(GroupJoinConfirmationState state)
      : super(state);

  /// Load group details from database using invite code.
  Future<void> loadGroupDetailsByInviteCode(String inviteCode) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      groupId: null,
    );

    try {
      final supabase = SupabaseService.instance.client;
      if (supabase == null) {
        throw Exception('Database connection unavailable');
      }

      final normalized = inviteCode.trim();
      if (normalized.isEmpty) {
        throw Exception('Invalid invite code');
      }

      print('🔍 Loading group details for invite code: $normalized');

      // Fetch group details
      final response = await supabase.from('groups').select('''
            id,
            creator_id,
            name,
            member_count
          ''').eq('invite_code', normalized).maybeSingle().timeout(
            Duration(seconds: 10),
            onTimeout: () => null,
          );

      if (response == null) {
        throw Exception('Group not found');
      }

      final groupId = response['id'] as String?;
      final creatorId = response['creator_id'] as String?;
      final groupName = response['name'] as String?;
      final memberCount = response['member_count'] as int?;

      String? creatorName;
      String? creatorAvatar;
      List<String> memberAvatars = const [];

      if (creatorId != null && creatorId.isNotEmpty) {
        try {
          final creator = await supabase.from('user_profiles').select('''
              display_name,
              avatar_url
            ''').eq('id', creatorId).maybeSingle();
          creatorName = creator?['display_name'] as String?;
          creatorAvatar =
              StorageUtils.resolveAvatarUrl(creator?['avatar_url'] as String?) ??
                  creator?['avatar_url'] as String?;
        } catch (_) {}
      }

      // Fetch member avatars for preview row
      if (groupId != null && groupId.isNotEmpty) {
        try {
          final gm = await supabase
              .from('group_members')
              .select('user_id')
              .eq('group_id', groupId)
              .limit(50);

          final ids = <String>[];
          for (final row in (gm as List?) ?? const []) {
            if (row is! Map) continue;
            final id = (row['user_id'] as String?)?.trim();
            if (id != null && id.isNotEmpty) ids.add(id);
          }

          if (ids.isNotEmpty) {
            final profiles = await supabase
                .from('user_profiles')
                .select('id,avatar_url')
                .inFilter('id', ids);

            final urls = <String>[];
            for (final row in (profiles as List?) ?? const []) {
              if (row is! Map) continue;
              final avatarRaw = row['avatar_url'] as String?;
              final resolved = StorageUtils.resolveAvatarUrl(avatarRaw);
              if (resolved != null && resolved.trim().isNotEmpty) {
                urls.add(resolved.trim());
              }
            }

            // Ensure creator is represented (if they have an avatar and aren't already included)
            final creatorResolved = (creatorAvatar ?? '').trim();
            if (creatorResolved.isNotEmpty && !urls.contains(creatorResolved)) {
              urls.insert(0, creatorResolved);
            }

            memberAvatars = urls;
          } else {
            final creatorResolved = (creatorAvatar ?? '').trim();
            memberAvatars =
                creatorResolved.isNotEmpty ? [creatorResolved] : const [];
          }
        } catch (_) {
          final creatorResolved = (creatorAvatar ?? '').trim();
          memberAvatars = creatorResolved.isNotEmpty ? [creatorResolved] : const [];
        }
      }

      state = state.copyWith(
        isLoading: false,
        groupId: groupId,
        groupName: groupName,
        creatorName: creatorName,
        creatorAvatar: creatorAvatar,
        memberAvatars: memberAvatars,
        memberCount: memberCount,
        errorMessage: null,
      );
    } catch (e, stackTrace) {
      print('❌ Error loading group details: $e');
      print('   Stack trace: $stackTrace');

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load group details: ${e.toString()}',
      );
    }
  }

  /// Accept invitation - join group_members and navigate to Groups.
  Future<void> acceptInvitation() async {
    final groupId = state.groupId;
    if (groupId == null || groupId.isEmpty) {
      print('❌ No group ID available');
      return;
    }

    state = state.copyWith(isAccepting: true);

    try {
      final supabase = SupabaseService.instance.client;
      if (supabase == null) {
        throw Exception('Database connection unavailable');
      }

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      print('🔵 Accepting invitation for group: $groupId');
      print('   User ID: $userId');

      // Check if already a member
      final existingMember = await supabase
          .from('group_members')
          .select('id')
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingMember != null) {
        print('✅ User already a group member');
        state = state.copyWith(
          isAccepting: false,
          shouldNavigateToGroups: true,
        );
        return;
      }

      // Add user to group_members
      await supabase.from('group_members').insert({
        'group_id': groupId,
        'user_id': userId,
      });

      print('✅ Successfully joined group');

      state = state.copyWith(
        isAccepting: false,
        shouldNavigateToGroups: true,
      );

      // Reset navigation flag
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          state = state.copyWith(shouldNavigateToGroups: false);
        }
      });
    } catch (e, stackTrace) {
      print('❌ Error accepting invitation: $e');
      print('   Stack trace: $stackTrace');

      state = state.copyWith(
        isAccepting: false,
        errorMessage: 'Failed to join group: ${e.toString()}',
      );
    }
  }

  /// Decline invitation - navigate to groups screen
  void declineInvitation() {
    print('🔴 Declining invitation');

    state = state.copyWith(shouldNavigateToGroups: true);

    // Reset navigation flag
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        state = state.copyWith(shouldNavigateToGroups: false);
      }
    });
  }
}
