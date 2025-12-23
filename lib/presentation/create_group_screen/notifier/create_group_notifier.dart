import '../models/create_group_model.dart';
import '../../../core/app_export.dart';
import '../../../services/friends_service.dart';
import '../../../services/groups_service.dart';
import '../../groups_management_screen/notifier/groups_management_notifier.dart';

part 'create_group_state.dart';

final createGroupNotifier =
    StateNotifierProvider.autoDispose<CreateGroupNotifier, CreateGroupState>(
  (ref) => CreateGroupNotifier(
    CreateGroupState(
      createGroupModel: CreateGroupModel(),
    ),
    ref,
  ),
);

class CreateGroupNotifier extends StateNotifier<CreateGroupState> {
  final FriendsService _friendsService = FriendsService();
  final Ref _ref;

  CreateGroupNotifier(CreateGroupState state, this._ref) : super(state) {
    initialize();
  }

  void initialize() async {
    state = state.copyWith(
      groupNameController: TextEditingController(),
      searchController: TextEditingController(),
      isLoading: true,
    );

    // Fetch actual friends from Supabase
    await fetchFriends();
  }

  Future<void> fetchFriends() async {
    try {
      state = state.copyWith(isLoading: true);

      final friendsData = await _friendsService.getUserFriends();

      final friends = friendsData
          .map((friend) => FriendModel(
                id: friend['id'] as String,
                name: friend['display_name'] as String? ??
                    friend['username'] as String,
                profileImage: friend['avatar_url'] as String? ?? '',
              ))
          .toList();

      state = state.copyWith(
        createGroupModel: state.createGroupModel?.copyWith(
          friendsList: friends,
          filteredFriends: friends,
          selectedMembers: [],
        ),
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error fetching friends: $e');
      state = state.copyWith(
        isLoading: false,
        createGroupModel: state.createGroupModel?.copyWith(
          friendsList: [],
          filteredFriends: [],
        ),
      );
    }
  }

  void searchFriends(String query) {
    if (query.isEmpty) {
      state = state.copyWith(
        createGroupModel: state.createGroupModel?.copyWith(
          filteredFriends: state.createGroupModel?.friendsList ?? [],
        ),
      );
    } else {
      final filtered = state.createGroupModel?.friendsList?.where((friend) {
            return friend.name?.toLowerCase().contains(query.toLowerCase()) ??
                false;
          }).toList() ??
          [];

      state = state.copyWith(
        createGroupModel: state.createGroupModel?.copyWith(
          filteredFriends: filtered,
        ),
      );
    }
  }

  void addMember(FriendModel friend) {
    final currentMembers =
        List<FriendModel>.from(state.createGroupModel?.selectedMembers ?? []);

    if (!currentMembers.any((member) => member.id == friend.id)) {
      currentMembers.add(friend);

      state = state.copyWith(
        createGroupModel: state.createGroupModel?.copyWith(
          selectedMembers: currentMembers,
        ),
      );
    }
  }

  void removeMember(FriendModel friend) {
    final currentMembers =
        List<FriendModel>.from(state.createGroupModel?.selectedMembers ?? []);
    currentMembers.removeWhere((member) => member.id == friend.id);

    state = state.copyWith(
      createGroupModel: state.createGroupModel?.copyWith(
        selectedMembers: currentMembers,
      ),
    );
  }

  Future<void> createGroup() async {
    try {
      state = state.copyWith(isLoading: true);

      final groupName = state.groupNameController?.text.trim();
      if (groupName == null || groupName.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      // Create the group
      final groupId = await GroupsService.createGroup(groupName);

      if (groupId == null) {
        throw Exception('Failed to create group');
      }

      // Add selected members to the group
      final selectedMembers = state.createGroupModel?.selectedMembers ?? [];
      for (final member in selectedMembers) {
        await GroupsService.addGroupMember(groupId, member.id!);
      }

      // Clear form after successful creation
      state.groupNameController?.clear();
      state.searchController?.clear();

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        createGroupModel: state.createGroupModel?.copyWith(
          selectedMembers: [],
        ),
      );

      // Invalidate groups management to trigger real-time refresh
      _ref.invalidate(groupsManagementNotifier);
    } catch (e) {
      debugPrint('Error creating group: $e');
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
      );
    }
  }

  @override
  void dispose() {
    state.groupNameController?.dispose();
    state.searchController?.dispose();
    super.dispose();
  }
}
