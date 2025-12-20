import '../models/create_group_model.dart';
import '../../../core/app_export.dart';

part 'create_group_state.dart';

final createGroupNotifier =
    StateNotifierProvider.autoDispose<CreateGroupNotifier, CreateGroupState>(
  (ref) => CreateGroupNotifier(
    CreateGroupState(
      createGroupModel: CreateGroupModel(),
    ),
  ),
);

class CreateGroupNotifier extends StateNotifier<CreateGroupState> {
  CreateGroupNotifier(CreateGroupState state) : super(state) {
    initialize();
  }

  void initialize() {
    state = state.copyWith(
      groupNameController: TextEditingController(),
      searchController: TextEditingController(),
      isLoading: false,
    );

    // Initialize with sample friends data
    final sampleFriends = [
      FriendModel(
        id: '1',
        name: 'Maxine Bates',
        profileImage: ImageConstant.imgEllipse842x42,
      ),
      FriendModel(
        id: '2',
        name: 'Alex Johnson',
        profileImage: ImageConstant.imgEllipse81,
      ),
      FriendModel(
        id: '3',
        name: 'Sarah Wilson',
        profileImage: ImageConstant.imgEllipse842x42,
      ),
    ];

    // Add Jane Doe as a selected member initially
    final selectedMembers = [
      FriendModel(
        id: '4',
        name: 'Jane Doe',
        profileImage: ImageConstant.imgEllipse81,
      ),
    ];

    state = state.copyWith(
      createGroupModel: state.createGroupModel?.copyWith(
        friendsList: sampleFriends,
        filteredFriends: sampleFriends,
        selectedMembers: selectedMembers,
      ),
    );
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

  void createGroup() {
    state = state.copyWith(isLoading: true);

    // Simulate group creation process
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
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
      }
    });
  }

  @override
  void dispose() {
    state.groupNameController?.dispose();
    state.searchController?.dispose();
    super.dispose();
  }
}
