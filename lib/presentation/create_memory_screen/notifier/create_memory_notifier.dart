import '../models/create_memory_model.dart';
import '../../../core/app_export.dart';
import '../../../services/groups_service.dart';
import '../../../services/story_service.dart';
import '../../../services/memory_cache_service.dart';
import '../../../services/supabase_service.dart';

part 'create_memory_state.dart';

final createMemoryNotifier =
    StateNotifierProvider.autoDispose<CreateMemoryNotifier, CreateMemoryState>(
  (ref) => CreateMemoryNotifier(
    CreateMemoryState(
      createMemoryModel: CreateMemoryModel(),
    ),
  ),
);

class CreateMemoryNotifier extends StateNotifier<CreateMemoryState> {
  final _storyService = StoryService();
  final _cacheService = MemoryCacheService();

  CreateMemoryNotifier(CreateMemoryState state) : super(state) {
    initialize();
  }

  void initialize() {
    state = state.copyWith(
      memoryNameController: TextEditingController(),
      searchController: TextEditingController(),
      isLoading: false,
      currentStep: 1,
      shouldNavigateToInvite: false,
      shouldNavigateBack: false,
      createMemoryModel: CreateMemoryModel(
        isPublic: true,
        memoryName: null,
        selectedGroup: null,
        searchQuery: null,
        searchResults: [],
        invitedUserIds: {},
        groupMembers: [],
        availableGroups: [],
      ),
    );
    // Fetch available groups on initialization
    _fetchAvailableGroups();
  }

  /// Fetch available groups from Supabase
  Future<void> _fetchAvailableGroups() async {
    try {
      final groups = await GroupsService.fetchUserGroups();

      state = state.copyWith(
        createMemoryModel: state.createMemoryModel?.copyWith(
          availableGroups: groups,
        ),
      );
    } catch (e) {
      print('Error fetching groups: $e');
    }
  }

