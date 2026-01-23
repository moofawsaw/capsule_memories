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

    _fetchAvailableGroups();
    _fetchAvailableCategories();
  }

  Future<void> initializeWithCategory(String categoryId) async {
    int attempts = 0;
    const maxAttempts = 50;

    while (attempts < maxAttempts) {
      final categories = state.createMemoryModel?.availableCategories ?? [];

      if (categories.isNotEmpty) {
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

      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    print('⚠️ Timeout waiting for categories to load');
  }

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

  String? validateCategory(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select a category';
    }
    return null;
  }

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

  void updateSelectedCategory(String? categoryId) {
    state = state.copyWith(
      createMemoryModel: state.createMemoryModel?.copyWith(
        selectedCategory: categoryId,
      ),
    );
  }

  void moveToStep2() {
    if (state.memoryNameController?.text.trim().isEmpty ?? true) {
      return;
    }

    if (state.createMemoryModel?.selectedCategory == null) {
      state = state.copyWith(
        errorMessage: 'Please select a category for your memory',
      );
      return;
    }

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

  /// ✅ Group selection now auto-populates invitedUserIds from group members.
  Future<void> updateSelectedGroup(String? groupId) async {
    // Clear group
    if (groupId == null) {
      state = state.copyWith(
        createMemoryModel: state.createMemoryModel?.copyWith(
          selectedGroup: null,
          groupMembers: [],
          invitedUserIds: {}, // ✅ clear auto-added members too
        ),
      );
      return;
    }

    // Set selected group, clear while loading
    state = state.copyWith(
      createMemoryModel: state.createMemoryModel?.copyWith(
        selectedGroup: groupId,
        groupMembers: [],
        invitedUserIds: {}, // ✅ reset before loading
      ),
    );

    try {
      final members = await _fetchGroupMembers(groupId);

      // Convert group members -> invitedUserIds set (exclude current user)
      final currentUserId = SupabaseService.instance.client?.auth.currentUser?.id;
      final Set<String> autoInvites = {};

      for (final m in members) {
        final uid = (m['id'] as String?)?.trim(); // GroupsService returns 'id' as profile/user id
        if (uid == null || uid.isEmpty) continue;
        if (currentUserId != null && uid == currentUserId) continue;
        autoInvites.add(uid);
      }

      state = state.copyWith(
        createMemoryModel: state.createMemoryModel?.copyWith(
          selectedGroup: groupId,
          groupMembers: members,
          invitedUserIds: autoInvites, // ✅ key behavior
        ),
      );
    } catch (e) {
      print('Error fetching group members: $e');
      state = state.copyWith(
        createMemoryModel: state.createMemoryModel?.copyWith(
          selectedGroup: groupId,
          groupMembers: [],
          invitedUserIds: {},
        ),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchGroupMembers(String groupId) async {
    try {
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

  void handleQRCodeTap() {}

  Future<void> handleCameraTap() async {
    final context = NavigatorService.navigatorKey.currentContext;
    if (context == null) return;

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => QRScannerOverlay(
            scanType: 'friend',
            onSuccess: () async {},
          ),
        ),
      );
    } catch (e) {
      print('Error opening QR scanner: $e');
    }
  }

  Future<void> createMemory() async {
    print('🎯 Create Memory button pressed');

    final memoryName = state.memoryNameController?.text.trim();
    if (memoryName == null || memoryName.isEmpty) {
      print('❌ Memory name is required');
      return;
    }

    final categoryId = state.createMemoryModel?.selectedCategory;
    if (categoryId == null || categoryId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please select a category',
      );
      return;
    }

    final duration = state.createMemoryModel?.selectedDuration ?? '12_hours';

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final supabase = SupabaseService.instance.client;
      final currentUser = supabase?.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final visibility =
      state.createMemoryModel?.isPublic == true ? 'public' : 'private';

      final selectedGroupId = state.createMemoryModel?.selectedGroup;

      // ✅ If a group is selected, invitedUserIds is already auto-populated in updateSelectedGroup.
      // (Still defensively compute it here in case selection happened without fetch finishing.)
      Set<String> finalInvitedSet =
      Set<String>.from(state.createMemoryModel?.invitedUserIds ?? {});

      if (selectedGroupId != null && selectedGroupId.isNotEmpty) {
        if ((state.createMemoryModel?.groupMembers ?? []).isNotEmpty) {
          finalInvitedSet = {};
          for (final m in state.createMemoryModel!.groupMembers) {
            final uid = (m['id'] as String?)?.trim();
            if (uid == null || uid.isEmpty) continue;
            if (uid == currentUser.id) continue;
            finalInvitedSet.add(uid);
          }
        } else {
          // If groupMembers somehow empty, fetch quickly here
          final members = await _fetchGroupMembers(selectedGroupId);
          finalInvitedSet = {};
          for (final m in members) {
            final uid = (m['id'] as String?)?.trim();
            if (uid == null || uid.isEmpty) continue;
            if (uid == currentUser.id) continue;
            finalInvitedSet.add(uid);
          }
        }
      }

      final invitedUserIds = finalInvitedSet.toList();

      print('📋 Creating memory with:');
      print('   - Title: $memoryName');
      print('   - Category: $categoryId');
      print('   - Duration: $duration');
      print('   - Visibility: $visibility');
      print('   - Group: ${selectedGroupId ?? "none"}');
      print('   - Auto-added users: ${invitedUserIds.length}');

      final memoryId = await _memoryService.createMemory(
        title: memoryName,
        creatorId: currentUser.id,
        visibility: visibility,
        duration: duration,
        categoryId: categoryId,
        invitedUserIds: invitedUserIds,
        groupId: state.createMemoryModel?.selectedGroup, // ✅
      );

      if (memoryId == null) {
        throw Exception('Failed to create memory - service returned null');
      }

      // ✅ Persist group_id on the memory (so MemoryMembersService.fetchMemoryGroupInfo works)
      if (selectedGroupId != null && selectedGroupId.isNotEmpty) {
        try {
          await supabase!
              .from('memories')
              .update({'group_id': selectedGroupId})
              .eq('id', memoryId);
          print('✅ Set memories.group_id = $selectedGroupId');
        } catch (e) {
          print('⚠️ Failed to set group_id on memory: $e');
          // Non-fatal: members are still added via invitedUserIds
        }
      }

      print('✅ Memory created successfully with ID: $memoryId');

      await _cacheService.refreshMemoryCache(currentUser.id);

      state = state.copyWith(
        isLoading: false,
        shouldNavigateToConfirmation: true,
        createdMemoryId: memoryId,
        errorMessage: null,
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          state.memoryNameController?.clear();

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
              invitedUserIds: {},
              groupMembers: [],
              availableGroups:
              state.createMemoryModel?.availableGroups ?? const [],
              availableCategories:
              state.createMemoryModel?.availableCategories ?? const [],
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
    state.memoryNameController?.clear();

    state = state.copyWith(
      shouldNavigateBack: true,
      currentStep: 1,
      createMemoryModel: CreateMemoryModel(
        isPublic: true,
        memoryName: null,
        selectedGroup: null,
        selectedDuration: '12_hours',
        invitedUserIds: {},
        groupMembers: [],
        availableGroups: state.createMemoryModel?.availableGroups ?? const [],
        availableCategories:
        state.createMemoryModel?.availableCategories ?? const [],
      ),
    );

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