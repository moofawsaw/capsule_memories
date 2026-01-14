import '../../../core/app_export.dart';
import '../../../core/utils/memory_navigation_wrapper.dart';
import '../../../services/avatar_helper_service.dart';
import '../../../services/story_service.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/custom_confirmation_dialog.dart';
import '../../../widgets/custom_image_view.dart';
import '../../create_memory_screen/create_memory_screen.dart';
import '../../event_timeline_view_screen/widgets/timeline_story_widget.dart';
import '../../memory_details_screen/memory_details_screen.dart';
import '../../memory_feed_dashboard_screen/widgets/native_camera_recording_screen.dart';
import '../../memory_invitation_screen/memory_invitation_screen.dart';
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

      print('🔍 MEMORY CARD: Loading timeline for memory $memoryId');
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
        height: 300.h, // UPDATED: Increased from 280.h to 300.h for state badge
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
    // Get current user ID for creator comparison
    final currentUser = SupabaseService.instance.client?.auth.currentUser;
    final currentUserId = currentUser?.id ?? '';
    final isCreator = currentUserId.isNotEmpty &&
        currentUserId == widget.memoryItem.creatorId;

    return Container(
      height: 110.h, // UPDATED: Increased height to accommodate state badge row
      padding: EdgeInsets.all(18.h),
      decoration: BoxDecoration(
        color: appTheme.color3BD81E,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.h),
          topRight: Radius.circular(20.h),
        ),
      ),
      child: Column(
        children: [
          // Title and controls row
          Row(
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
                child: GestureDetector(
                  onTap: () => _handleTitleTap(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.memoryItem.title ?? 'Nixon Wedding 2025',
                        style: TextStyleHelper
                            .instance.title16BoldPlusJakartaSans
                            .copyWith(color: appTheme.gray_50),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        widget.memoryItem.date ?? 'Dec 4, 2025',
                        style: TextStyleHelper
                            .instance.body12MediumPlusJakartaSans,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.h),
              // EDIT ICON - only show for memories created by current user
              if (isCreator) ...[
                Builder(
                  builder: (context) => GestureDetector(
                    onTap: () => _handleEditTap(context),
                    child: Container(
                      padding: EdgeInsets.all(8.h),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 20.h,
                        color: appTheme.gray_50,
                      ),
                    ),
                  ),
                ),
              ],
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
          SizedBox(height: 8.h),
          // Members and state badge row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Participant avatars on the left
              _buildParticipantAvatarsStack(),
              // State badge on the right
              _buildStateBadge(),
            ],
          ),
        ],
      ),
    );
  }

  /// Build state badge showing SEALED or OPEN
  Widget _buildStateBadge() {
    // Determine if memory is sealed
    final isSealed = widget.memoryItem.isSealed ?? false;
    final state = widget.memoryItem.state?.toUpperCase() ??
        (isSealed ? 'SEALED' : 'OPEN');

    // Color based on state
    final badgeColor = isSealed
        ? appTheme.red_500.withAlpha(204) // Red for sealed
        : appTheme.green_500.withAlpha(204); // Green for open

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 6.h),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12.h),
      ),
      child: Text(
        state,
        style: TextStyleHelper.instance.body12BoldPlusJakartaSans.copyWith(
          color: appTheme.gray_50,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Handle title tap - open memory details bottom sheet
  void _handleTitleTap(BuildContext context) {
    final memoryId = widget.memoryItem.id;
    if (memoryId == null || memoryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid memory ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MemoryDetailsScreen(memoryId: memoryId),
    );
  }

  /// Handle edit icon tap - open edit memory bottom sheet
  void _handleEditTap(BuildContext context) {
    final memoryId = widget.memoryItem.id;
    if (memoryId == null || memoryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid memory ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Open CreateMemoryScreen as edit bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateMemoryScreen(
          // TODO: Add memoryId parameter to CreateMemoryScreen for edit mode
          // For now, it will open as create mode - edit functionality needs to be added to CreateMemoryScreen
          ),
    );
  }

  /// Handle QR code icon tap - open memory QR bottom sheet
  void _handleQRCodeTap(BuildContext context) {
    final memoryId = widget.memoryItem.id;
    if (memoryId == null || memoryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid memory ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MemoryInvitationScreen(memoryId: memoryId),
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

  /// Handle delete icon tap
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
      // FIXED: Empty state now shows "Create Story" button and opens story recording screen
      return GestureDetector(
        onTap: () {
          final memoryId = widget.memoryItem.id;
          if (memoryId == null || memoryId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Unable to create story - missing memory ID'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          print(
              '🎬 CREATE STORY TAPPED: Opening story record screen for memory $memoryId');

          // Navigate to story recording screen with memory ID as argument
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NativeCameraRecordingScreen(
                memoryId: memoryId,
                memoryTitle: widget.memoryItem.title ?? 'Memory',
                categoryIcon: widget.memoryItem.categoryIconUrl,
              ),
            ),
          );

        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.h, vertical: 8.h),
          height: 112.h,
          decoration: BoxDecoration(
            color: appTheme.gray_900_02.withAlpha(77),
            borderRadius: BorderRadius.circular(12.h),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo_outlined,
                size: 32.h,
                color: appTheme.deep_purple_A100,
              ),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.h),
                decoration: BoxDecoration(
                  color: appTheme.deep_purple_A100,
                  borderRadius: BorderRadius.circular(20.h),
                ),
                child: Text(
                  'Create Story',
                  style: TextStyleHelper.instance.body12BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_900_02),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.h),
      child: TimelineStoryWidget(
        item: _timelineStories.isNotEmpty
            ? _timelineStories.first
            : TimelineStoryItem(
                backgroundImage: '',
                userAvatar: '',
                postedAt: DateTime.now(),
                timeLabel: '',
                storyId: '',
              ),
        onTap: () {
          // CRITICAL FIX: Navigate directly to timeline instead of opening bottom sheet
          print(
              '🔍 TIMELINE CARD TAPPED: Navigating to /timeline for memory ${widget.memoryItem.id}');
          MemoryNavigationWrapper.navigateFromMemoryItem(
            context: context,
            memoryItem: widget.memoryItem,
          );
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
