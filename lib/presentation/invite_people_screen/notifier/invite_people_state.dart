part of 'invite_people_notifier.dart';

class InvitePeopleState extends Equatable {
  final TextEditingController? searchController;
  final bool? isLoading;
  final bool? isNavigating;
  final String? navigationRoute;
  final InvitePeopleModel? invitePeopleModel;

  InvitePeopleState({
    this.searchController,
    this.isLoading = false,
    this.isNavigating = false,
    this.navigationRoute,
    this.invitePeopleModel,
  });

  @override
  List<Object?> get props => [
        searchController,
        isLoading,
        isNavigating,
        navigationRoute,
        invitePeopleModel,
      ];

  InvitePeopleState copyWith({
    TextEditingController? searchController,
    bool? isLoading,
    bool? isNavigating,
    String? navigationRoute,
    InvitePeopleModel? invitePeopleModel,
  }) {
    return InvitePeopleState(
      searchController: searchController ?? this.searchController,
      isLoading: isLoading ?? this.isLoading,
      isNavigating: isNavigating ?? this.isNavigating,
      navigationRoute: navigationRoute ?? this.navigationRoute,
      invitePeopleModel: invitePeopleModel ?? this.invitePeopleModel,
    );
  }
}
