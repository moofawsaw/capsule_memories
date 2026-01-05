import '../core/app_export.dart';
import '../services/avatar_helper_service.dart';
import '../services/story_service.dart';
import '../services/supabase_service.dart';
import './custom_image_view.dart';
import './custom_memory_skeleton.dart';
import './timeline_widget.dart';

/// CustomPublicMemories - A horizontal scrolling component that displays public memory cards.
/// Loading behavior:
/// - When [isLoading] is true: shows the SAME skeleton loader used in MemoriesDashboardScreen
///   (3x CustomMemorySkeleton).
/// - When loaded: shows real cards. Each card fetches its own timeline stories; while those load,
///   we keep a fixed-height placeholder (no additional skeleton shimmer per card).
class CustomPublicMemories extends StatelessWidget {
  const CustomPublicMemories({
    Key? key,
    this.sectionTitle,
    this.sectionIcon,
    this.memories,
    this.onMemoryTap,
    this.margin,
    this.isLoading = false,
  }) : super(key: key);

  final String? sectionTitle;
  final String? sectionIcon;
  final List<CustomMemoryItem>? memories;
  final Function(CustomMemoryItem)? onMemoryTap;
  final EdgeInsetsGeometry? margin;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.only(top: 30.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sectionTitle != null || sectionIcon != null)
            _buildSectionHeader(),
          if (sectionTitle != null || sectionIcon != null)
            SizedBox(height: 24.h),
          _buildMemoriesScroll(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        CustomImageView(
          imagePath: sectionIcon ?? ImageConstant.imgIcon22x22,
          height: 22.h,
          width: 22.h,
          color: appTheme.deep_purple_A100,
        ),
        SizedBox(width: 8.h),
        Text(
          sectionTitle ?? 'Public Memories',
          style: TextStyleHelper.instance.title16BoldPlusJakartaSans
              .copyWith(color: appTheme.gray_50),
        ),
      ],
    );
  }

  Widget _buildMemoriesScroll(BuildContext context) {
    // SAME SKELETON PATTERN AS MemoriesDashboardScreen
    if (isLoading) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          children: List.generate(3, (index) {
            return Container(
              width: 300.h,
              margin: EdgeInsets.only(right: index == 2 ? 0 : 12.h),
              child: CustomMemorySkeleton(),
            );
          }),
        ),
      );
    }

    final memoryList = memories ?? [];
    if (memoryList.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(memoryList.length, (index) {
          final memory = memoryList[index];
          return Container(
            margin: EdgeInsets.only(
              right: index == memoryList.length - 1 ? 0 : 12.h,
            ),
            child: _PublicMemoryCard(
              memory: memory,
              onTap: () => onMemoryTap?.call(memory),
            ),
          );
        }),
      ),
    );
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

