import '../models/memories_dashboard_model.dart';
import '../models/memory_item_model.dart';
import '../models/story_item_model.dart';
import '../../../core/app_export.dart';

part 'memories_dashboard_state.dart';

final memoriesDashboardNotifier = StateNotifierProvider.autoDispose<
    MemoriesDashboardNotifier, MemoriesDashboardState>(
  (ref) => MemoriesDashboardNotifier(
    MemoriesDashboardState(
      memoriesDashboardModel: MemoriesDashboardModel(),
    ),
  ),
);

class MemoriesDashboardNotifier extends StateNotifier<MemoriesDashboardState> {
  MemoriesDashboardNotifier(MemoriesDashboardState state) : super(state) {
    initialize();
  }

  void initialize() {
    _initializeStoryItems();
    _initializeMemoryItems();

    state = state.copyWith(
      isLoading: false,
      selectedTabIndex: 0,
    );
  }

  void _initializeStoryItems() {
    final storyItems = [
      StoryItemModel(
        backgroundImage: ImageConstant.imgImage8202x116,
        profileImage: ImageConstant.imgFrame2,
        timestamp: '2 mins ago',
        navigateTo: '1398:6774',
      ),
      StoryItemModel(
        backgroundImage: ImageConstant.imgImage8120x90,
        profileImage: ImageConstant.imgFrame1,
        timestamp: '2 mins ago',
        navigateTo: '1398:6774',
      ),
      StoryItemModel(
        backgroundImage: ImageConstant.imgImage8,
        profileImage: ImageConstant.imgFrame48x48,
        timestamp: '2 mins ago',
        navigateTo: '1398:6774',
      ),
      StoryItemModel(
        backgroundImage: ImageConstant.imgImg,
        profileImage: ImageConstant.imgEllipse842x42,
        timestamp: '2 mins ago',
        navigateTo: '1398:6774',
      ),
      StoryItemModel(
        backgroundImage: ImageConstant.imgImage81,
        profileImage: ImageConstant.imgEllipse81,
        timestamp: '2 mins ago',
        navigateTo: '1398:6774',
      ),
    ];

    state = state.copyWith(
      memoriesDashboardModel: state.memoriesDashboardModel?.copyWith(
        storyItems: storyItems,
      ),
    );
  }

  void _initializeMemoryItems() {
    final memoryItems = [
      MemoryItemModel(
        title: 'Nixon Wedding 2025',
        date: 'Dec 4, 2025',
        eventDate: 'Dec 4',
        eventTime: '3:18pm',
        endDate: 'Dec 4',
        endTime: '3:18am',
        location: 'Tillsonburg, ON',
        distance: '21km',
        participantAvatars: [
          ImageConstant.imgFrame2,
          ImageConstant.imgFrame1,
          ImageConstant.imgEllipse81,
        ],
        memoryThumbnails: [
          ImageConstant.imgImage9,
          ImageConstant.imgImage8,
        ],
        isLive: true,
      ),
      MemoryItemModel(
        title: 'Family Reunion 2024',
        date: 'Dec 1, 2024',
        eventDate: 'Dec 1',
        eventTime: '2:30pm',
        endDate: 'Dec 1',
        endTime: '11:45pm',
        location: 'Toronto, ON',
        distance: '45km',
        participantAvatars: [
          ImageConstant.imgFrame2,
          ImageConstant.imgFrame1,
          ImageConstant.imgEllipse81,
        ],
        memoryThumbnails: [
          ImageConstant.imgImage9,
          ImageConstant.imgImage8,
        ],
        isSealed: true,
      ),
    ];

    final liveMemories =
        memoryItems.where((item) => item.isLive ?? false).toList();
    final sealedMemories =
        memoryItems.where((item) => item.isSealed ?? false).toList();

    state = state.copyWith(
      memoriesDashboardModel: state.memoriesDashboardModel?.copyWith(
        memoryItems: memoryItems,
        liveMemoryItems: liveMemories,
        sealedMemoryItems: sealedMemories,
        allCount: memoryItems.length,
        liveCount: liveMemories.length,
        sealedCount: sealedMemories.length,
      ),
    );
  }

  void updateSelectedTabIndex(int index) {
    state = state.copyWith(selectedTabIndex: index);
  }

  void loadAllStories() {
    state = state.copyWith(isLoading: true);

    // Simulate loading more stories
    Future.delayed(Duration(milliseconds: 500), () {
      final currentStories = state.memoriesDashboardModel?.storyItems ?? [];
      final additionalStories = [
        StoryItemModel(
          backgroundImage: ImageConstant.imgImage8202x116,
          profileImage: ImageConstant.imgFrame2,
          timestamp: '5 mins ago',
          navigateTo: '1398:6774',
        ),
        StoryItemModel(
          backgroundImage: ImageConstant.imgImage8120x90,
          profileImage: ImageConstant.imgFrame1,
          timestamp: '8 mins ago',
          navigateTo: '1398:6774',
        ),
      ];

      final updatedStories = [...currentStories, ...additionalStories];

      state = state.copyWith(
        memoriesDashboardModel: state.memoriesDashboardModel?.copyWith(
          storyItems: updatedStories,
        ),
        isLoading: false,
        isSuccess: true,
      );
    });
  }

  void createNewMemory() {
    state = state.copyWith(isLoading: true);

    Future.delayed(Duration(milliseconds: 800), () {
      final newMemory = MemoryItemModel(
        title: 'New Year Celebration 2025',
        date: 'Dec 31, 2024',
        eventDate: 'Dec 31',
        eventTime: '11:30pm',
        endDate: 'Jan 1',
        endTime: '2:00am',
        location: 'Downtown, ON',
        distance: '12km',
        participantAvatars: [
          ImageConstant.imgFrame2,
          ImageConstant.imgFrame1,
        ],
        memoryThumbnails: [
          ImageConstant.imgImage9,
        ],
        isLive: true,
      );

      final currentMemories = state.memoriesDashboardModel?.memoryItems ?? [];
      final updatedMemories = [newMemory, ...currentMemories];

      final liveMemories =
          updatedMemories.where((item) => item.isLive ?? false).toList();
      final sealedMemories =
          updatedMemories.where((item) => item.isSealed ?? false).toList();

      state = state.copyWith(
        memoriesDashboardModel: state.memoriesDashboardModel?.copyWith(
          memoryItems: updatedMemories,
          liveMemoryItems: liveMemories,
          sealedMemoryItems: sealedMemories,
          allCount: updatedMemories.length,
          liveCount: liveMemories.length,
          sealedCount: sealedMemories.length,
        ),
        isLoading: false,
        isSuccess: true,
      );
    });
  }

  void refreshMemories() {
    state = state.copyWith(isLoading: true);

    Future.delayed(Duration(milliseconds: 1000), () {
      initialize();

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
      );
    });
  }
}
