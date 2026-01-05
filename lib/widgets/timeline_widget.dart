import '../core/app_export.dart';

/// Data model for timeline story items
class TimelineStoryItem {
  const TimelineStoryItem({
    required this.backgroundImage,
    required this.userAvatar,
    required this.postedAt,
    this.timeLabel,
    this.storyId,
    this.isVideo = true,
  });

  final String backgroundImage;
  final String userAvatar;
  final DateTime postedAt;
  final String? timeLabel;
  final String? storyId;
  final bool isVideo;
}

/// Enum for timeline display variants
enum TimelineVariant {
  sealed, // Sealed memory view with replay/add media buttons
  active, // Active memory view
}

/// Timeline widget that displays stories positioned along a time-based horizontal bar
class TimelineWidget extends StatelessWidget {
  final List<TimelineStoryItem> stories;
  final DateTime memoryStartTime;
  final DateTime memoryEndTime;
  final TimelineVariant variant;
  final Function(String)? onStoryTap;
  final VoidCallback? onReplayAll;
  final VoidCallback? onAddMedia;

  const TimelineWidget({
    Key? key,
    required this.stories,
    required this.memoryStartTime,
    required this.memoryEndTime,
    this.variant = TimelineVariant.active,
    this.onStoryTap,
    this.onReplayAll,
    this.onAddMedia,
  }) : super(key: key);

  // Layout constants
  static const double _cardHeight = 68.0;
  static const double _connectorAboveBar = 12.0;
  static const double _barHeight = 4.0;
  static const double _connectorBelowBar = 12.0;
  static const double _avatarSize = 40.0;
  static const double _markerAreaHeight = 30.0;
  static const double _horizontalPadding = 20.0;
  static const double _storyCardWidth = 70.0;

  // Calculate total height needed
  double get _totalHeight =>
      _cardHeight +
      _connectorAboveBar +
      _barHeight +
      _connectorBelowBar +
      _avatarSize +
      _markerAreaHeight +
      20.0;