/// Data model for media items in the timeline (kept for compatibility)
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
        memoryStart = DateTime.parse(memoryResponse['start_time'] as String);
        memoryEnd = DateTime.parse(memoryResponse['end_time'] as String);
      } else {
        memoryStart = _parseMemoryStartTime();
        memoryEnd = _parseMemoryEndTime();
      }

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
      // ignore: avoid_print
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
      final day = int.tryParse(parts.length > 1 ? parts[1] : '') ?? now.day;

      final timeParts = timeStr
          .toLowerCase()
          .replaceAll(RegExp(r'[ap]m'), '')
          .trim()
          .split(':');

      var hour = int.tryParse(timeParts[0]) ?? 0;
      final minute =
          timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;

      if (timeStr.toLowerCase().contains('pm') && hour != 12) hour += 12;
      if (timeStr.toLowerCase().contains('am') && hour == 12) hour = 0;

      return DateTime(now.year, month, day, hour, minute);
    } catch (_) {
      return DateTime.now().subtract(const Duration(hours: 2));
    }
  }

  DateTime _parseMemoryEndTime() {
    try {
      final dateStr = widget.memory.endDate ?? 'Dec 4';
      final timeStr = widget.memory.endTime ?? '3:18am';

      final now = DateTime.now();
      final parts = dateStr.split(' ');
      final month = _monthToNumber(parts[0]);
      final day = int.tryParse(parts.length > 1 ? parts[1] : '') ?? now.day;

      final timeParts = timeStr
          .toLowerCase()
          .replaceAll(RegExp(r'[ap]m'), '')
          .trim()
          .split(':');

      var hour = int.tryParse(timeParts[0]) ?? 0;
      final minute =
          timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;

      if (timeStr.toLowerCase().contains('pm') && hour != 12) hour += 12;
      if (timeStr.toLowerCase().contains('am') && hour == 12) hour = 0;

      return DateTime(now.year, month, day, hour, minute);
    } catch (_) {
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
    final key =
        month.toLowerCase().substring(0, month.length >= 3 ? 3 : month.length);
    return months[key] ?? DateTime.now().month;
  }

  Widget _buildMemoryTimeline() {
    // IMPORTANT: no per-card skeleton shimmer (performance). Keep height stable.
    if (_isLoadingTimeline) {
      return SizedBox(
        height: 200.h,
        child: const SizedBox.shrink(),
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

    // USE ONLY THE UNIFIED TIMELINE WIDGET
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.h, vertical: 8.h),
      child: TimelineWidget(
        stories: _timelineStories,
        memoryStartTime: _memoryStartTime!,
        memoryEndTime: _memoryEndTime!,
        onStoryTap: (storyId) {
          if (widget.onTap != null) widget.onTap!();
        },
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
        child: Column(
          children: [
            _buildMemoryHeader(context),
            _buildMemoryTimeline(),
            _buildMemoryFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryHeader(BuildContext context) {
    final memory = widget.memory;

    return Container(
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
          Container(
            height: 36.h,
            width: 36.h,
            decoration: BoxDecoration(
              color: const Color(0xFFC1242F).withAlpha(64),
              borderRadius: BorderRadius.circular(18.h),
            ),
            padding: EdgeInsets.all(6.h),
            child: CustomImageView(
              imagePath: memory.iconPath ?? ImageConstant.imgFrame13Red600,
              height: 24.h,
              width: 24.h,
            ),
          ),
          SizedBox(width: 12.h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memory.title ?? 'Nixon Wedding 2025',
                  style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                ),
                SizedBox(height: 2.h),
                Text(
                  memory.date ?? 'Dec 4, 2025',
                  style: TextStyleHelper.instance.body12MediumPlusJakartaSans,
                ),
              ],
            ),
          ),
          _buildProfileStack(context, memory.profileImages ?? []),
        ],
      ),
    );
  }

  Widget _buildProfileStack(BuildContext context, List<String> profileImages) {
    if (profileImages.isEmpty) return const SizedBox.shrink();

    final count = profileImages.length > 3 ? 3 : profileImages.length;

    return SizedBox(
      width: 84.h,
      height: 36.h,
      child: Stack(
        children: List.generate(count, (index) {
          return Positioned(
            left: (index * 24).h,
            child: Container(
              height: 36.h,
              width: 36.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: appTheme.whiteCustom, width: 1.h),
              ),
              child: ClipOval(
                child: CustomImageView(
                  imagePath: profileImages[index],
                  height: 36.h,
                  width: 36.h,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMemoryFooter(BuildContext context) {
    final memory = widget.memory;

    return Container(
      padding: EdgeInsets.all(12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.h),
          bottomRight: Radius.circular(20.h),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                memory.startDate ?? 'Dec 4',
                style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                    .copyWith(color: appTheme.gray_50),
              ),
              SizedBox(height: 6.h),
              Text(
                memory.startTime ?? '3:18pm',
                style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
            ],
          ),
          if (memory.location != null)
            Column(
              children: [
                Text(
                  memory.location!,
                  style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                      .copyWith(color: appTheme.blue_gray_300),
                ),
                if (memory.distance != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    memory.distance!,
                    style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                        .copyWith(color: appTheme.blue_gray_300),
                  ),
                ],
              ],
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                memory.endDate ?? 'Dec 4',
                style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                    .copyWith(color: appTheme.gray_50),
              ),
              SizedBox(height: 6.h),
              Text(
                memory.endTime ?? '3:18am',
                style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
