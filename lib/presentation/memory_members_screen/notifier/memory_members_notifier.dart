import '../models/memory_members_model.dart';
import '../../../core/app_export.dart';
import '../../../services/memory_members_service.dart';

part 'memory_members_state.dart';

final memoryMembersNotifier = StateNotifierProvider.autoDispose<
    MemoryMembersNotifier, MemoryMembersState>(
  (ref) => MemoryMembersNotifier(
    MemoryMembersState(
      memoryMembersModel: MemoryMembersModel(),
    ),
  ),
);

class MemoryMembersNotifier extends StateNotifier<MemoryMembersState> {
  final MemoryMembersService _membersService = MemoryMembersService();

  MemoryMembersNotifier(MemoryMembersState state) : super(state);

  /// Initialize with memory ID to fetch actual members from database
  Future<void> initialize(String memoryId, {String? memoryTitle}) async {
    // Set loading state
    state = state.copyWith(
      memoryMembersModel: state.memoryMembersModel?.copyWith(
        memoryId: memoryId,
        memoryTitle: memoryTitle ?? 'Memory',
        isLoading: true,
        errorMessage: null,
      ),
    );

    try {
      // Fetch all members (creator + contributors)
      final membersData = await _membersService.fetchAllMemoryMembers(memoryId);

      // Fetch group information if memory was created from a group
      final groupInfo = await _membersService.fetchMemoryGroupInfo(memoryId);

      // Convert to MemberModel objects
      final members = membersData.map((data) {
        return MemberModel(
          userId: data['user_id'] as String? ?? '',
          displayName: data['display_name'] as String? ?? 'Unknown',
          username: data['username'] as String? ?? '',
          avatarUrl: data['avatar_url'] as String? ?? '',
          isCreator: data['is_creator'] as bool? ?? false,
          isVerified: data['is_verified'] as bool? ?? false,
          joinedAt: data['joined_at'] as String?,
        );
      }).toList();

      // Update state with fetched members and group info
      state = state.copyWith(
        memoryMembersModel: state.memoryMembersModel?.copyWith(
          members: members,
          groupId: groupInfo?['group_id'] as String?,
          groupName: groupInfo?['group_name'] as String?,
          isLoading: false,
          errorMessage: null,
        ),
      );
    } catch (e) {
      // Handle error
      state = state.copyWith(
        memoryMembersModel: state.memoryMembersModel?.copyWith(
          members: [],
          isLoading: false,
          errorMessage: 'Failed to load members',
        ),
      );
      print('Error loading memory members: $e');
    }
  }

  void selectMember(String memberId) {
    state = state.copyWith(
      selectedMemberId: memberId,
    );
    // Navigate to member profile or show member options
  }
}
