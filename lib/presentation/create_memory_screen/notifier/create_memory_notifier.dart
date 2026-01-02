import '../../../core/app_export.dart';
import '../../../services/groups_service.dart';
import '../../../services/memory_cache_service.dart';
import '../../../services/story_service.dart';
import '../../../services/supabase_service.dart';
import '../../friends_management_screen/widgets/qr_scanner_overlay.dart';
import '../models/create_memory_model.dart';

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
        selectedCategory: null,
        searchQuery: null,
        searchResults: [],
        invitedUserIds: {},
        groupMembers: [],
        availableGroups: [],
        availableCategories: [],
      ),
    );
    // Fetch available groups and categories on initialization
    _fetchAvailableGroups();
    _fetchAvailableCategories();
  }

  /// NEW: Initialize with pre-selected category
  void initializeWithCategory(String categoryId) {
    // Wait for categories to be loaded before setting selection
    Future.delayed(Duration(milliseconds: 100), () {
      final categories = state.createMemoryModel?.availableCategories ?? [];
      final categoryExists = categories.any((cat) => cat['id'] == categoryId);

      if (categoryExists) {
        state = state.copyWith(
          createMemoryModel: state.createMemoryModel?.copyWith(
            selectedCategory: categoryId,
          ),
        );
      }
    });
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

  /// NEW: Fetch available categories from Supabase
  Future<void> _fetchAvailableCategories() async {
    try {
      final supabase = SupabaseService.instance.client;
      if (supabase == null) return;

      final response = await supabase
          .from('memory_categories')
          .select('id, name, tagline, icon_name, icon_url')
          .eq('is_active', true)
          .order('display_order', ascending: true);

      final categories = (response as List)
          .map<Map<String, dynamic>>((category) => {
                'id': category['id'] as String,
                'name': category['name'] as String,
                'tagline': category['tagline'] as String?,
                'icon_name': category['icon_name'] as String?,
                'icon_url': category['icon_url'] as String?,
              })
          .toList();

      state = state.copyWith(
        createMemoryModel: state.createMemoryModel?.copyWith(
          availableCategories: categories,
        ),
      );
    } catch (e) {
      print('Error fetching categories: $e');
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

  /// NEW: Validate category selection
  String? validateCategory(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select a category';
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

  /// NEW: Update selected category
  void updateSelectedCategory(String? categoryId) {
    state = state.copyWith(
      createMemoryModel: state.createMemoryModel?.copyWith(
        selectedCategory: categoryId,
      ),
    );
  }

  void moveToStep2() {
    // Validate memory name
    if (state.memoryNameController?.text.trim().isEmpty ?? true) {
      return;
    }

    // Validate category selection
    if (state.createMemoryModel?.selectedCategory == null) {
      state = state.copyWith(
        errorMessage: 'Please select a category for your memory',
      );
      return;
    }

    // Update model with current form data and move to step 2
    state = state.copyWith(
      createMemoryModel: state.createMemoryModel?.copyWith(
        memoryName: state.memoryNameController?.text.trim(),
      ),
      currentStep: 2,
      errorMessage: null,
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

  Future<void> handleCameraTap() async {
    // Open QR scanner to add users via friend QR code scanning
    final context = NavigatorService.navigatorKey.currentContext;
    if (context == null) return;

    try {
      // Use existing QRScannerOverlay instead of custom scanner
      await Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => QRScannerOverlay(
            scanType: 'friend',
            onSuccess: () async {
              // QR scanner returns after successful scan
              // We'll get the scanned user from the service
              // Refresh invites or show success
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('User added to memory invites!'),
                  backgroundColor: appTheme.deep_purple_A100,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      print('Error opening QR scanner: $e');
    }
  }

  Future<void> createMemory() async {
    // Validate memory name
    final memoryName = state.memoryNameController?.text.trim();
    if (memoryName == null || memoryName.isEmpty) {
      print('❌ CREATE MEMORY: Memory name is required');
      return;
    }

    // Validate category selection
    final categoryId = state.createMemoryModel?.selectedCategory;
    if (categoryId == null || categoryId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please select a category',
      );
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

      // Helper function to validate UUID format
      bool isValidUUID(String? value) {
        if (value == null || value.isEmpty) return false;
        final uuidRegex = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          caseSensitive: false,
        );
        return uuidRegex.hasMatch(value);
      }

      // Add group members if a group is selected
      if (state.createMemoryModel?.selectedGroup != null) {
        final groupMembers = state.createMemoryModel?.groupMembers ?? [];
        for (final member in groupMembers) {
          final userId = member['id'] as String?;
          // Only add valid UUIDs and exclude current user
          if (userId != null &&
              userId != currentUser.id &&
              isValidUUID(userId)) {
            invitedUserIds.add(userId);
          }
        }
      }

      // Add manually invited users (filter out invalid UUIDs like mock user IDs)
      final manuallyInvited = state.createMemoryModel?.invitedUserIds ?? {};
      for (final userId in manuallyInvited) {
        if (isValidUUID(userId) && userId != currentUser.id) {
          invitedUserIds.add(userId);
        }
      }

      // Determine visibility
      final visibility =
          state.createMemoryModel?.isPublic == true ? 'public' : 'private';

      // Create memory in database with category_id
      final memoryId = await _storyService.createMemory(
        title: memoryName,
        creatorId: currentUser.id,
        visibility: visibility,
        duration: '12_hours', // Default duration
        categoryId: categoryId, // Pass category ID
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
          selectedCategory: null,
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
