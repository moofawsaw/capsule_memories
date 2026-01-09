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
/// - When loaded: shows real cards. Each card fetches its own timeline stories; when there are
///   no stories yet, we STILL show a timeline skeleton preview (empty-state guidance), not just on load.
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
      margin: margin ?? EdgeInsets.only(top: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sectionTitle != null || sectionIcon != null) _buildSectionHeader(),
          if (sectionTitle != null || sectionIcon != null) SizedBox(height: 24.h),
          _buildMemoriesScroll(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
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
    if (isLoading) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          children: List.generate(3, (index) {
            return Container(
              width: 300.h,
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(memoryList.length, (index) {
          final CustomMemoryItem memory = memoryList[index];
          return Container(
            margin: EdgeInsets.only(
              left: index == 0 ? 24.h : 0,
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
    this.userId, // ✅ add owner id so we don't rely on a per-card RLS-blocked query
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
  final String? userId; // ✅ owner/creator id (from your memory list query)
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

  static const double _timelineSidePadding = 14.0;

  @override
  void initState() {
    super.initState();
    _deriveOwnershipFast();
    _loadTimelineData();
    _fetchMemberCount();
  }

  /// ✅ Prefer using userId passed into the model (no RLS risk).
  /// Fallback to DB check only if userId not provided.
  void _deriveOwnershipFast() {
    final currentUser = SupabaseService.instance.client?.auth.currentUser;
    final ownerId = widget.memory.userId;

    if (currentUser == null || ownerId == null || ownerId.isEmpty) {
      // We'll try DB fallback async (best effort) if needed.
      _isUserCreatedMemory = false;
      _checkMemoryOwnershipFallback();
      return;
    }

    _isUserCreatedMemory = currentUser.id == ownerId;
  }

  Future<void> _checkMemoryOwnershipFallback() async {
    try {
      final currentUser = SupabaseService.instance.client?.auth.currentUser;
      if (currentUser == null || widget.memory.id == null) {
        if (mounted) setState(() => _isUserCreatedMemory = false);
        return;
      }

      final dynamic memoryResponse = await SupabaseService.instance.client
          ?.from('memories')
          .select('user_id')
          .eq('id', widget.memory.id!)
          .single();

      if (!mounted) return;

      if (memoryResponse != null && memoryResponse['user_id'] != null) {
        setState(() {
          _isUserCreatedMemory = memoryResponse['user_id'] == currentUser.id;
        });
      } else {
        setState(() => _isUserCreatedMemory = false);
      }
    } catch (e) {
      // If RLS blocks it, we stay false (joined view)
      // ignore: avoid_print
      print('❌ Error checking memory ownership (fallback): $e');
      if (mounted) setState(() => _isUserCreatedMemory = false);
    }
  }

  Future<void> _fetchMemberCount() async {
    if (widget.memory.id == null || widget.memory.id!.isEmpty) {
      if (mounted) setState(() => _memberCount = 0);
      return;
    }

    try {
      final members = await _membersService.fetchMemoryMembers(widget.memory.id!);
      if (mounted) {
        setState(() => _memberCount = members.length);
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error fetching member count: $e');
      if (mounted) setState(() => _memberCount = 0);
    }
  }

  @override
  void didUpdateWidget(covariant _PublicMemoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.memory.id != widget.memory.id) {
      setState(() {
        _isLoadingTimeline = true;
        _timelineStories = <TimelineStoryItem>[];
        _memoryStartTime = null;
        _memoryEndTime = null;
        _memberCount = 0;
      });

      _deriveOwnershipFast();
      _fetchMemberCount();
      _loadTimelineData();
    } else if (oldWidget.memory.userId != widget.memory.userId) {
      // ownership info changed
      _deriveOwnershipFast();
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadTimelineData() async {
    if (widget.memory.id == null || widget.memory.id!.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoadingTimeline = false;
        _timelineStories = <TimelineStoryItem>[];
        _memoryStartTime = _parseMemoryStartTime();
        _memoryEndTime = _parseMemoryEndTime();
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

      final List<dynamic> storiesData = await _storyService.fetchMemoryStories(memoryId);

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

        final DateTime createdAt = DateTime.parse(storyData['created_at'] as String);
        final String storyId = storyData['id'] as String;

        final String backgroundImage = _storyService.getStoryMediaUrl(storyData);

        final String? avatarUrl = contributor != null ? contributor['avatar_url'] as String? : null;
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
        _memoryStartTime ??= _parseMemoryStartTime();
        _memoryEndTime ??= _parseMemoryEndTime();
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
      final int minute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;

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
      final int minute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;

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
    // Loading: show skeleton
    if (_isLoadingTimeline) {
      return _buildTimelineSkeleton();
    }

    // Empty: ALWAYS show skeleton preview + then the correct empty messaging/CTAs
    if (_timelineStories.isEmpty) {
      final bool hasNoMembers = _memberCount == 0;

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: _timelineSidePadding.h),
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 8.h),
          padding: EdgeInsets.all(16.h),
          decoration: BoxDecoration(
            color: appTheme.gray_900_02.withAlpha(128),
            // borderRadius: BorderRadius.circular(16.h),
            // border: Border.all(
            //   color: appTheme.blue_gray_300.withAlpha(51),
            //   width: 1.0,
            // ),
          ),
          child: Column(
            children: [
              _buildTimelineSkeleton(),
              SizedBox(height: 12.h),

              // Owner: show CTAs (Create Story always, Invite optional)
              if (_isUserCreatedMemory) ...[
                _buildOwnerEmptyContent(hasNoMembers: hasNoMembers),
              ] else ...[
                _buildJoinedEmptyContent(),
              ],
            ],
          ),
        ),
      );
    }

    // Normal timeline
    final DateTime start = _memoryStartTime ?? _parseMemoryStartTime();
    final DateTime end = _memoryEndTime ?? _parseMemoryEndTime();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _timelineSidePadding.h),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.h),
        child: TimelineWidget(
          stories: _timelineStories,
          memoryStartTime: start,
          memoryEndTime: end,
          onStoryTap: (String storyId) {
            if (widget.onTap != null) widget.onTap!();
          },
        ),
      ),
    );
  }

  Widget _buildOwnerEmptyContent({required bool hasNoMembers}) {
    return Column(
      children: [
        CustomImageView(
          imagePath: ImageConstant.imgPlayCircle,
          height: 48.h,
          width: 48.h,
          color: appTheme.blue_gray_300,
        ),
        SizedBox(height: 16.h),
        Text(
          'No stories yet',
          style: TextStyleHelper.instance.title16BoldPlusJakartaSans
              .copyWith(color: appTheme.gray_50),
        ),
        SizedBox(height: 6.h),
        Text(
          'Create your first story',
          style: TextStyleHelper.instance.body12MediumPlusJakartaSans
              .copyWith(color: appTheme.blue_gray_300),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20.h),

        // ✅ Create Story ALWAYS for owner when empty
        CustomButton(
          text: 'Create Story',
          leftIcon: ImageConstant.imgPlayCircle,
          onPressed: _onCreateStoryTap,
          buttonStyle: CustomButtonStyle.fillPrimary,
          buttonTextStyle: CustomButtonTextStyle.bodySmall,
          height: 40.h,
          padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 10.h),
        ),

        // ✅ Invite as secondary if no members yet (excluding creator)
        if (hasNoMembers) ...[
          SizedBox(height: 10.h),
          CustomButton(
            text: 'Invite',
            leftIcon: ImageConstant.imgIconWhiteA700,
            onPressed: _onInviteTap,
            buttonStyle: CustomButtonStyle.fillPrimary,
            buttonTextStyle: CustomButtonTextStyle.bodySmall,
            height: 40.h,
            padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 10.h),
          ),
        ],
      ],
    );
  }

  Widget _buildJoinedEmptyContent() {
    return Column(
      children: [
        Text(
          'No stories yet',
          style: TextStyleHelper.instance.title16BoldPlusJakartaSans
              .copyWith(color: appTheme.gray_50),
        ),
        SizedBox(height: 6.h),
        Text(
          'Check back soon',
          style: TextStyleHelper.instance.body12MediumPlusJakartaSans
              .copyWith(color: appTheme.blue_gray_300),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build timeline skeleton to show what's missing
  Widget _buildTimelineSkeleton() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 16.h),
      // height: 90.h,
      child: Column(
        children: [
          Container(
            height: 4.h,
            decoration: BoxDecoration(
              color: appTheme.blue_gray_300.withAlpha(51),
              // borderRadius: BorderRadius.circular(999),
            ),
          ),
          SizedBox(height: 24.h),
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
    );
  }

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

  void _onInviteTap() {
    if (widget.memory.id != null) {
      NavigatorService.pushNamed(
        AppRoutes.appBsMembers,
        arguments: widget.memory.id,
      );
    }
  }

  void _onCreateStoryTap() {
    if (widget.memory.id != null) {
      NavigatorService.pushNamed(
        AppRoutes.appBsUpload,
        arguments: widget.memory.id,
      );
    }
  }

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
              color: const Color(0xFF222D3E),
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
            right: (index * 24).h,
            child: Container(
              height: 36.h,
              width: 36.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
/*                border: Border.all(color: appTheme.whiteCustom, width: 1.h),*/
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
    // keep as-is
    return const SizedBox();
  }
}
