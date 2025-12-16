part of 'create_group_notifier.dart';

class CreateGroupState extends Equatable {
  final TextEditingController? groupNameController;
  final TextEditingController? searchController;
  final bool? isLoading;
  final bool? isSuccess;
  final CreateGroupModel? createGroupModel;

  CreateGroupState({
    this.groupNameController,
    this.searchController,
    this.isLoading = false,
    this.isSuccess = false,
    this.createGroupModel,
  });

  @override
  List<Object?> get props => [
        groupNameController,
        searchController,
        isLoading,
        isSuccess,
        createGroupModel,
      ];

  CreateGroupState copyWith({
    TextEditingController? groupNameController,
    TextEditingController? searchController,
    bool? isLoading,
    bool? isSuccess,
    CreateGroupModel? createGroupModel,
  }) {
    return CreateGroupState(
      groupNameController: groupNameController ?? this.groupNameController,
      searchController: searchController ?? this.searchController,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      createGroupModel: createGroupModel ?? this.createGroupModel,
    );
  }
}
