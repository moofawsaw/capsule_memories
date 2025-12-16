import '../models/memory_details_view_model.dart';
import '../../../core/app_export.dart';

part 'memory_details_view_state.dart';

final memoryDetailsViewNotifier = StateNotifierProvider.autoDispose<
    MemoryDetailsViewNotifier, MemoryDetailsViewState>(
  (ref) => MemoryDetailsViewNotifier(
    MemoryDetailsViewState(
      memoryDetailsViewModel: MemoryDetailsViewModel(),
    ),
  ),
);

class MemoryDetailsViewNotifier extends StateNotifier<MemoryDetailsViewState> {
  MemoryDetailsViewNotifier(MemoryDetailsViewState state) : super(state) {
    initialize();
  }

  void initialize() {
    state = state.copyWith(
      isLoading: false,
      memoryDetailsViewModel: MemoryDetailsViewModel(
        memoryTitle: 'Boyz Golf Trip',
        memoryDate: 'Sept 21, 2025',
        isPublic: true,
        participantImages: [
          ImageConstant.imgFrame2,
          ImageConstant.imgFrame1,
          ImageConstant.imgEllipse81,
        ],
        timelineEntries: [
          TimelineEntryModel(
            date: 'Dec 4',
            time: '3:18pm',
            location: 'Tillsonburg, ON',
            distance: '21km',
          ),
          TimelineEntryModel(
            date: 'Dec 4',
            time: '3:18am',
            location: 'Tillsonburg, ON',
            distance: '21km',
          ),
        ],
        storyItems: [
          StoryItemModel(
            backgroundImage: ImageConstant.imgImage8202x116,
            profileImage: ImageConstant.imgFrame2,
            timestamp: '2 mins ago',
          ),
          StoryItemModel(
            backgroundImage: ImageConstant.imgImage8120x90,
            profileImage: ImageConstant.imgFrame1,
            timestamp: '2 mins ago',
          ),
          StoryItemModel(
            backgroundImage: ImageConstant.imgImage8,
            profileImage: ImageConstant.imgFrame48x48,
            timestamp: '2 mins ago',
          ),
          StoryItemModel(
            backgroundImage: ImageConstant.imgImg,
            profileImage: ImageConstant.imgEllipse842x42,
            timestamp: '2 mins ago',
          ),
          StoryItemModel(
            backgroundImage: ImageConstant.imgImage81,
            profileImage: ImageConstant.imgEllipse81,
            timestamp: '2 mins ago',
          ),
        ],
        isMemorySealed: true,
        sealedDate: 'Dec 4, 2025',
        storiesCount: 6,
      ),
    );
  }

  void onAddContentTap() {
    state = state.copyWith(isLoading: true);

    // Navigate to add memory upload screen
    // NavigatorService.pushNamed(AppRoutes.addMemoryUploadScreen);

    state = state.copyWith(isLoading: false);
  }

  void onEventOptionsTap() {
    state = state.copyWith(
      showEventOptions: true,
    );
  }

  void onReplayAllTap() {
    state = state.copyWith(isLoading: true);

    // Navigate to event stories view screen
    // NavigatorService.pushNamed(AppRoutes.eventStoriesViewScreen);

    state = state.copyWith(
      isLoading: false,
      isReplayingAll: true,
    );
  }

  void onAddMediaTap() {
    state = state.copyWith(isLoading: true);

    // Navigate to add memory upload screen
    // NavigatorService.pushNamed(AppRoutes.addMemoryUploadScreen);

    state = state.copyWith(isLoading: false);
  }

  void onStoryTap(int index) {
    state = state.copyWith(
      selectedStoryIndex: index,
    );

    // Navigate to video call screen or story viewer
    // NavigatorService.pushNamed(AppRoutes.videoCallScreen);
  }

  void onProfileTap() {
    // Navigate to user profile screen
    // NavigatorService.pushNamed(AppRoutes.userProfileScreen);
  }

  void onNotificationTap() {
    // Navigate to notifications screen
    // NavigatorService.pushNamed(AppRoutes.notificationsScreen);
  }
}
