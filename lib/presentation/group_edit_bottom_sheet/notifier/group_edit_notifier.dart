import '../../../core/app_export.dart';
import '../../../services/friends_service.dart';
import '../../../services/groups_service.dart';
import '../../groups_management_screen/models/groups_management_model.dart';
import '../models/group_edit_model.dart';

final groupEditNotifier =
    StateNotifierProvider<GroupEditNotifier, GroupEditModel>(
  (ref) => GroupEditNotifier(GroupEditModel()),
);

class GroupEditNotifier extends StateNotifier<GroupEditModel> {
  GroupEditNotifier(GroupEditModel state) : super(state);

  final FriendsService _friendsService = FriendsService();
  List<Map<String, dynamic>> _allFriends = [];

  Future<void> initialize(GroupModel group) async {
    state = state.copyWith(
      groupId: group.id,
      groupName: group.name,
      isLoadingMembers: true,
      isLoadingFriends: true,
    );

    await Future.wait([
      _loadCurrentMembers(),
      _loadAvailableFriends(),
    ]);
  }

  Future<void> _loadCurrentMembers() async {
    try {
      final members = await GroupsService.fetchGroupMembers(state.groupId!);
      state = state.copyWith(
        currentMembers: members,
        isLoadingMembers: false,
      );
    } catch (e) {
      debugPrint('Error loading members: $e');
      state = state.copyWith(
        isLoadingMembers: false,
        error: 'Failed to load members',
      );
    }
  }

  Future<void> _loadAvailableFriends() async {
    try {
      _allFriends = await _friendsService.getUserFriends();

      final currentMemberIds =
          state.currentMembers.map((m) => m['id'] as String).toSet();

      final available = _allFriends
          .where((friend) => !currentMemberIds.contains(friend['id']))
          .toList();

      state = state.copyWith(
        availableFriends: available,
        isLoadingFriends: false,
      );
    } catch (e) {
      debugPrint('Error loading friends: $e');
      state = state.copyWith(
        isLoadingFriends: false,
        error: 'Failed to load friends',
      );
    }
  }

  void updateGroupName(String name) {
    state = state.copyWith(groupName: name);
  }

  void toggleFriendSelection(Map<String, dynamic> friend) {
    final currentSelection = List<Map<String, dynamic>>.from(
      state.selectedFriendsToAdd,
    );

    final isAlreadySelected =
        currentSelection.any((f) => f['id'] == friend['id']);

    if (isAlreadySelected) {
      currentSelection.removeWhere((f) => f['id'] == friend['id']);
    } else {
      currentSelection.add(friend);
    }

    state = state.copyWith(selectedFriendsToAdd: currentSelection);
  }

  void searchFriends(String query) {
    if (query.isEmpty) {
      final currentMemberIds =
          state.currentMembers.map((m) => m['id'] as String).toSet();
      final available = _allFriends
          .where((friend) => !currentMemberIds.contains(friend['id']))
          .toList();
      state = state.copyWith(availableFriends: available);
      return;
    }

    final currentMemberIds =
        state.currentMembers.map((m) => m['id'] as String).toSet();

    final filtered = _allFriends.where((friend) {
      if (currentMemberIds.contains(friend['id'])) return false;

      final displayName =
          (friend['display_name'] as String? ?? '').toLowerCase();
      final username = (friend['username'] as String? ?? '').toLowerCase();
      final searchQuery = query.toLowerCase();

      return displayName.contains(searchQuery) ||
          username.contains(searchQuery);
    }).toList();

    state = state.copyWith(availableFriends: filtered);
  }

  Future<void> removeMember(String memberId) async {
    try {
      final success = await GroupsService.removeGroupMember(
        state.groupId!,
        memberId,
      );

      if (success) {
        final updatedMembers =
            state.currentMembers.where((m) => m['id'] != memberId).toList();

        state = state.copyWith(currentMembers: updatedMembers);

        await _loadAvailableFriends();
      }
    } catch (e) {
      debugPrint('Error removing member: $e');
      state = state.copyWith(error: 'Failed to remove member');
    }
  }

  Future<bool> saveChanges(String newGroupName) async {
    if (newGroupName.trim().isEmpty) {
      state = state.copyWith(error: 'Group name cannot be empty');
      return false;
    }

    state = state.copyWith(isSaving: true);

    try {
      bool success = true;

      if (newGroupName.trim() != state.groupName?.trim()) {
        success = await GroupsService.updateGroupName(
          state.groupId!,
          newGroupName.trim(),
        );
      }

      if (success && state.selectedFriendsToAdd.isNotEmpty) {
        for (final friend in state.selectedFriendsToAdd) {
          final addSuccess = await GroupsService.addGroupMember(
            state.groupId!,
            friend['id'] as String,
          );
          if (!addSuccess) {
            success = false;
            break;
          }
        }
      }

      state = state.copyWith(isSaving: false);

      return success;
    } catch (e) {
      debugPrint('Error saving changes: $e');
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to save changes',
      );
      return false;
    }
  }

  void setLoading(bool loading) {
    state = state.copyWith(isSaving: loading);
  }
}