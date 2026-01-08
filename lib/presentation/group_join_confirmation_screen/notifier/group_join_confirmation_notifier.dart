import '../models/group_join_confirmation_model.dart';
import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';

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

  /// Load memory details from database
  Future<void> loadMemoryDetails(String memoryId) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      memoryId: memoryId,
    );

    try {
      final supabase = SupabaseService.instance.client;
      if (supabase == null) {
        throw Exception('Database connection unavailable');
      }

      print('🔍 Loading memory details for: $memoryId');

      // Fetch memory details with creator info and category
      final response = await supabase.from('memories').select('''
            id,
            title,
            expires_at,
            contributor_count,
            creator_id,
            category_id,
            user_profiles!memories_creator_id_fkey (
              display_name,
              avatar_url
            ),
            memory_categories (
              name
            )
          ''').eq('id', memoryId).maybeSingle().timeout(
            Duration(seconds: 10),
            onTimeout: () => null,
          );

      if (response == null) {
        throw Exception('Memory not found');
      }

      print('✅ Memory details loaded successfully');

      // Parse creator info
      final creatorData = response['user_profiles'] as Map<String, dynamic>?;
      final categoryData =
          response['memory_categories'] as Map<String, dynamic>?;

      // Parse expires_at
      DateTime? parsedExpiresAt;
      if (response['expires_at'] != null) {
        try {
          parsedExpiresAt = DateTime.parse(response['expires_at'] as String);
        } catch (e) {
          print('⚠️ Failed to parse expires_at: $e');
        }
      }

      state = state.copyWith(
        isLoading: false,
        memoryTitle: response['title'] as String?,
        creatorName: creatorData?['display_name'] as String?,
        creatorAvatar: creatorData?['avatar_url'] as String?,
        memoryCategory: categoryData?['name'] as String?,
        expiresAt: parsedExpiresAt,
        memberCount: response['contributor_count'] as int?,
        errorMessage: null,
      );
    } catch (e, stackTrace) {
      print('❌ Error loading memory details: $e');
      print('   Stack trace: $stackTrace');

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load memory details: ${e.toString()}',
      );
    }
  }

  /// Accept invitation - join memory_contributors and navigate to timeline
  Future<void> acceptInvitation() async {
    if (state.memoryId == null) {
      print('❌ No memory ID available');
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

      print('🔵 Accepting invitation for memory: ${state.memoryId}');
      print('   User ID: $userId');

      // Check if already a contributor
      final existingContributor = await supabase
          .from('memory_contributors')
          .select('id')
          .eq('memory_id', state.memoryId!)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingContributor != null) {
        print('✅ User already a contributor, navigating to timeline');
        state = state.copyWith(
          isAccepting: false,
          shouldNavigateToTimeline: true,
        );
        return;
      }

      // Add user to memory_contributors
      await supabase.from('memory_contributors').insert({
        'memory_id': state.memoryId!,
        'user_id': userId,
      });

      print('✅ Successfully joined memory');

      state = state.copyWith(
        isAccepting: false,
        shouldNavigateToTimeline: true,
      );

      // Reset navigation flag
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          state = state.copyWith(shouldNavigateToTimeline: false);
        }
      });
    } catch (e, stackTrace) {
      print('❌ Error accepting invitation: $e');
      print('   Stack trace: $stackTrace');

      state = state.copyWith(
        isAccepting: false,
        errorMessage: 'Failed to join memory: ${e.toString()}',
      );
    }
  }

  /// Decline invitation - navigate to memories screen
  void declineInvitation() {
    print('🔴 Declining invitation');

    state = state.copyWith(shouldNavigateToMemories: true);

    // Reset navigation flag
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        state = state.copyWith(shouldNavigateToMemories: false);
      }
    });
  }
}
