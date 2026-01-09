import '../../core/app_export.dart';
import '../../core/utils/memory_nav_args.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_event_card.dart';
import '../../widgets/custom_story_list.dart';
import '../../widgets/timeline_widget.dart';
import '../add_memory_upload_screen/add_memory_upload_screen.dart';
import '../memory_members_screen/memory_members_screen.dart';
import 'notifier/memory_details_view_notifier.dart';

class MemoryDetailsViewScreen extends ConsumerStatefulWidget {
  MemoryDetailsViewScreen({Key? key}) : super(key: key);

  @override
  MemoryDetailsViewScreenState createState() => MemoryDetailsViewScreenState();
}

class MemoryDetailsViewScreenState
    extends ConsumerState<MemoryDetailsViewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use same navigation contract as timeline screen
      final rawArgs = ModalRoute.of(context)?.settings.arguments;

      print('🚨 SEALED SCREEN: Processing navigation arguments');
      print('   - Raw type: ${rawArgs.runtimeType}');

      MemoryNavArgs? navArgs;

      if (rawArgs is MemoryNavArgs) {
        navArgs = rawArgs;
        print('✅ SEALED SCREEN: Received typed MemoryNavArgs');
      } else if (rawArgs is Map<String, dynamic>) {
        navArgs = MemoryNavArgs.fromMap(rawArgs);
        print('✅ SEALED SCREEN: Converted Map to MemoryNavArgs');
      } else {
        print(
            '❌ SEALED SCREEN: Invalid argument type - expected MemoryNavArgs or Map');
      }

      // Validate arguments
      if (navArgs == null || !navArgs.isValid) {
        print('❌ SEALED SCREEN: Missing or invalid memory ID');
        ref.read(memoryDetailsViewNotifier.notifier).setErrorState(
              'Unable to load memory. Invalid navigation arguments.',
            );
        return;
      }

      print('✅ SEALED SCREEN: Valid MemoryNavArgs received');
      print('   - Memory ID: ${navArgs.memoryId}');
      print('   - Has snapshot: ${navArgs.snapshot != null}');

      // Initialize with same approach as timeline
      ref
          .read(memoryDetailsViewNotifier.notifier)
          .initializeFromMemory(navArgs);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryDetailsViewNotifier);

        // Show error UI if navigation failed
        if (state.errorMessage != null) {
          return Container(
            color: appTheme.gray_900_02,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64.h,
                      color: appTheme.red_500,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Failed to Load Memory',
                      style: TextStyleHelper.instance.body16BoldPlusJakartaSans
                          .copyWith(color: appTheme.gray_50),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      state.errorMessage!,
                      style: TextStyleHelper
                          .instance.body14MediumPlusJakartaSans
                          .copyWith(color: appTheme.gray_300),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24.h),
                    CustomButton(
                      text: 'Go Back',
                      width: double.infinity,
                      buttonStyle: CustomButtonStyle.fillPrimary,
                      buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                      onPressed: () {
                        NavigatorService.goBack();
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Show loading state
        if (state.isLoading ?? false) {
          return Container(
            color: appTheme.gray_900_02,
            child: Center(
              child: CircularProgressIndicator(
                color: appTheme.deep_purple_A100,
              ),
            ),
          );
        }

        // Display content with dynamic data
        return Container(
          color: appTheme.gray_900_02,
          child: SingleChildScrollView(
              child: Column(
            children: [
              SizedBox(height: 18.h),
              _buildEventCard(context),
              _buildTimelineSection(context),
              SizedBox(height: 20.h),
              _buildStoriesSection(context),
              SizedBox(height: 19.h),
              _buildStoriesList(context),
              SizedBox(height: 23.h),
              _buildActionButtons(context),
              _buildFooterMessage(context),
              SizedBox(height: 24.h),
            ],
          )),
        );
      },
    );
  }

  /// Section Widget
  Widget _buildEventCard(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryDetailsViewNotifier);

        return CustomEventCard(
          eventTitle: state.memoryDetailsViewModel?.eventTitle,
          eventDate: state.memoryDetailsViewModel?.eventDate,
          eventLocation: state.memoryDetailsViewModel?.eventLocation,
          isPrivate: state.memoryDetailsViewModel?.isPrivate,
          iconButtonImagePath: state.memoryDetailsViewModel?.categoryIcon ??
              ImageConstant.imgFrame13,
          participantImages: state.memoryDetailsViewModel?.participantImages,
          onBackTap: () {
            NavigatorService.goBack();
          },
          onIconButtonTap: () {
            ref.read(memoryDetailsViewNotifier.notifier).onEventOptionsTap();
          },
          onAvatarTap: () {
            onTapAvatars(context);
          },
        );
      },
    );
  }

  /// Section Widget
  Widget _buildTimelineSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryDetailsViewNotifier);
        final timelineDetail = state.memoryDetailsViewModel?.timelineDetail;

        // Fix null safety: Check isEmpty with proper null handling
        if (timelineDetail == null ||
            (timelineDetail.timelineStories?.isEmpty ?? true)) {
          return SizedBox.shrink();
        }

        // Additional validation for required DateTime fields
        if (timelineDetail.memoryStartTime == null ||
            timelineDetail.memoryEndTime == null) {
          return SizedBox.shrink();
        }

        // Convert TimelineStoryItem types with proper typing
        final List<TimelineStoryItem> convertedStories =
            timelineDetail.timelineStories!
                .map((story) => TimelineStoryItem(
                      backgroundImage: story.backgroundImage,
                      userAvatar: story.userAvatar,
                      postedAt: story.postedAt,
                      timeLabel: story.timeLabel,
                      storyId: story.storyId,
                    ))
                .toList();

        return Container(
          child: Stack(
            children: [
              Container(
                width: double.maxFinite,
                padding: EdgeInsets.symmetric(horizontal: 16.h),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: appTheme.blue_gray_900,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    _buildStoryProgress(context),
                    SizedBox(height: 44.h),
                    TimelineWidget(
                      stories: convertedStories,
                      memoryStartTime: timelineDetail.memoryStartTime!,
                      memoryEndTime: timelineDetail.memoryEndTime!,
                      variant: TimelineVariant.sealed,
                      onStoryTap: (storyId) =>
                          _handleTimelineStoryTap(context, storyId),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Section Widget
  Widget _buildStoryProgress(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryDetailsViewNotifier);

        return SizedBox();
      },
    );
  }

  /// Section Widget
  Widget _buildStoriesSection(BuildContext context) {
    return Container(
      width: double.maxFinite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(left: 20.h),
            child: Consumer(
              builder: (context, ref, _) {
                final state = ref.watch(memoryDetailsViewNotifier);
                final storyCount =
                    state.memoryDetailsViewModel?.customStoryItems?.length ?? 0;

                return Text(
                  'Stories ($storyCount)',
                  style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                );
              },
            ),
          ),
          SizedBox(height: 18.h),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildStoriesList(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryDetailsViewNotifier);
        // Add cast to List<CustomStoryItem>
        final storyItems =
            (state.memoryDetailsViewModel?.customStoryItems ?? [])
                .cast<CustomStoryItem>();

        if (storyItems.isEmpty) {
          return Container(
            margin: EdgeInsets.only(left: 20.h),
            padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.h),
            decoration: BoxDecoration(
              color: appTheme.gray_900_03,
              borderRadius: BorderRadius.circular(12.h),
            ),
            child: Center(
              child: Text(
                'No stories yet',
                style: TextStyleHelper.instance.body14MediumPlusJakartaSans
                    .copyWith(color: appTheme.gray_300),
              ),
            ),
          );
        }

        return CustomStoryList(
          storyItems: storyItems,
          onStoryTap: (index) {
            onTapStoryItem(context, index);
          },
          itemGap: 8.h,
          margin: EdgeInsets.only(left: 20.h),
        );
      },
    );
  }

  /// Section Widget
  Widget _buildActionButtons(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 22.h),
      child: Row(
        spacing: 18.h,
        children: [
          Expanded(
            child: CustomButton(
              text: 'Replay All',
              leftIcon: ImageConstant.imgIcon12,
              onPressed: () {
                ref.read(memoryDetailsViewNotifier.notifier).onReplayAllTap();
              },
              buttonStyle: CustomButtonStyle.fillPrimary,
              buttonTextStyle: CustomButtonTextStyle.bodyMedium,
            ),
          ),
          Expanded(
            child: CustomButton(
              text: 'Add Media',
              leftIcon: ImageConstant.imgIcon13,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: AddMemoryUploadScreen(),
                  ),
                );
              },
              buttonStyle: CustomButtonStyle.fillPrimary,
              buttonTextStyle: CustomButtonTextStyle.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildFooterMessage(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 33.h, vertical: 14.h),
      child: Text(
        'You can still add photos and videos you captured during the memory window',
        textAlign: TextAlign.center,
        style: TextStyleHelper.instance.body14RegularPlusJakartaSans
            .copyWith(color: appTheme.blue_gray_300, height: 1.21),
      ),
    );
  }

  void _handleTimelineStoryTap(BuildContext context, String storyId) {
    final notifier = ref.read(memoryDetailsViewNotifier.notifier);

    NavigatorService.pushNamed(
      AppRoutes.appStoryView,
      arguments: storyId,
    );
  }

  void onTapStoryItem(BuildContext context, int index) {
    final notifier = ref.read(memoryDetailsViewNotifier.notifier);
    final state = ref.read(memoryDetailsViewNotifier);
    final storyItems = state.memoryDetailsViewModel?.customStoryItems ?? [];

    if (index < storyItems.length) {
      final storyItem = storyItems[index];

      NavigatorService.pushNamed(
        AppRoutes.appStoryView,
        arguments: storyItem.storyId ?? '',
      );
    }
  }

  void onTapAvatars(BuildContext context) {
    final state = ref.read(memoryDetailsViewNotifier);
    final memoryId = state.memoryDetailsViewModel?.memoryId;
    final memoryTitle = state.memoryDetailsViewModel?.eventTitle;

    if (memoryId != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => MemoryMembersScreen(
          memoryId: memoryId,
          memoryTitle: memoryTitle,
        ),
      );
    }
  }
}