  String? validateMemoryName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Memory name is required';
    }
    if (value.trim().length < 3) {
      return 'Memory name must be at least 3 characters';
    }
    return null;
  }

  void togglePrivacySetting(bool isPublic) {
    state = state.copyWith(
      createMemoryModel: state.createMemoryModel?.copyWith(
        isPublic: isPublic,
      ),
    );
  }

  void moveToStep2() {
    if (state.memoryNameController?.text.trim().isEmpty ?? true) {
      return;
    }

    // Update model with current form data and move to step 2
    state = state.copyWith(
      createMemoryModel: state.createMemoryModel?.copyWith(
        memoryName: state.memoryNameController?.text.trim(),
      ),
      currentStep: 2,
    );
  }

  void backToStep1() {
    state = state.copyWith(
      currentStep: 1,
    );
  }

  Future<void> updateSelectedGroup(String? groupId) async {
    if (groupId == null) {
      state = state.copyWith(
        createMemoryModel: state.createMemoryModel?.copyWith(
          selectedGroup: null,
          groupMembers: [],
        ),
      );
      return;
    }

    // Set loading state
    state = state.copyWith(
      createMemoryModel: state.createMemoryModel?.copyWith(
        selectedGroup: groupId,
        groupMembers: [], // Clear current members while loading
      ),
    );

    try {
      // Fetch group members from Supabase
      final members = await _fetchGroupMembers(groupId);

      state = state.copyWith(
        createMemoryModel: state.createMemoryModel?.copyWith(
          selectedGroup: groupId,
          groupMembers: members,
        ),
      );
    } catch (e) {
      print('Error fetching group members: $e');
      state = state.copyWith(
        createMemoryModel: state.createMemoryModel?.copyWith(
          selectedGroup: groupId,
          groupMembers: [],
        ),
      );
    }
  }

  /// Fetch group members from Supabase
  Future<List<Map<String, dynamic>>> _fetchGroupMembers(String groupId) async {
    try {
      // Use the existing GroupsService.fetchGroupMembers method
      return await GroupsService.fetchGroupMembers(groupId);
    } catch (e) {
      print('Error fetching group members: $e');
      return [];
    }
  }

  void updateSearchQuery(String query) {
    final filteredUsers = state.createMemoryModel
            ?.copyWith(searchQuery: query)
            .getFilteredUsers() ??
        [];

    state = state.copyWith(
      createMemoryModel: state.createMemoryModel?.copyWith(
        searchQuery: query,
        searchResults: filteredUsers,
      ),
    );
  }

  void toggleUserInvite(String userId) {
    final currentInvitedUsers =
        Set<String>.from(state.createMemoryModel?.invitedUserIds ?? {});

    if (currentInvitedUsers.contains(userId)) {
      currentInvitedUsers.remove(userId);
    } else {
      currentInvitedUsers.add(userId);
    }

    state = state.copyWith(
      createMemoryModel: state.createMemoryModel?.copyWith(
        invitedUserIds: currentInvitedUsers,
      ),
    );
  }

  void handleQRCodeTap() {
    // Handle QR code functionality
    // Navigate to QR code screen or show QR scanner
  }

  void handleCameraTap() {
    // Handle camera functionality
    // Open camera or image picker
  }

  Future<void> createMemory() async {
    // Validate memory name
    final memoryName = state.memoryNameController?.text.trim();
    if (memoryName == null || memoryName.isEmpty) {
      print('❌ CREATE MEMORY: Memory name is required');
      return;
    }

    // Set loading state
    state = state.copyWith(isLoading: true);

    try {
      // Get current user
      final currentUser = SupabaseService.instance.client?.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get invited user IDs (from selected group members + manually invited users)
      final Set<String> invitedUserIds = {};

      // Add group members if a group is selected
      if (state.createMemoryModel?.selectedGroup != null) {
        final groupMembers = state.createMemoryModel?.groupMembers ?? [];
        for (final member in groupMembers) {
          final userId = member['id'] as String?;
          if (userId != null && userId != currentUser.id) {
            invitedUserIds.add(userId);
          }
        }
      }

      // Add manually invited users
      final manuallyInvited = state.createMemoryModel?.invitedUserIds ?? {};
      invitedUserIds.addAll(manuallyInvited);

      // Determine visibility
      final visibility =
          state.createMemoryModel?.isPublic == true ? 'public' : 'private';

      // Create memory in database
      final memoryId = await _storyService.createMemory(
        title: memoryName,
        creatorId: currentUser.id,
        visibility: visibility,
        duration: '12_hours', // Default duration
        invitedUserIds: invitedUserIds.toList(),
      );

      if (memoryId == null) {
        throw Exception('Failed to create memory');
      }

      print('✅ CREATE MEMORY: Memory created successfully with ID: $memoryId');

      // Refresh cache to include new memory
      await _cacheService.refreshMemoryCache(currentUser.id);

      // Reset state and close bottom sheet
      state.memoryNameController?.clear();

      state = state.copyWith(
        isLoading: false,
        shouldNavigateBack: true,
        currentStep: 1,
        createMemoryModel: CreateMemoryModel(
          isPublic: true,
          memoryName: null,
          selectedGroup: null,
        ),
      );

      // Reset navigation flag
      Future.delayed(Duration.zero, () {
        state = state.copyWith(shouldNavigateBack: false);
      });
    } catch (e) {
      print('❌ CREATE MEMORY: Error creating memory: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create memory: ${e.toString()}',
      );
    }
  }

  void onCancelPressed() {
    // Clear form data
    state.memoryNameController?.clear();

    state = state.copyWith(
      shouldNavigateBack: true,
      currentStep: 1,
      createMemoryModel: CreateMemoryModel(
        isPublic: true,
        memoryName: null,
        selectedGroup: null,
      ),
    );

    // Reset navigation flag
    Future.delayed(Duration.zero, () {
      state = state.copyWith(shouldNavigateBack: false);
    });
  }

  @override
  void dispose() {
    state.memoryNameController?.dispose();
    state.searchController?.dispose();
    super.dispose();
  }
}
