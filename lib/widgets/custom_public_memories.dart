import '../core/app_export.dart';
import '../presentation/event_timeline_view_screen/widgets/timeline_story_widget.dart';
import '../services/avatar_helper_service.dart';
import '../services/story_service.dart';
import '../services/supabase_service.dart';
import './custom_image_view.dart';
import './custom_memory_skeleton.dart';

/**
 * CustomPublicMemories - A horizontal scrolling component that displays public memory cards
 * with rich visual content including profile images, media previews, and timeline information.
 * 
 * Features:
 * - Section header with icon and title
 * - Horizontally scrollable memory cards
 * - Profile image stacks with overlapping circular images
 * - Media timeline with preview images and play buttons
 * - Timestamp and location information
 * - Responsive design with SizeUtils extensions
 */
class CustomPublicMemories extends StatelessWidget {
  CustomPublicMemories({
    Key? key,
    this.sectionTitle,
    this.sectionIcon,
    this.memories,
    this.onMemoryTap,
    this.margin,
    this.isLoading = false, // ADD THIS PARAMETER
  }) : super(key: key);

  /// Title text for the section header
  final String? sectionTitle;

  /// Icon path for the section header
  final String? sectionIcon;

  /// List of memory data to display
  final List<CustomMemoryItem>? memories;

  /// Callback when a memory card is tapped
  final Function(CustomMemoryItem)? onMemoryTap;

  /// Margin around the entire component
  final EdgeInsetsGeometry? margin;

