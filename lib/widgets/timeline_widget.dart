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

enum TimelineVariant {
  sealed,
  active,
}

class TimelineWidget extends StatelessWidget {
  final List<TimelineStoryItem> stories;
  final DateTime memoryStartTime;
  final DateTime memoryEndTime;
  final TimelineVariant variant;
  final Function(String)? onStoryTap;

  const TimelineWidget({
    Key? key,
    required this.stories,
    required this.memoryStartTime,
    required this.memoryEndTime,
    this.variant = TimelineVariant.active,
    this.onStoryTap,
  }) : super(key: key);

  static const double _cardHeight = 68.0;
  static const double _connectorAboveBar = 12.0;
  static const double _barHeight = 4.0;
  static const double _connectorBelowBar = 12.0;
  static const double _avatarSize = 40.0;
  static const double _markerAreaHeight = 30.0;
  static const double _horizontalPadding = 20.0;
  static const double _storyMarkerWidth = 70.0;
  static const double _dayLabelWidth = 50.0;

  double get _totalHeight =>
      _cardHeight +
      _connectorAboveBar +
      _barHeight +
      _connectorBelowBar +
      _avatarSize +
      _markerAreaHeight +
      20.0;

  double get _barYPosition => _cardHeight + _connectorAboveBar;

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double timelineWidth = constraints.maxWidth;
        const double padding = _horizontalPadding;
        final double usableWidth =
            (timelineWidth - (padding * 2)).clamp(0.0, double.infinity);

        return SizedBox(
          height: _totalHeight.h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              /// HORIZONTAL TIMELINE BAR
              Positioned(
                left: padding,
                right: padding,
                top: _barYPosition.h,
                child: Container(
                  height: _barHeight.h,
                  decoration: BoxDecoration(
                    color: appTheme.deep_purple_A100,
                    borderRadius: BorderRadius.circular(2.h),
                  ),
                ),
              ),

              ..._buildStoryWidgets(usableWidth, padding),
              ..._buildDayMarkers(usableWidth, padding),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildStoryWidgets(double usableWidth, double padding) {
    final sortedStories = List<TimelineStoryItem>.from(stories)
      ..sort((a, b) => a.postedAt.compareTo(b.postedAt));

    final double half = _storyMarkerWidth / 2;

    return sortedStories.map((story) {
      final double centerX =
          _calculateTimePosition(story.postedAt, usableWidth);

      double leftPos = padding + centerX - half;

      final double minLeft = padding - half;
      final double maxLeft = padding + usableWidth - half;
      leftPos = leftPos.clamp(minLeft, maxLeft);

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

  List<Widget> _buildDayMarkers(double usableWidth, double padding) {
    final markers = <Widget>[];
    final totalDays =
        memoryEndTime.difference(memoryStartTime).inDays;

    final dates =
        _getMarkerDates(memoryStartTime, memoryEndTime, totalDays);

    for (int i = 0; i < dates.length; i++) {
      final date = dates[i];
      final pos = _calculateTimePosition(date, usableWidth);
      final double half = _dayLabelWidth / 2;

      double leftPos = padding + pos - half;
      leftPos = leftPos.clamp(
        padding - half,
        padding + usableWidth - half,
      );

      markers.add(
        Positioned(
          left: leftPos,
          bottom: 0,
          child: Column(
            children: [
              Container(
                width: 2,
                height: 8.h,
                color: appTheme.deep_purple_A100,
              ),
              SizedBox(height: 4.h),
              SizedBox(
                width: _dayLabelWidth,
                child: Text(
                  _formatDayMarker(date, i == 0, i == dates.length - 1),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: Colors.white54,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return markers;
  }

  double _calculateTimePosition(DateTime dateTime, double usableWidth) {
    final total =
        memoryEndTime.difference(memoryStartTime).inMilliseconds;
    if (total <= 0) return usableWidth / 2;

    final elapsed =
        dateTime.difference(memoryStartTime).inMilliseconds;

    final ratio = (elapsed / total).clamp(0.0, 1.0);
    return ratio * usableWidth;
  }

  List<DateTime> _getMarkerDates(
      DateTime start, DateTime end, int totalDays) {
    final dates = <DateTime>[start];

    if (totalDays > 0) {
      dates.add(end);
    }

    return dates;
  }

  String _formatDayMarker(DateTime date, bool isStart, bool isEnd) {
    final label = '${date.month}/${date.day}';
    if (isStart) return '$label\nStart';
    if (isEnd) return '$label\nEnd';
    return label;
  }
}

/// INTERNAL STORY MARKER
class _TimelineStoryWidget extends StatelessWidget {
  final TimelineStoryItem item;
  final VoidCallback? onTap;
  final double barPosition;

  const _TimelineStoryWidget({
    Key? key,
    required this.item,
    this.onTap,
    required this.barPosition,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            _buildStoryCard(),
            Container(
              width: 3,
              height: 12.h,
              color: appTheme.deep_purple_A100,
            ),
            SizedBox(height: 4.h),
            Container(
              width: 3,
              height: 12.h,
              color: appTheme.deep_purple_A100,
            ),
            _buildAvatar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard() {
    return Container(
      width: 48,
      height: 68.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.h),
        border: Border.all(
          color: appTheme.deep_purple_A100,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.h),
        child: Image.network(
          item.backgroundImage,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return SizedBox(
      width: 40.h,
      height: 40.h,
      child: ClipOval(
        child: Image.network(
          item.userAvatar,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
