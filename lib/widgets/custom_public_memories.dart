import '../core/app_export.dart';
import '../services/avatar_helper_service.dart';
import '../services/memory_members_service.dart';
import '../services/story_service.dart';
import '../services/supabase_service.dart';
import './custom_button.dart';
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
    // ✅ ADD horizontal padding to section header (like story feeds)
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.h),
      child: Row(
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
      ),
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
              // ✅ ADD left padding to first card, right padding to all
              margin: EdgeInsets.only(
                left: index == 0 ? 24.h : 0,
                right: 12.h,
              ),
              child: CustomMemorySkeleton(),
            );
          }),
        ),
      );
    }

    final List<CustomMemoryItem> memoryList = memories ?? <CustomMemoryItem>[];

    // ✅ EMPTY STATE: Add horizontal padding
    if (memoryList.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.h),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomImageView(
                  imagePath: sectionIcon ?? ImageConstant.imgIcon22x22,
                  height: 48.h,
                  width: 48.h,
                  color: appTheme.blue_gray_300,
                ),
                SizedBox(height: 12.h),
                Text(
                  'No memories yet',
                  style: TextStyleHelper.instance.title16MediumPlusJakartaSans
                      .copyWith(color: appTheme.blue_gray_300),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Create your first memory',
                  style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                      .copyWith(color: appTheme.blue_gray_300),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ✅ FIX: Add padding to FIRST card only (like story feeds)
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(memoryList.length, (index) {
          final CustomMemoryItem memory = memoryList[index];
          return Container(
            margin: EdgeInsets.only(
              left: index == 0 ? 24.h : 0, // ✅ First card gets left padding
              right: 12.h,
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
  final StoryService _storyService = StoryService();
  final MemoryMembersService _membersService = MemoryMembersService();

  List<TimelineStoryItem> _timelineStories = <TimelineStoryItem>[];
  DateTime? _memoryStartTime;
  DateTime? _memoryEndTime;
  bool _isLoadingTimeline = true;
  bool _isUserCreatedMemory = false;
  int _memberCount = 0;

  // Parent-card horizontal padding applied around the timeline area
  // (this is what keeps markers away from card edges).
  static const double _timelineSidePadding = 14.0;

  @override
  void initState() {
    super.initState();
    _checkMemoryOwnership();
    _loadTimelineData();
    _fetchMemberCount();
  }

  // Check if current user is the creator of this memory
  Future<void> _checkMemoryOwnership() async {
    try {
      final currentUser = SupabaseService.instance.client?.auth.currentUser;
      if (currentUser == null || widget.memory.id == null) {
        setState(() => _isUserCreatedMemory = false);
        return;
      }

      final dynamic memoryResponse = await SupabaseService.instance.client
          ?.from('memories')
          .select('user_id')
          .eq('id', widget.memory.id!)
          .single();

      if (memoryResponse != null && mounted) {
        setState(() {
          _isUserCreatedMemory = memoryResponse['user_id'] == currentUser.id;
        });
      }
    } catch (e) {
      print('❌ Error checking memory ownership: $e');
      if (mounted) {
        setState(() => _isUserCreatedMemory = false);
      }
    }
  }

  // Fetch count of members (excluding creator)
  Future<void> _fetchMemberCount() async {
    if (widget.memory.id == null || widget.memory.id!.isEmpty) {
      if (mounted) setState(() => _memberCount = 0);
      return;
    }

    try {
      final members =
          await _membersService.fetchMemoryMembers(widget.memory.id!);
      if (mounted) {
        setState(() => _memberCount = members.length);
      }
    } catch (e) {
      print('❌ Error fetching member count: $e');
      if (mounted) setState(() => _memberCount = 0);
    }
  }

  // ✅ CRITICAL FIX: Reload timeline when memory ID changes
  @override
  void didUpdateWidget(covariant _PublicMemoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only reload if the memory ID actually changed
    if (oldWidget.memory.id != widget.memory.id) {
      setState(() {
        _isLoadingTimeline = true;
        _timelineStories = [];
      });
      _loadTimelineData();
    }
  }

  Future<void> _loadTimelineData() async {
    if (widget.memory.id == null || widget.memory.id!.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoadingTimeline = false;
        _timelineStories = <TimelineStoryItem>[];
      });
      return;
    }

    try {
      final String memoryId = widget.memory.id!;

      final dynamic memoryResponse = await SupabaseService.instance.client
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

      final List<dynamic> storiesData =
          await _storyService.fetchMemoryStories(memoryId);

      if (!mounted) return;

      if (storiesData.isEmpty) {
        setState(() {
          _isLoadingTimeline = false;
          _timelineStories = <TimelineStoryItem>[];
          _memoryStartTime = memoryStart;
          _memoryEndTime = memoryEnd;
        });
        return;
      }

      final List<TimelineStoryItem> timelineStories =
          storiesData.map<TimelineStoryItem>((dynamic storyData) {
        final Map<String, dynamic>? contributor =
            storyData['user_profiles'] as Map<String, dynamic>?;

        final DateTime createdAt =
            DateTime.parse(storyData['created_at'] as String);
        final String storyId = storyData['id'] as String;

        final String backgroundImage =
            _storyService.getStoryMediaUrl(storyData);

        final String? avatarUrl =
            contributor != null ? contributor['avatar_url'] as String? : null;

        final String profileImage = AvatarHelperService.getAvatarUrl(avatarUrl);

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
        _timelineStories = <TimelineStoryItem>[];
      });
    }
  }

  DateTime _parseMemoryStartTime() {
    try {
      final String dateStr = widget.memory.startDate ?? 'Dec 4';
      final String timeStr = widget.memory.startTime ?? '3:18pm';

      final DateTime now = DateTime.now();
      final List<String> parts = dateStr.split(' ');
      final int month = _monthToNumber(parts[0]);
      final int day = int.tryParse(parts.length > 1 ? parts[1] : '') ?? now.day;

      final List<String> timeParts = timeStr
          .toLowerCase()
          .replaceAll(RegExp(r'[ap]m'), '')
          .trim()
          .split(':');

      int hour = int.tryParse(timeParts[0]) ?? 0;
      final int minute =
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
      final String dateStr = widget.memory.endDate ?? 'Dec 4';
      final String timeStr = widget.memory.endTime ?? '3:18am';

      final DateTime now = DateTime.now();
      final List<String> parts = dateStr.split(' ');
      final int month = _monthToNumber(parts[0]);
      final int day = int.tryParse(parts.length > 1 ? parts[1] : '') ?? now.day;

      final List<String> timeParts = timeStr
          .toLowerCase()
          .replaceAll(RegExp(r'[ap]m'), '')
          .trim()
          .split(':');

      int hour = int.tryParse(timeParts[0]) ?? 0;
      final int minute =
          timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;

      if (timeStr.toLowerCase().contains('pm') && hour != 12) hour += 12;
      if (timeStr.toLowerCase().contains('am') && hour == 12) hour = 0;

      return DateTime(now.year, month, day, hour, minute);
    } catch (_) {
      return DateTime.now();
    }
  }

  int _monthToNumber(String month) {
    const Map<String, int> months = <String, int>{
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

    final String key =
        month.toLowerCase().substring(0, month.length >= 3 ? 3 : month.length);
    return months[key] ?? DateTime.now().month;
  }

  Widget _buildMemoryTimeline() {
    // Show skeleton content while loading to guide users on what's missing
    if (_isLoadingTimeline) {
      return _buildTimelineSkeleton();
    }

    // Empty state with conditional buttons based on member/story status
    if (_timelineStories.isEmpty) {
      if (_isUserCreatedMemory) {
        return _buildUserCreatedEmptyState();
      }

      // Default empty state for joined memories
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: _timelineSidePadding.h),
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 8.h),
          height: 112.h,
          child: Center(
            child: Text(
              'No stories yet',
              style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                  .copyWith(color: appTheme.blue_gray_300),
            ),
          ),
        ),
      );
    }

    // ✅ KEY CHANGE: add horizontal padding on the PARENT card area (not inside TimelineWidget)
    // This keeps the markers away from the card edges.
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _timelineSidePadding.h),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.h),
        child: TimelineWidget(
          stories: _timelineStories,
          memoryStartTime: _memoryStartTime!,
          memoryEndTime: _memoryEndTime!,
          onStoryTap: (String storyId) {
            if (widget.onTap != null) widget.onTap!();
          },
        ),
      ),
    );
  }

  /// Build timeline skeleton to show what's missing
  Widget _buildTimelineSkeleton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _timelineSidePadding.h),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 16.h),
        height: 180.h,
        child: Column(
          children: [
            // Timeline progress bar skeleton
            Container(
              height: 4.h,
              decoration: BoxDecoration(
                color: appTheme.blue_gray_300.withAlpha(51),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            SizedBox(height: 24.h),
            // Date markers skeleton (start, middle, end)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDateMarkerSkeleton(),
                _buildDateMarkerSkeleton(),
                _buildDateMarkerSkeleton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build individual date marker skeleton
  Widget _buildDateMarkerSkeleton() {
    return Column(
      children: [
        Container(
          width: 2,
          height: 8.h,
          color: appTheme.blue_gray_300.withAlpha(51),
        ),
        SizedBox(height: 6.h),
        Container(
          width: 60.h,
          height: 14.h,
          decoration: BoxDecoration(
            color: appTheme.blue_gray_300.withAlpha(51),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          width: 50.h,
          height: 12.h,
          decoration: BoxDecoration(
            color: appTheme.blue_gray_300.withAlpha(51),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  /// Build empty state for user-created memories with conditional buttons
  Widget _buildUserCreatedEmptyState() {
    // Determine which button to show based on member and story count
    final bool hasNoMembers = _memberCount == 0;
    final bool hasNoStories = _timelineStories.isEmpty;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _timelineSidePadding.h),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.h),
        padding: EdgeInsets.all(20.h),
        decoration: BoxDecoration(
          color: appTheme.gray_900_02.withAlpha(128),
          borderRadius: BorderRadius.circular(16.h),
          border: Border.all(
            color: appTheme.blue_gray_300.withAlpha(51),
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Show timeline skeleton if memory isn't built out yet
            if (hasNoStories && !hasNoMembers) ...[
              _buildTimelineSkeleton(),
              SizedBox(height: 12.h),
            ],

            CustomImageView(
              imagePath: ImageConstant.imgPlayCircle,
              height: 48.h,
              width: 48.h,
              color: appTheme.blue_gray_300,
            ),
            SizedBox(height: 16.h),
            Text(
              hasNoMembers ? 'No members yet' : 'No stories yet',
              style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                  .copyWith(color: appTheme.gray_50),
            ),
            SizedBox(height: 6.h),
            Text(
              hasNoMembers
                  ? 'Invite people to join this memory'
                  : 'Create your first story',
              style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                  .copyWith(color: appTheme.blue_gray_300),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),

            // Conditional button rendering
            if (hasNoMembers)
              // Show only invite button if no members
              CustomButton(
                text: 'Invite',
                leftIcon: ImageConstant.imgIconWhiteA700,
                onPressed: () => _onInviteTap(),
                buttonStyle: CustomButtonStyle.fillPrimary,
                buttonTextStyle: CustomButtonTextStyle.bodySmall,
                height: 40.h,
                padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 10.h),
              )
            else
              // Show create story button if members exist but no stories
              CustomButton(
                text: 'Create Story',
                leftIcon: ImageConstant.imgPlayCircle,
                onPressed: () => _onCreateStoryTap(),
                buttonStyle: CustomButtonStyle.fillPrimary,
                buttonTextStyle: CustomButtonTextStyle.bodySmall,
                height: 40.h,
                padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 10.h),
              ),
          ],
        ),
      ),
    );
  }

  /// Handle invite button tap
  void _onInviteTap() {
    if (widget.memory.id != null) {
      NavigatorService.pushNamed(
        AppRoutes.appBsMembers,
        arguments: widget.memory.id,
      );
    }
  }

  /// Handle create story button tap
  void _onCreateStoryTap() {
    if (widget.memory.id != null) {
      // Navigate to story creation screen with memory context
      NavigatorService.pushNamed(
        AppRoutes.appBsUpload,
        arguments: widget.memory.id,
      );
    }
  }

  /// Handle edit button tap
  void _onEditTap() {
    if (widget.memory.id != null) {
      NavigatorService.pushNamed(
        AppRoutes.appBsDetails,
        arguments: widget.memory.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 300.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.h),
        ),
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
    final CustomMemoryItem memory = widget.memory;

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
            padding: EdgeInsets.all(6.h),
            decoration: BoxDecoration(
              color: Color(0xFF222D3E),
              borderRadius: BorderRadius.circular(18.h),
            ),
            width: 42.h,
            height: 42.h,
            child: CustomImageView(
              imagePath: memory.iconPath ?? ImageConstant.imgFrame13Red600,
              height: 29.h,
              width: 29.h,
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
                  memory.location ?? 'Dec 4, 2025',
                  style: TextStyleHelper.instance.body12MediumPlusJakartaSans,
                ),
              ],
            ),
          ),
          _buildProfileStack(context, memory.profileImages ?? <String>[]),
        ],
      ),
    );
  }

  Widget _buildProfileStack(BuildContext context, List<String> profileImages) {
    if (profileImages.isEmpty) return const SizedBox.shrink();

    final int count = profileImages.length > 3 ? 3 : profileImages.length;

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
    final CustomMemoryItem memory = widget.memory;

    return SizedBox();
  }
}