  /// Loading state indicator
  final bool isLoading; // ADD THIS PROPERTY

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: margin ?? EdgeInsets.only(top: 30.h, left: 24.h),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Only show section header if sectionTitle or sectionIcon is provided
          if (sectionTitle != null || sectionIcon != null)
            _buildSectionHeader(context),
          if (sectionTitle != null || sectionIcon != null)
            SizedBox(height: 24.h),
          _buildMemoriesScroll(context),
        ]));
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Row(children: [
      CustomImageView(
          imagePath: sectionIcon ?? ImageConstant.imgIcon22x22,
          height: 22.h,
          width: 22.h,
          color: appTheme.deep_purple_A100),
      SizedBox(width: 8.h),
      Text(sectionTitle ?? 'Public Memories',
          style: TextStyleHelper.instance.title16BoldPlusJakartaSans
              .copyWith(color: appTheme.gray_50)),
    ]);
  }

  Widget _buildMemoriesScroll(BuildContext context) {
    // SHOW SKELETON LOADERS DURING INITIAL LOAD
    if (isLoading) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(3, (index) {
            return Container(
              width: 300.h,
              margin: EdgeInsets.only(right: index == 2 ? 0 : 12.h),
              child: _buildSkeletonCard(context),
            );
          }),
        ),
      );
    }

    final memoryList = memories ?? [];

    if (memoryList.isEmpty) {
      return SizedBox.shrink();
    }

    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
            children: List.generate(memoryList.length, (index) {
          final memory = memoryList[index];
          return Container(
              margin: EdgeInsets.only(
                  right: index == memoryList.length - 1 ? 0 : 12.h),
              child: _buildMemoryCard(context, memory));
        })));
  }

  // ADD NEW METHOD: Build skeleton card for loading state
  Widget _buildSkeletonCard(BuildContext context) {
    return Container(
      width: 300.h,
      decoration: BoxDecoration(
        color: appTheme.gray_900_01,
        borderRadius: BorderRadius.circular(20.h),
      ),
      child: Column(
        children: [
          // Skeleton header
          Container(
            padding: EdgeInsets.all(18.h),
            decoration: BoxDecoration(
              color: appTheme.background_transparent,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.h),
                topRight: Radius.circular(20.h),
              ),
            ),
            child: Row(
              children: [
                // Skeleton icon
                Container(
                  height: 36.h,
                  width: 36.h,
                  decoration: BoxDecoration(
                    color: appTheme.blue_gray_300.withAlpha(51),
                    borderRadius: BorderRadius.circular(18.h),
                  ),
                ),
                SizedBox(width: 12.h),
                // Skeleton text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16.h,
                        width: 140.h,
                        decoration: BoxDecoration(
                          color: appTheme.blue_gray_300.withAlpha(51),
                          borderRadius: BorderRadius.circular(4.h),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        height: 12.h,
                        width: 80.h,
                        decoration: BoxDecoration(
                          color: appTheme.blue_gray_300.withAlpha(51),
                          borderRadius: BorderRadius.circular(4.h),
                        ),
                      ),
                    ],
                  ),
                ),
                // Skeleton profile images
                SizedBox(
                  width: 84.h,
                  height: 36.h,
                  child: Stack(
                    children: List.generate(3, (index) {
                      return Positioned(
                        left: (index * 24).h,
                        child: Container(
                          height: 36.h,
                          width: 36.h,
                          decoration: BoxDecoration(
                            color: appTheme.blue_gray_300.withAlpha(51),
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          // Skeleton timeline
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4.h, vertical: 8.h),
            height: 112.h,
            child: CustomMemorySkeleton(),
          ),
          // Skeleton footer
          Container(
            padding: EdgeInsets.all(12.h),
            decoration: BoxDecoration(
              color: appTheme.gray_900_01,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20.h),
                bottomRight: Radius.circular(20.h),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSkeletonFooterColumn(),
                _buildSkeletonFooterColumn(),
                _buildSkeletonFooterColumn(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for skeleton footer columns
  Widget _buildSkeletonFooterColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 14.h,
          width: 50.h,
          decoration: BoxDecoration(
            color: appTheme.blue_gray_300.withAlpha(51),
            borderRadius: BorderRadius.circular(4.h),
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          height: 12.h,
          width: 40.h,
          decoration: BoxDecoration(
            color: appTheme.blue_gray_300.withAlpha(51),
            borderRadius: BorderRadius.circular(4.h),
          ),
        ),
      ],
    );
  }

  Widget _buildMemoryCard(BuildContext context, CustomMemoryItem memory) {
    return _PublicMemoryCard(
      memory: memory,
      onTap: () => onMemoryTap?.call(memory),
    );
  }

  Widget _buildMemoryHeader(BuildContext context, CustomMemoryItem memory) {
    return Container(
        padding: EdgeInsets.all(18.h),
        decoration: BoxDecoration(
          color: appTheme.background_transparent,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.h),
            topRight: Radius.circular(20.h),
          ),
        ),
        child: Row(children: [
          Container(
              height: 36.h,
              width: 36.h,
              decoration: BoxDecoration(
                  color: Color(0xFFC1242F).withAlpha(64),
                  borderRadius: BorderRadius.circular(18.h)),
              padding: EdgeInsets.all(6.h),
              child: CustomImageView(
                  imagePath: memory.iconPath ?? ImageConstant.imgFrame13Red600,
                  height: 24.h,
                  width: 24.h)),
          SizedBox(width: 12.h),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(memory.title ?? 'Nixon Wedding 2025',
                    style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                        .copyWith(color: appTheme.gray_50)),
                SizedBox(height: 2.h),
                Text(memory.date ?? 'Dec 4, 2025',
                    style:
                        TextStyleHelper.instance.body12MediumPlusJakartaSans),
              ])),
          _buildProfileStack(context, memory.profileImages ?? []),
        ]));
  }

  Widget _buildProfileStack(BuildContext context, List<String> profileImages) {
    if (profileImages.isEmpty) {
      return SizedBox.shrink();
    }

    return SizedBox(
        width: 84.h,
        height: 36.h,
        child: Stack(
            children: List.generate(
                profileImages.length > 3 ? 3 : profileImages.length, (index) {
          return Positioned(
              left: (index * 24).h,
              child: Container(
                  height: 36.h,
                  width: 36.h,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: appTheme.whiteCustom, width: 1.h)),
                  child: ClipOval(
                      child: CustomImageView(
                          imagePath: profileImages[index],
                          height: 36.h,
                          width: 36.h,
                          fit: BoxFit.cover))));
        })));
  }

  Widget _buildMediaPreview(BuildContext context, CustomMediaItem item) {
    return Container(
        margin: EdgeInsets.only(left: 6.h),
        child: Stack(children: [
          Container(
              height: 56.h,
              width: 40.h,
              decoration: BoxDecoration(
                  color: appTheme.gray_900_01,
                  borderRadius: BorderRadius.circular(6.h),
                  border:
                      Border.all(color: appTheme.deep_purple_A200, width: 1.h)),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(6.h),
                  child: CustomImageView(
                      imagePath: item.imagePath ?? '',
                      height: 56.h,
                      width: 40.h,
                      fit: BoxFit.cover))),
          if (item.hasPlayButton == true)
            Positioned(
                top: 4.h,
                left: 4.h,
                child: Container(
                    height: 16.h,
                    width: 16.h,
                    decoration: BoxDecoration(
                        color: Color(0xFFD81E29).withAlpha(59),
                        borderRadius: BorderRadius.circular(8.h)),
                    child: Center(
                        child: CustomImageView(
                            imagePath: ImageConstant.imgPlayCircle,
                            height: 12.h,
                            width: 12.h)))),
        ]));
  }

  Widget _buildMemoryFooter(BuildContext context, CustomMemoryItem memory) {
    return Container(
        padding: EdgeInsets.all(12.h),
        decoration: BoxDecoration(
          color: appTheme.gray_900_01,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20.h),
            bottomRight: Radius.circular(20.h),
          ),
        ),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(memory.startDate ?? 'Dec 4',
                style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                    .copyWith(color: appTheme.gray_50)),
            SizedBox(height: 6.h),
            Text(memory.startTime ?? '3:18pm',
                style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300)),
          ]),
          if (memory.location != null)
            Column(children: [
              Text(memory.location!,
                  style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                      .copyWith(color: appTheme.blue_gray_300)),
              if (memory.distance != null) ...[
                SizedBox(height: 4.h),
                Text(memory.distance!,
                    style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                        .copyWith(color: appTheme.blue_gray_300)),
              ],
            ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(memory.endDate ?? 'Dec 4',
                style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                    .copyWith(color: appTheme.gray_50)),
            SizedBox(height: 6.h),
            Text(memory.endTime ?? '3:18am',
                style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300)),
          ]),
        ]));
  }
}

