import '../models/create_memory_model.dart';
import '../../../core/app_export.dart';
import '../../../services/groups_service.dart';

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

  void createMemory() {
    // Set loading state
    state = state.copyWith(isLoading: true);

    // Simulate memory creation
    Future.delayed(Duration(seconds: 1), () {
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
    });
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
