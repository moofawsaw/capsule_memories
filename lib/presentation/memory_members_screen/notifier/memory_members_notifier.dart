import '../models/memory_members_model.dart';
import '../../../core/app_export.dart';

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
  MemoryMembersNotifier(MemoryMembersState state) : super(state) {
    initialize();
  }

  void initialize() {
    final members = [
      MemberModel(
        name: 'Joe Dirt',
        profileImagePath: ImageConstant.imgEllipse826x26,
        role: 'Creator',
        status: 'Active',
      ),
      MemberModel(
        name: 'Cassey Campbell',
        profileImagePath: ImageConstant.imgFrame3,
        role: 'Member',
        status: 'Active',
      ),
      MemberModel(
        name: 'Jane Doe',
        profileImagePath: ImageConstant.imgEllipse81,
        role: 'Member',
        status: 'Pending Invite',
      ),
    ];

    state = state.copyWith(
      memoryMembersModel: state.memoryMembersModel?.copyWith(
        members: members,
      ),
    );
  }

  void selectMember(String memberName) {
    state = state.copyWith(
      selectedMemberName: memberName,
    );

    // Navigate to member profile or show member options
    // This can be extended based on requirements
  }

  void removeMember(String memberId) {
    final updatedMembers = state.memoryMembersModel?.members
        ?.where(
          (member) => member.name != memberId,
        )
        .toList();

    state = state.copyWith(
      memoryMembersModel: state.memoryMembersModel?.copyWith(
        members: updatedMembers,
      ),
    );
  }

  void updateMemberRole(String memberName, String newRole) {
    final updatedMembers = state.memoryMembersModel?.members?.map((member) {
      if (member.name == memberName) {
        return member.copyWith(role: newRole);
      }
      return member;
    }).toList();

    state = state.copyWith(
      memoryMembersModel: state.memoryMembersModel?.copyWith(
        members: updatedMembers,
      ),
    );
  }
}