/// Data model for memory items
class CustomMemoryItem {
  CustomMemoryItem({
    this.id,
    this.title,
    this.date,
    this.iconPath,
    this.profileImages,
    this.mediaItems,
    this.startDate,
    this.startTime,
    this.endDate,
    this.endTime,
    this.location,
    this.distance,
    this.isLiked,
  });

  final String? id;
  final String? title;
  final String? date;
  final String? iconPath;
  final List<String>? profileImages;
  final List<CustomMediaItem>? mediaItems;
  final String? startDate;
  final String? startTime;
  final String? endDate;
  final String? endTime;
  final String? location;
  final String? distance;
  final bool? isLiked;
}

/// Data model for media items in the timeline
class CustomMediaItem {
  CustomMediaItem({
    this.imagePath,
    this.hasPlayButton = false,
  });

  final String? imagePath;
  final bool hasPlayButton;
}

/// Stateful widget for individual public memory card that fetches stories
class _PublicMemoryCard extends StatefulWidget {
  final CustomMemoryItem memory;
  final VoidCallback? onTap;

  const _PublicMemoryCard({
    Key? key,
    required this.memory,
    this.onTap,
  }) : super(key: key);

  @override
  State<_PublicMemoryCard> createState() => _PublicMemoryCardState();
}

class _PublicMemoryCardState extends State<_PublicMemoryCard> {
  final _storyService = StoryService();
  List<TimelineStoryItem> _timelineStories = [];
  DateTime? _memoryStartTime;
  DateTime? _memoryEndTime;
  bool _isLoadingTimeline = true;

  @override
  void initState() {
    super.initState();
    _loadTimelineData();
  }

