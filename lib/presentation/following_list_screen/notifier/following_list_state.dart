part of 'following_list_notifier.dart';

/// Represents the state for the following list screen.
// ignore: must_be_immutable
class FollowingListState extends Equatable {
  FollowingListState({
    this.followingListModel,
    this.selectedUser,
    this.isLoading,

    // Search state
    this.searchQuery,
    this.searchResults,
    this.isSearching,
  });

  FollowingListModel? followingListModel;
  FollowingUserModel? selectedUser;
  bool? isLoading;

  String? searchQuery;
  List<FollowingSearchUserModel>? searchResults;
  bool? isSearching;

  @override
  List<Object?> get props => [
    followingListModel,
    selectedUser,
    isLoading,
    searchQuery,
    searchResults,
    isSearching,
  ];

  FollowingListState copyWith({
    FollowingListModel? followingListModel,
    FollowingUserModel? selectedUser,
    bool? isLoading,
    String? searchQuery,
    List<FollowingSearchUserModel>? searchResults,
    bool? isSearching,
  }) {
    return FollowingListState(
      followingListModel: followingListModel ?? this.followingListModel,
      selectedUser: selectedUser ?? this.selectedUser,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}