  // Y position of the horizontal bar
  double get _barYPosition => _cardHeight + _connectorAboveBar;

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) {
      return _buildEmptyState();
    }

    // Debug logging
    debugPrint('Timeline: ${stories.length} stories');
    debugPrint('Timeline: Start=$memoryStartTime, End=$memoryEndTime');

    return LayoutBuilder(
      builder: (context, constraints) {
        final timelineWidth = constraints.maxWidth;
        final padding = _horizontalPadding.w;
        final usableWidth = timelineWidth - (padding * 2);

        return Container(
          height: _totalHeight.h,
          margin: EdgeInsets.symmetric(vertical: 8.h),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // === HORIZONTAL TIMELINE BAR ===
              Positioned(
                left: padding,
                right: padding,
                top: _barYPosition.h,
                child: Container(
                  height: _barHeight.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF8B5CF6), // Purple
                        Color(0xFFEC4899), // Pink
                        Color(0xFFA855F7), // Purple variant
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(2.h),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withAlpha(128),
                        blurRadius: 8,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),

              // === STORY CARDS (positioned along timeline) ===
              ..._buildStoryWidgets(usableWidth, padding),

              // === DAY MILESTONE MARKERS ===
              ..._buildDayMarkers(usableWidth, padding),
            ],
          ),
        );
      },
    );
  }

  /// Build positioned story widgets based on their posting time
  List<Widget> _buildStoryWidgets(double usableWidth, double padding) {
    // Sort by postedAt so later stories appear on top (higher z-index)
    final sortedStories = List<TimelineStoryItem>.from(stories)
      ..sort((a, b) => a.postedAt.compareTo(b.postedAt));

    return sortedStories.map((story) {
      final position = _calculateTimePosition(story.postedAt, usableWidth);
      // Center the card on its position
      final leftPos = padding + position - (_storyCardWidth.w / 2);

      return Positioned(
        left: leftPos,
        top: 0,
        child: _TimelineStoryWidget(
          item: story,
          barPosition: _barYPosition,
          onTap: () {
            if (onStoryTap != null && story.storyId != null) {
              onStoryTap!(story.storyId!);
            }
          },
        ),
      );
    }).toList();
  }

  /// Build day milestone markers at the bottom of the timeline
  List<Widget> _buildDayMarkers(double usableWidth, double padding) {
    final markers = <Widget>[];
    final totalDuration = memoryEndTime.difference(memoryStartTime);
    final totalDays = totalDuration.inDays;

    // Determine marker dates based on duration
    final markerDates =
        _getMarkerDates(memoryStartTime, memoryEndTime, totalDays);

    for (int i = 0; i < markerDates.length; i++) {
      final markerDate = markerDates[i];
      final position = _calculateTimePosition(markerDate, usableWidth);
      final isFirst = i == 0;
      final isLast = i == markerDates.length - 1;

      markers.add(
        Positioned(
          left: padding + position - 25.w, // Center the label
          bottom: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tick mark
              Container(
                width: 2.w,
                height: 8.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A4A5A),
                  borderRadius: BorderRadius.circular(1.w),
                ),
              ),
              SizedBox(height: 4.h),
              // Date label
              SizedBox(
                width: 50.w,
                child: Text(
                  _formatDayMarker(markerDate, isFirst, isLast),
                  style: TextStyle(
                    color: isFirst || isLast ? Colors.white70 : Colors.white54,
                    fontSize: 9.sp,
                    fontWeight:
                        isFirst || isLast ? FontWeight.w600 : FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return markers;
  }

  /// Calculate horizontal position based on time
  double _calculateTimePosition(DateTime dateTime, double usableWidth) {
    final totalDuration = memoryEndTime.difference(memoryStartTime);
    final itemDuration = dateTime.difference(memoryStartTime);

    if (totalDuration.inSeconds <= 0) return 0;

    final ratio = itemDuration.inSeconds / totalDuration.inSeconds;
    return (ratio.clamp(0.0, 1.0) * usableWidth);
  }

  /// Get dates for markers based on memory duration
  List<DateTime> _getMarkerDates(DateTime start, DateTime end, int totalDays) {
    final dates = <DateTime>[];

    if (totalDays <= 1) {
      // Show start and end only for short memories
      dates.add(start);
      if (totalDays == 1) {
        dates.add(end);
      }
    } else if (totalDays <= 7) {
      // Show each day
      for (int i = 0; i <= totalDays; i++) {
        dates.add(DateTime(start.year, start.month, start.day)
            .add(Duration(days: i)));
      }
    } else if (totalDays <= 14) {
      // Show every 2 days
      for (int i = 0; i <= totalDays; i += 2) {
        dates.add(DateTime(start.year, start.month, start.day)
            .add(Duration(days: i)));
      }
      // Always include end date
      if (dates.last != DateTime(end.year, end.month, end.day)) {
        dates.add(DateTime(end.year, end.month, end.day));
      }
    } else {
      // Show weekly + start/end
      dates.add(DateTime(start.year, start.month, start.day));
      for (int i = 7; i < totalDays; i += 7) {
        dates.add(DateTime(start.year, start.month, start.day)
            .add(Duration(days: i)));
      }
      dates.add(DateTime(end.year, end.month, end.day));
    }

    return dates;
  }

  /// Format date for marker label
  String _formatDayMarker(DateTime date, bool isStart, bool isEnd) {
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final label = '${monthNames[date.month - 1]} ${date.day}';

    if (isStart) return '$label\nStart';
    if (isEnd) return '$label\nEnd';
    return label;
  }

  Widget _buildEmptyState() {
    return Container(
      height: 100.h,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timeline_outlined,
            color: Colors.white38,
            size: 32.h,
          ),
          SizedBox(height: 8.h),
          Text(
            'No stories in this memory yet',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual timeline story widget with vertical layout
/// Card at top, connector, avatar at bottom
class _TimelineStoryWidget extends StatelessWidget {
  final TimelineStoryItem item;
  final VoidCallback? onTap;
  final double barPosition; // Y position of the horizontal bar

  const _TimelineStoryWidget({
    Key? key,
    required this.item,
    this.onTap,
    this.barPosition = 85.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Story Card (phone-shaped) - ABOVE THE BAR
            _buildStoryCard(),

            // Vertical connector from card to bar
            Container(
              width: 3.w,
              height: 12.h,
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A4A),
                borderRadius: BorderRadius.circular(1.5.w),
              ),
            ),

            // Space for the horizontal bar (handled by parent Stack)
            SizedBox(height: 4.h),

            // Vertical connector from bar to avatar
            Container(
              width: 3.w,
              height: 12.h,
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A4A),
                borderRadius: BorderRadius.circular(1.5.w),
              ),
            ),

            // User Avatar with gradient ring - BELOW THE BAR
            _buildAvatarWithRing(),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard() {
    return Container(
      width: 48.w,
      height: 68.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.h),
        border: Border.all(
          color: const Color(0xFF8B5CF6), // Purple border
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(102),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.h),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            Image.network(
              item.backgroundImage,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF2A2A3A),
                child: Icon(
                  Icons.image_not_supported,
                  color: Colors.white38,
                  size: 20.h,
                ),
              ),
            ),

            // Play icon overlay (for videos)
            if (item.isVideo)
              Center(
                child: Container(
                  padding: EdgeInsets.all(8.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(128),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 18.h,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarWithRing() {
    return Container(
      width: 40.h,
      height: 40.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color(0xFF8B5CF6), // Purple
            Color(0xFFEC4899), // Pink
            Color(0xFFA855F7), // Purple variant
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withAlpha(102),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(2.5.h), // Ring thickness
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1A1A2E), // Dark background fallback
        ),
        child: ClipOval(
          child: Image.network(
            item.userAvatar,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFF2A2A3A),
              child: Icon(
                Icons.person,
                color: Colors.white38,
                size: 20.h,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
