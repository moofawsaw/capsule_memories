import '../../../core/app_export.dart';
import '../../../services/avatar_helper_service.dart';
import '../../../services/story_service.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/custom_confirmation_dialog.dart';
import '../../../widgets/custom_icon_button.dart';
import '../../../widgets/custom_image_view.dart';
import '../../event_timeline_view_screen/widgets/timeline_story_widget.dart';
import '../models/memory_item_model.dart';

class MemoryCardWidget extends StatefulWidget {
  final MemoryItemModel memoryItem;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  MemoryCardWidget({
    Key? key,
    required this.memoryItem,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  State<MemoryCardWidget> createState() => _MemoryCardWidgetState();
}

class _MemoryCardWidgetState extends State<MemoryCardWidget> {
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

  /// CRITICAL FIX: Load actual timeline data from database
  Future<void> _loadTimelineData() async {
    try {
      final memoryId = widget.memoryItem.id ?? '';
      if (memoryId.isEmpty) {
        setState(() {
          _isLoadingTimeline = false;
          _timelineStories = [];
        });
        return;
      }

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

      print(
          '🔍 MEMORY CARD: Loading timeline for memory $memoryId');
      print('🔍 MEMORY CARD: Fetched ${storiesData.length} stories');

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

      setState(() {
        _timelineStories = timelineStories;
        _memoryStartTime = memoryStart;
        _memoryEndTime = memoryEnd;
        _isLoadingTimeline = false;
      });

      print(
          '✅ MEMORY CARD: Timeline loaded with ${timelineStories.length} stories');
    } catch (e) {
      print('❌ MEMORY CARD: Error loading timeline: $e');
      setState(() {
        _isLoadingTimeline = false;
        _timelineStories = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 300.h,
        decoration: BoxDecoration(
          color: appTheme.gray_900_01,
          borderRadius: BorderRadius.circular(20.h),
        ),
        child: Column(
          children: [
            _buildEventHeader(),
            _buildTimelineStoryWidget(),
            _buildEventInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventHeader() {
    return Container(
      padding: EdgeInsets.all(18.h),
      decoration: BoxDecoration(
        color: appTheme.color3BD81E,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.h),
          topRight: Radius.circular(20.h),
        ),
      ),
      child: Row(
        children: [
          // Use actual category icon if available, otherwise use fallback
          CustomIconButton(
            iconPath: widget.memoryItem.categoryIconUrl != null &&
                    widget.memoryItem.categoryIconUrl!.isNotEmpty
                ? widget.memoryItem.categoryIconUrl!
                : ImageConstant.imgFrame13Red600,
            backgroundColor: appTheme.color41C124,
            borderRadius: 18.h,
            height: 36.h,
            width: 36.h,
            padding: EdgeInsets.all(6.h),
            iconSize: 24.h,
          ),
          SizedBox(width: 12.h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.memoryItem.title ?? 'Nixon Wedding 2025',
                  style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                ),
                SizedBox(height: 4.h),
                Text(
                  widget.memoryItem.date ?? 'Dec 4, 2025',
                  style: TextStyleHelper.instance.body12MediumPlusJakartaSans,
                ),
              ],
            ),
          ),
          SizedBox(width: 8.h),
          // Participant avatars section - using exact feed pattern
          _buildParticipantAvatarsStack(),
          if (widget.onDelete != null) ...[
            SizedBox(width: 8.h),
            Builder(
              builder: (context) => GestureDetector(
                onTap: () => _handleDeleteTap(context),
                child: Container(
                  padding: EdgeInsets.all(8.h),
                  child: Icon(
                    Icons.delete_outline,
                    size: 20.h,
                    color: appTheme.gray_50,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build participant avatars using exact same pattern as feed
  Widget _buildParticipantAvatarsStack() {
    // Use actual participant avatars from cache service (already filtered)
    final avatars = widget.memoryItem.participantAvatars ?? [];

    // Return empty container if no avatars to display
    if (avatars.isEmpty) {
      return SizedBox(width: 84.h, height: 36.h);
    }

    // Take up to 3 avatars for display
    final displayAvatars = avatars.take(3).toList();

    return Container(
      width: 84.h,
      height: 36.h,
      child: Stack(
        children: [
          // First avatar
          if (displayAvatars.isNotEmpty)
            Positioned(
              left: 0,
              child: CustomImageView(
                imagePath: displayAvatars[0],
                height: 36.h,
                width: 36.h,
                radius: BorderRadius.circular(18.h),
              ),
            ),
          // Second avatar
          if (displayAvatars.length > 1)
            Positioned(
              left: 24.h,
              child: CustomImageView(
                imagePath: displayAvatars[1],
                height: 36.h,
                width: 36.h,
                radius: BorderRadius.circular(18.h),
              ),
            ),
          // Third avatar
          if (displayAvatars.length > 2)
            Positioned(
              right: 0,
              child: CustomImageView(
                imagePath: displayAvatars[2],
                height: 36.h,
                width: 36.h,
                radius: BorderRadius.circular(18.h),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteTap(BuildContext context) async {
    final confirmed = await CustomConfirmationDialog.show(
      context: context,
      title: 'Delete Memory?',
      message:
          'Are you sure you want to delete "${widget.memoryItem.title ?? 'this memory'}"? All stories and content will be permanently removed.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      icon: Icons.delete_outline,
    );

    if (confirmed == true && widget.onDelete != null) {
      widget.onDelete!();
    }
  }

  /// CRITICAL FIX: Use TimelineStoryWidget with actual database data
  Widget _buildTimelineStoryWidget() {
    if (_isLoadingTimeline) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 4.h, vertical: 8.h),
        height: 112.h,
        child: Center(
          child: SizedBox(
            width: 24.h,
            height: 24.h,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor:
                  AlwaysStoppedAnimation<Color>(appTheme.deep_purple_A100),
            ),
          ),
        ),
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
      margin: EdgeInsets.symmetric(horizontal: 4.h),
      child: TimelineStoryWidget(
        stories: _timelineStories,
        memoryStartTime:
            _memoryStartTime ?? DateTime.now().subtract(Duration(hours: 2)),
        memoryEndTime: _memoryEndTime ?? DateTime.now(),
        timelineHeight: 112,
        onStoryTap: (storyId) {
          // Navigate with full memory context when timeline card is tapped
          if (widget.onTap != null) {
            widget.onTap!();
          }
        },
      ),
    );
  }

  /// Convert memory start time from eventDate + eventTime
  DateTime _parseMemoryStartTime() {
    try {
      final dateStr = widget.memoryItem.eventDate ?? 'Dec 4';
      final timeStr = widget.memoryItem.eventTime ?? '3:18pm';

      // Parse date (format: "Dec 4")
      final now = DateTime.now();
      final parts = dateStr.split(' ');
      final month = _monthToNumber(parts[0]);
      final day = int.tryParse(parts[1]) ?? now.day;

      // Parse time (format: "3:18pm")
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

  /// Parse memory end time from endDate + endTime
  DateTime _parseMemoryEndTime() {
    try {
      final dateStr = widget.memoryItem.endDate ?? 'Dec 4';
      final timeStr = widget.memoryItem.endTime ?? '3:18am';

      // Parse date (format: "Dec 4")
      final now = DateTime.now();
      final parts = dateStr.split(' ');
      final month = _monthToNumber(parts[0]);
      final day = int.tryParse(parts[1]) ?? now.day;

      // Parse time (format: "3:18am")
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

  /// Convert month name to number
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

  Widget _buildEventInfo() {
    return Container(
      padding: EdgeInsets.all(12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.memoryItem.eventDate ?? 'Dec 4',
                style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                    .copyWith(color: appTheme.gray_50),
              ),
              SizedBox(height: 6.h),
              Text(
                widget.memoryItem.eventTime ?? '3:18pm',
                style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                widget.memoryItem.location ?? 'Tillsonburg, ON',
                style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
              SizedBox(height: 4.h),
              Text(
                widget.memoryItem.distance ?? '21km',
                style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.memoryItem.endDate ?? 'Dec 4',
                style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                    .copyWith(color: appTheme.gray_50),
              ),
              SizedBox(height: 6.h),
              Text(
                widget.memoryItem.endTime ?? '3:18am',
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