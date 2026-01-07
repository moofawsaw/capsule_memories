import '../../../core/app_export.dart';
import '../../../services/groups_service.dart';
import '../../../services/memory_cache_service.dart';
import '../../../services/memory_service.dart';
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
  final _memoryService = MemoryService();

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
      shouldNavigateToConfirmation: false,
      createdMemoryId: null,
      createMemoryModel: CreateMemoryModel(
        isPublic: true,
        memoryName: null,
        selectedGroup: null,
        selectedCategory: null,
        selectedDuration: '12_hours',
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

  /// FIXED: Initialize with pre-selected category - now properly waits for categories to load
  Future<void> initializeWithCategory(String categoryId) async {
    // Wait for categories to be loaded with timeout
    int attempts = 0;
    const maxAttempts = 50; // 50 attempts * 100ms = 5 seconds max wait

    while (attempts < maxAttempts) {
      final categories = state.createMemoryModel?.availableCategories ?? [];

      if (categories.isNotEmpty) {
        // Categories loaded - check if the requested category exists
        final categoryExists = categories.any((cat) => cat['id'] == categoryId);

        if (categoryExists) {
          state = state.copyWith(
            createMemoryModel: state.createMemoryModel?.copyWith(
              selectedCategory: categoryId,
            ),
          );
          print('✅ Category pre-selected: $categoryId');
          return;
        } else {
          print('⚠️ Category $categoryId not found in available categories');
          return;
        }
      }

      // Categories not loaded yet - wait and retry
      await Future.delayed(Duration(milliseconds: 100));
      attempts++;
    }

    print('⚠️ Timeout waiting for categories to load');
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

  /// NEW: Update selected duration
  void updateSelectedDuration(String? duration) {
    state = state.copyWith(
      createMemoryModel: state.createMemoryModel?.copyWith(
        selectedDuration: duration,
      ),
    );
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
    print('🎯 Create Memory button pressed');

    // Validate memory name
    final memoryName = state.memoryNameController?.text.trim();
    if (memoryName == null || memoryName.isEmpty) {
      print('❌ Memory name is required');
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

    print('✅ Form validation passed');

    // Get selected duration
    final duration = state.createMemoryModel?.selectedDuration ?? '12_hours';

    // Set loading state
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Get current user
      final currentUser = SupabaseService.instance.client?.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Determine visibility
      final visibility =
          state.createMemoryModel?.isPublic == true ? 'public' : 'private';

      // Get invited user IDs from state
      final invitedUserIds =
          state.createMemoryModel?.invitedUserIds.toList() ?? [];

      print('📋 Creating memory with:');
      print('   - Title: $memoryName');
      print('   - Category: $categoryId');
      print('   - Duration: $duration');
      print('   - Visibility: $visibility');
      print('   - Invited users: ${invitedUserIds.length}');

      // CRITICAL FIX: Use MemoryService.createMemory instead of direct database insertion
      // This ensures proper location fetching, geocoding, and contributor management
      final memoryId = await _memoryService.createMemory(
        title: memoryName,
        creatorId: currentUser.id,
        visibility: visibility,
        duration: duration,
        categoryId: categoryId,
        invitedUserIds: invitedUserIds,
      );

      if (memoryId == null) {
        throw Exception('Failed to create memory - service returned null');
      }

      print('✅ Memory created successfully with ID: $memoryId');

      // Force refresh cache BEFORE navigation to ensure /memories screen shows new data
      await _cacheService.refreshMemoryCache(currentUser.id);

      // CRITICAL FIX: Store memory data in state variables for navigation
      state = state.copyWith(
        isLoading: false,
        shouldNavigateToConfirmation: true,
        createdMemoryId: memoryId,
        errorMessage: null,
      );

      print('🚀 Set shouldNavigateToConfirmation flag');

      // Clear form and reset after a short delay to allow navigation to complete
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          // Clear form data
          state.memoryNameController?.clear();

          // Reset state to initial values
          state = state.copyWith(
            shouldNavigateToConfirmation: false,
            createdMemoryId: null,
            currentStep: 1,
            createMemoryModel: CreateMemoryModel(
              isPublic: true,
              memoryName: null,
              selectedGroup: null,
              selectedCategory: null,
              selectedDuration: '12_hours',
            ),
          );

          print('✅ Form cleared and state reset');
        }
      });
    } catch (e, stackTrace) {
      print('❌ CREATE MEMORY: Error creating memory: $e');
      print('   Stack trace: $stackTrace');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create memory. Please try again.',
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
        selectedDuration: '12_hours',
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