  Future<void> _loadTimelineData() async {
    if (widget.memory.id == null || widget.memory.id!.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoadingTimeline = false;
        _timelineStories = [];
      });
      return;
    }

    try {
      final memoryId = widget.memory.id!;

      // Fetch memory's start_time and end_time from database (same as timeline detail screen)
      final memoryResponse = await SupabaseService.instance.client
          ?.from('memories')
          .select('start_time, end_time')
          .eq('id', memoryId)
          .single();

      DateTime memoryStart;
      DateTime memoryEnd;

      if (memoryResponse != null &&
          memoryResponse['start_time'] != null &&
          memoryResponse['end_time'] != null) {
        // Use actual event window from database (same as timeline detail screen)
        memoryStart = DateTime.parse(memoryResponse['start_time'] as String);
        memoryEnd = DateTime.parse(memoryResponse['end_time'] as String);
      } else {
        // Fallback: parse from string dates if database columns not available
        memoryStart = _parseMemoryStartTime();
        memoryEnd = _parseMemoryEndTime();
      }

      // Fetch stories from database using memory ID
      final storiesData = await _storyService.fetchMemoryStories(memoryId);

      if (!mounted) return;

      if (storiesData.isEmpty) {
        setState(() {
          _isLoadingTimeline = false;
          _timelineStories = [];
          _memoryStartTime = memoryStart;
          _memoryEndTime = memoryEnd;
        });
        return;
      }

      // Convert stories to TimelineStoryItem format
      final timelineStories = storiesData.map((storyData) {
        final contributor = storyData['user_profiles'] as Map<String, dynamic>?;
        final createdAt = DateTime.parse(storyData['created_at'] as String);
        final storyId = storyData['id'] as String;

        final backgroundImage = _storyService.getStoryMediaUrl(storyData);
        final profileImage = AvatarHelperService.getAvatarUrl(
          contributor?['avatar_url'] as String?,
        );

        return TimelineStoryItem(
          backgroundImage: backgroundImage,
          userAvatar: profileImage,
          postedAt: createdAt,
          timeLabel: _storyService.getTimeAgo(createdAt),
          storyId: storyId,
        );
      }).toList();

      if (!mounted) return;

      setState(() {
        _timelineStories = timelineStories;
        _memoryStartTime = memoryStart;
        _memoryEndTime = memoryEnd;
        _isLoadingTimeline = false;
      });
    } catch (e) {
      print('❌ PUBLIC MEMORY CARD: Error loading timeline: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingTimeline = false;
        _timelineStories = [];
      });
    }
  }

  DateTime _parseMemoryStartTime() {
    try {
      final dateStr = widget.memory.startDate ?? 'Dec 4';
      final timeStr = widget.memory.startTime ?? '3:18pm';

      final now = DateTime.now();
      final parts = dateStr.split(' ');
      final month = _monthToNumber(parts[0]);
      final day = int.tryParse(parts[1]) ?? now.day;

      final timeParts =
          timeStr.toLowerCase().replaceAll(RegExp(r'[ap]m'), '').split(':');
      var hour = int.tryParse(timeParts[0]) ?? 0;
      final minute =
          timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;

      if (timeStr.toLowerCase().contains('pm') && hour != 12) hour += 12;
      if (timeStr.toLowerCase().contains('am') && hour == 12) hour = 0;

      return DateTime(now.year, month, day, hour, minute);
    } catch (e) {
      return DateTime.now().subtract(Duration(hours: 2));
    }
  }

  DateTime _parseMemoryEndTime() {
    try {
      final dateStr = widget.memory.endDate ?? 'Dec 4';
      final timeStr = widget.memory.endTime ?? '3:18am';

      final now = DateTime.now();
      final parts = dateStr.split(' ');
      final month = _monthToNumber(parts[0]);
      final day = int.tryParse(parts[1]) ?? now.day;

      final timeParts =
          timeStr.toLowerCase().replaceAll(RegExp(r'[ap]m'), '').split(':');
      var hour = int.tryParse(timeParts[0]) ?? 0;
      final minute =
          timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;

      if (timeStr.toLowerCase().contains('pm') && hour != 12) hour += 12;
      if (timeStr.toLowerCase().contains('am') && hour == 12) hour = 0;

      return DateTime(now.year, month, day, hour, minute);
    } catch (e) {
      return DateTime.now();
    }
  }

  int _monthToNumber(String month) {
    const months = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };
    return months[month.toLowerCase().substring(0, 3)] ?? DateTime.now().month;
  }

  Widget _buildMemoryTimeline() {
    if (_isLoadingTimeline) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 4.h, vertical: 8.h),
        height: 112.h,
        child: CustomMemorySkeleton(),
      );
    }

    if (_timelineStories.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 4.h, vertical: 8.h),
        height: 112.h,
        child: Center(
          child: Text(
            'No stories yet',
            style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                .copyWith(color: appTheme.blue_gray_300),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 0,
        vertical: 26,
      ),
      margin: EdgeInsets.symmetric(horizontal: 4.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _timelineStories.map((story) {
            return Padding(
              padding: EdgeInsets.only(right: 8.h),
              child: TimelineStoryWidget(
                item: story,
                onTap: () {
                  // Navigate to full memory when timeline card is tapped
                  if (widget.onTap != null) {
                    widget.onTap!();
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 300.h,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.h)),
        child: Column(children: [
          _buildMemoryHeader(context, widget.memory),
          _buildMemoryTimeline(),
          _buildMemoryFooter(context, widget.memory),
        ]),
      ),
    );
  }

  Widget _buildMemoryHeader(BuildContext context, CustomMemoryItem memory) {
    return Container(
        padding: EdgeInsets.all(18.h),
        decoration: BoxDecoration(
          color: appTheme.background_transparent,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.h),
            topRight: Radius.circular(20.h),
          ),
        ),
        child: Row(children: [
          Container(
              height: 36.h,
              width: 36.h,
              decoration: BoxDecoration(
                  color: Color(0xFFC1242F).withAlpha(64),
                  borderRadius: BorderRadius.circular(18.h)),
              padding: EdgeInsets.all(6.h),
              child: CustomImageView(
                  imagePath: memory.iconPath ?? ImageConstant.imgFrame13Red600,
                  height: 24.h,
                  width: 24.h)),
          SizedBox(width: 12.h),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(memory.title ?? 'Nixon Wedding 2025',
                    style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                        .copyWith(color: appTheme.gray_50)),
                SizedBox(height: 2.h),
                Text(memory.date ?? 'Dec 4, 2025',
                    style:
                        TextStyleHelper.instance.body12MediumPlusJakartaSans),
              ])),
          _buildProfileStack(context, memory.profileImages ?? []),
        ]));
  }

  Widget _buildProfileStack(BuildContext context, List<String> profileImages) {
    if (profileImages.isEmpty) {
      return SizedBox.shrink();
    }

    return SizedBox(
        width: 84.h,
        height: 36.h,
        child: Stack(
            children: List.generate(
                profileImages.length > 3 ? 3 : profileImages.length, (index) {
          return Positioned(
              left: (index * 24).h,
              child: Container(
                  height: 36.h,
                  width: 36.h,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: appTheme.whiteCustom, width: 0)),
                  child: ClipOval(
                      child: CustomImageView(
                          imagePath: profileImages[index],
                          height: 36.h,
                          width: 36.h,
                          fit: BoxFit.cover))));
        })));
  }

  Widget _buildMemoryFooter(BuildContext context, CustomMemoryItem memory) {
    return Container(
        padding: EdgeInsets.all(12.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20.h),
            bottomRight: Radius.circular(20.h),
          ),
        ),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(memory.startDate ?? 'Dec 4',
                style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                    .copyWith(color: appTheme.gray_50)),
            SizedBox(height: 6.h),
            Text(memory.startTime ?? '3:18pm',
                style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300)),
          ]),
          if (memory.location != null)
            Column(children: [
              Text(memory.location!,
                  style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                      .copyWith(color: appTheme.blue_gray_300)),
              if (memory.distance != null) ...[
                SizedBox(height: 4.h),
                Text(memory.distance!,
                    style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                        .copyWith(color: appTheme.blue_gray_300)),
              ],
            ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(memory.endDate ?? 'Dec 4',
                style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                    .copyWith(color: appTheme.gray_50)),
            SizedBox(height: 6.h),
            Text(memory.endTime ?? '3:18am',
                style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300)),
          ]),
        ]));
  }
}
