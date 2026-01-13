part of 'memory_details_notifier.dart';

@immutable
class MemoryDetailsState {
  final MemoryDetailsModel? memoryDetailsModel;
  final TextEditingController? titleController;
  final TextEditingController? inviteLinkController;
  final TextEditingController? searchController;
  final TextEditingController? locationController;

  final bool isLoading;
  final bool isSaving;
  final bool isSharing;
  final bool isCreator;
  final bool isPublic;

  final bool isFetchingLocation;
  final bool isLoadingFriends;
  final bool isInviting;
  final bool isLoadingCategories;

  final String? memoryId;
  final String? errorMessage;

  final bool? showSuccessMessage;
  final String? successMessage;

  final String? locationName;
  final double? locationLat;
  final double? locationLng;

  final String? selectedCategoryId;
  final String? selectedCategoryName;

  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> friendsList;
  final List<Map<String, dynamic>> filteredFriendsList;
  final Set<String> memberUserIds;

  final String? selectedDuration; // '12_hours', '24_hours', '3_days'
  final DateTime? startTime;
  final DateTime? endTime;

  /// ✅ NEW: memory state from DB ('open' / 'sealed')
  final String? memoryState;

  const MemoryDetailsState({
    this.memoryDetailsModel,
    this.titleController,
    this.inviteLinkController,
    this.searchController,
    this.locationController,
    this.isLoading = false,
    this.isSaving = false,
    this.isSharing = false,
    this.isCreator = false,
    this.isPublic = false,
    this.isFetchingLocation = false,
    this.isLoadingFriends = false,
    this.isInviting = false,
    this.isLoadingCategories = false,
    this.memoryId,
    this.errorMessage,
    this.showSuccessMessage,
    this.successMessage,
    this.locationName,
    this.locationLat,
    this.locationLng,
    this.selectedCategoryId,
    this.selectedCategoryName,
    this.categories = const [],
    this.friendsList = const [],
    this.filteredFriendsList = const [],
    this.memberUserIds = const {},
    this.selectedDuration,
    this.startTime,
    this.endTime,
    this.memoryState,
  });

  /// ✅ Computed: locked if sealed
  bool get isSealed => (memoryState ?? '').toLowerCase().trim() == 'sealed';

  MemoryDetailsState copyWith({
    MemoryDetailsModel? memoryDetailsModel,
    TextEditingController? titleController,
    TextEditingController? inviteLinkController,
    TextEditingController? searchController,
    TextEditingController? locationController,
    bool? isLoading,
    bool? isSaving,
    bool? isSharing,
    bool? isCreator,
    bool? isPublic,
    bool? isFetchingLocation,
    bool? isLoadingFriends,
    bool? isInviting,
    bool? isLoadingCategories,
    String? memoryId,
    String? errorMessage,
    bool? showSuccessMessage,
    String? successMessage,
    String? locationName,
    double? locationLat,
    double? locationLng,
    String? selectedCategoryId,
    String? selectedCategoryName,
    List<Map<String, dynamic>>? categories,
    List<Map<String, dynamic>>? friendsList,
    List<Map<String, dynamic>>? filteredFriendsList,
    Set<String>? memberUserIds,
    String? selectedDuration,
    DateTime? startTime,
    DateTime? endTime,
    String? memoryState,
  }) {
    return MemoryDetailsState(
      memoryDetailsModel: memoryDetailsModel ?? this.memoryDetailsModel,
      titleController: titleController ?? this.titleController,
      inviteLinkController: inviteLinkController ?? this.inviteLinkController,
      searchController: searchController ?? this.searchController,
      locationController: locationController ?? this.locationController,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isSharing: isSharing ?? this.isSharing,
      isCreator: isCreator ?? this.isCreator,
      isPublic: isPublic ?? this.isPublic,
      isFetchingLocation: isFetchingLocation ?? this.isFetchingLocation,
      isLoadingFriends: isLoadingFriends ?? this.isLoadingFriends,
      isInviting: isInviting ?? this.isInviting,
      isLoadingCategories: isLoadingCategories ?? this.isLoadingCategories,
      memoryId: memoryId ?? this.memoryId,
      errorMessage: errorMessage,
      showSuccessMessage: showSuccessMessage,
      successMessage: successMessage,
      locationName: locationName ?? this.locationName,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      selectedCategoryName: selectedCategoryName ?? this.selectedCategoryName,
      categories: categories ?? this.categories,
      friendsList: friendsList ?? this.friendsList,
      filteredFriendsList: filteredFriendsList ?? this.filteredFriendsList,
      memberUserIds: memberUserIds ?? this.memberUserIds,
      selectedDuration: selectedDuration ?? this.selectedDuration,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      memoryState: memoryState ?? this.memoryState,
    );
  }
}
