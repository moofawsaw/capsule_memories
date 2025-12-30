import 'package:flutter/services.dart';

import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';
import '../../../services/avatar_helper_service.dart';
import '../models/memory_details_model.dart';

part 'memory_details_state.dart';

final memoryDetailsNotifier = StateNotifierProvider.autoDispose<
    MemoryDetailsNotifier, MemoryDetailsState>(
  (ref) => MemoryDetailsNotifier(
    MemoryDetailsState(
      memoryDetailsModel: MemoryDetailsModel(),
    ),
  ),
);

class MemoryDetailsNotifier extends StateNotifier<MemoryDetailsState> {
  MemoryDetailsNotifier(MemoryDetailsState state) : super(state);

  /// Load memory data from Supabase
  Future<void> loadMemoryData(String memoryId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final client = SupabaseService.instance.client;
      if (client == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Database connection not available',
        );
        return;
      }

      // Get current user ID
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'User not authenticated',
        );
        return;
      }

      // Fetch memory data with creator info
      final memoryResponse = await client
          .from('memories')
          .select('id, title, invite_code, visibility, creator_id, state')
          .eq('id', memoryId)
          .single();

      // Check if current user is the creator
      final creatorId = memoryResponse['creator_id'] as String;
      final isCreator = creatorId == currentUserId;

      // Fetch memory contributors with user profiles
      final contributorsResponse = await client
          .from('memory_contributors')
          .select(
              'id, user_id, joined_at, user_profiles(id, display_name, username, avatar_url)')
          .eq('memory_id', memoryId);

      // Convert contributors to MemberModel list
      final members = (contributorsResponse as List).map((contributor) {
        final userProfile =
            contributor['user_profiles'] as Map<String, dynamic>;
        final userId = userProfile['id'] as String;

        return MemberModel(
          name: userProfile['display_name'] as String? ??
              userProfile['username'] as String? ??
              'Unknown',
          profileImagePath: AvatarHelperService.getAvatarUrl(
            userProfile['avatar_url'] as String?,
          ),
          role: userId == creatorId ? 'Creator' : 'Member',
          isCreator: userId == creatorId,
        );
      }).toList();

      // Initialize controllers
      final titleController = TextEditingController();
      final inviteLinkController = TextEditingController();

      titleController.text = memoryResponse['title'] as String? ?? '';
      inviteLinkController.text =
          memoryResponse['invite_code'] as String? ?? '';

      state = state.copyWith(
        titleController: titleController,
        inviteLinkController: inviteLinkController,
        isPublic: (memoryResponse['visibility'] as String?) == 'public',
        isCreator: isCreator,
        memoryId: memoryId,
        isLoading: false,
        memoryDetailsModel: state.memoryDetailsModel?.copyWith(
          title: memoryResponse['title'] as String? ?? '',
          inviteLink: memoryResponse['invite_code'] as String? ?? '',
          isPublic: (memoryResponse['visibility'] as String?) == 'public',
          members: members,
        ),
      );
    } catch (e) {
      print('❌ Error loading memory data: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load memory data: ${e.toString()}',
      );
    }
  }

  void updateVisibility(bool isPublic) {
    if (!state.isCreator) return;

    state = state.copyWith(
      isPublic: isPublic,
      memoryDetailsModel: state.memoryDetailsModel?.copyWith(
        isPublic: isPublic,
      ),
    );
  }

  void copyInviteLink() {
    final inviteLink = state.inviteLinkController?.text ?? '';
    if (inviteLink.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: inviteLink));
      state = state.copyWith(
        showSuccessMessage: true,
        successMessage: 'Invite link copied to clipboard',
      );

      // Reset success message after showing
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          state = state.copyWith(
            showSuccessMessage: false,
            successMessage: null,
          );
        }
      });
    }
  }

  void updateTitle(String title) {
    if (!state.isCreator) return;

    state = state.copyWith(
      memoryDetailsModel: state.memoryDetailsModel?.copyWith(
        title: title,
      ),
    );
  }

  Future<void> saveMemory() async {
    if (!state.isCreator) return;

    state = state.copyWith(isSaving: true);

    try {
      final client = SupabaseService.instance.client;
      if (client == null || state.memoryId == null) {
        throw Exception('Database connection not available');
      }

      // Update memory in database
      await client.from('memories').update({
        'title': state.titleController?.text ?? '',
        'visibility': state.isPublic ? 'public' : 'private',
      }).eq('id', state.memoryId!);

      state = state.copyWith(
        isSaving: false,
        showSuccessMessage: true,
        successMessage: 'Memory saved successfully',
      );

      // Reset success message after showing
      Future.delayed(Duration(milliseconds: 2000), () {
        if (mounted) {
          state = state.copyWith(
            showSuccessMessage: false,
            successMessage: null,
          );
        }
      });
    } catch (e) {
      print('❌ Error saving memory: $e');
      state = state.copyWith(
        isSaving: false,
        showSuccessMessage: true,
        successMessage: 'Failed to save memory',
      );
    }
  }

  Future<void> shareMemory() async {
    state = state.copyWith(isSharing: true);

    try {
      // Simulate share operation
      await Future.delayed(Duration(seconds: 1));

      state = state.copyWith(
        isSharing: false,
        showSuccessMessage: true,
        successMessage: 'Memory shared successfully',
      );

      // Reset success message after showing
      Future.delayed(Duration(milliseconds: 2000), () {
        if (mounted) {
          state = state.copyWith(
            showSuccessMessage: false,
            successMessage: null,
          );
        }
      });
    } catch (e) {
      state = state.copyWith(
        isSharing: false,
        showSuccessMessage: true,
        successMessage: 'Failed to share memory',
      );
    }
  }

  @override
  void dispose() {
    state.titleController?.dispose();
    state.inviteLinkController?.dispose();
    super.dispose();
  }
}
