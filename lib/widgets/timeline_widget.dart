import 'package:cached_network_image/cached_network_image.dart';

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

enum TimelineVariant { sealed, active }

class TimelineWidget extends StatelessWidget {
  final List<TimelineStoryItem> stories;
  final DateTime memoryStartTime; // stored UTC from DB
  final DateTime memoryEndTime; // stored UTC from DB
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

  // ===== Layout constants =====
  static const double _cardHeight = 62.0;
  static const double _cardWidth = 44.0;
  static const double _connectorAboveBar = 12.0;
  static const double _barHeight = 4.0;
  static const double _connectorBelowBar = 12.0;
  static const double _avatarSize = 40.0;
  static const double _markerAreaHeight = 46.0;
  static const double _horizontalPadding = 20.0;

  // Raw px widths (do NOT apply .w when positioning horizontally)
  static const double _storyMarkerWidth = 70.0;
  static const double _markerLabelWidth = 72.0;

  // Keep markers away from the edges (Option B)
  static const double _markerEdgeInset = 14.0; // px, tweak 10–20

  double get _totalHeight =>
      _cardHeight +
      _connectorAboveBar +
      _barHeight +
      _connectorBelowBar +
      _avatarSize +
      _markerAreaHeight +
      20.0;

  double get _barYPosition => _cardHeight + _connectorAboveBar;

  DateTime _toUtc(DateTime dt) => dt.isUtc ? dt : dt.toUtc();

  // Display to user in local timezone (EST/whatever device is set to)
  DateTime _toLocal(DateTime dt) => _toUtc(dt).toLocal();

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double timelineWidth = constraints.maxWidth;
        const double padding = _horizontalPadding;

        final double usableWidth = (timelineWidth - (padding * 2))
            .clamp(0.0, double.infinity)
            .toDouble();

        final double progressRatio = _memoryProgressRatio();

        return SizedBox(
          height: _totalHeight.h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // === PROGRESS BAR (track + fill) ===
              Positioned(
                left: padding,
                right: padding,
                top: _barYPosition.h,
                child: _buildProgressBar(
                  usableWidth: usableWidth,
                  progressRatio: progressRatio,
                ),
              ),

              ..._buildStoryWidgets(usableWidth, padding),
              ..._buildThreeMarkers(usableWidth, padding),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBar({
    required double usableWidth,
    required double progressRatio,
  }) {
    // Track + fill
    final trackColor = appTheme.deep_purple_A100.withAlpha(70);
    final fillColor = appTheme.deep_purple_A100;

    final double fillWidth =
        (usableWidth * progressRatio).clamp(0.0, usableWidth).toDouble();

    return SizedBox(
      height: _barHeight.h,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              width: fillWidth,
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _memoryProgressRatio() {
    DateTime start = _toUtc(memoryStartTime);
    DateTime end = _toUtc(memoryEndTime);

    if (end.isBefore(start)) {
      final tmp = start;
      start = end;
      end = tmp;
    }

    // If sealed memory (ended), show full
    if (variant == TimelineVariant.sealed) return 1.0;

    final DateTime now = DateTime.now().toUtc();
    final int totalMs = end.difference(start).inMilliseconds;
    if (totalMs <= 0) return 1.0;

    final int elapsedMs = now.difference(start).inMilliseconds;
    return (elapsedMs / totalMs).clamp(0.0, 1.0).toDouble();
  }

  List<Widget> _buildStoryWidgets(double usableWidth, double padding) {
    final sorted = List<TimelineStoryItem>.from(stories)
      ..sort((a, b) => a.postedAt.compareTo(b.postedAt));

    final double halfMarker = _storyMarkerWidth / 2;

    return sorted.map((story) {
      final double centerX =
          _calculateTimePosition(story.postedAt, usableWidth);

      double leftPos = padding + centerX - halfMarker;

      // Clamp so center can reach both ends (allow overflow off the edges)
      final double minLeft = padding - halfMarker; // center at x=0
      final double maxLeft =
          padding + usableWidth - halfMarker; // center at x=max
      leftPos = leftPos.clamp(minLeft, maxLeft).toDouble();

      return Positioned(
        left: leftPos,
        top: 0,
        child: _TimelineStoryWidget(
          item: story,
          barYPosition: _barYPosition,
          onTap: () {
            if (onStoryTap != null && story.storyId != null) {
              onStoryTap!(story.storyId!);
            }
          },
        ),
      );
    }).toList();
  }

  /// Markers: Start (bold), Midpoint (regular), End (bold)
  /// Start/End labels must equal memoryStartTime/memoryEndTime EXACTLY (shown in local timezone)
  List<Widget> _buildThreeMarkers(double usableWidth, double padding) {
    DateTime startUtc = _toUtc(memoryStartTime);
    DateTime endUtc = _toUtc(memoryEndTime);

    if (endUtc.isBefore(startUtc)) {
      final tmp = startUtc;
      startUtc = endUtc;
      endUtc = tmp;
    }

    final int totalMs = endUtc.difference(startUtc).inMilliseconds;
    final int safeTotalMs = totalMs <= 0 ? 1 : totalMs;

    final DateTime midUtc =
        startUtc.add(Duration(milliseconds: (safeTotalMs / 2).round()));

    final markers = <_MarkerSpec>[
      _MarkerSpec(
        timeForPositionUtc: startUtc,
        timeForLabelExact: memoryStartTime, // EXACT
        isEmphasized: true,
      ),
      _MarkerSpec(
        timeForPositionUtc: midUtc,
        timeForLabelExact: midUtc,
        isEmphasized: false,
      ),
      _MarkerSpec(
        timeForPositionUtc: endUtc,
        timeForLabelExact: memoryEndTime, // EXACT
        isEmphasized: true,
      ),
    ];

    final widgets = <Widget>[];
    final double halfLabel = _markerLabelWidth / 2;

    for (final m in markers) {
      final double rawPos =
          _calculateTimePosition(m.timeForPositionUtc, usableWidth);

      // === OPTION B: keep markers away from edges ===
      final double minCenter = _markerEdgeInset;
      final double maxCenter = (usableWidth - _markerEdgeInset)
          .clamp(0.0, double.infinity)
          .toDouble();
      final double clampedCenter =
          rawPos.clamp(minCenter, maxCenter).toDouble();

      final double leftPos = (padding + clampedCenter - halfLabel).toDouble();

      final _MarkerTextParts parts =
          _formatMarkerPartsLocal(m.timeForLabelExact);

      widgets.add(
        Positioned(
          left: leftPos,
          bottom: 0,
          child: Column(
            children: [
              Container(
                width: 2,
                height: 8.h,
                color: appTheme.blue_gray_900_02, // muted gridline
              ),
              SizedBox(height: 6.h),
              SizedBox(
                width: _markerLabelWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Date (Dec 22) — bold for start/end
                    Text(
                      parts.dateLine,
                      textAlign: TextAlign.center,
                      style: (m.isEmphasized
                              ? TextStyleHelper
                                  .instance.body14BoldPlusJakartaSans
                              : TextStyleHelper
                                  .instance.body14RegularPlusJakartaSans)
                          .copyWith(color: appTheme.gray_50),
                      maxLines: 1,
                    ),
                    SizedBox(height: 6.h),
                    // Time (6:33 PM) — regular muted
                    Text(
                      parts.timeLine,
                      textAlign: TextAlign.center,
                      style: TextStyleHelper
                          .instance.body14RegularPlusJakartaSans
                          .copyWith(color: appTheme.blue_gray_300),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  /// Position across the bar based on time ratio (UTC normalization for math)
  double _calculateTimePosition(DateTime dateTime, double usableWidth) {
    DateTime start = _toUtc(memoryStartTime);
    DateTime end = _toUtc(memoryEndTime);
    final DateTime item = _toUtc(dateTime);

    if (end.isBefore(start)) {
      final tmp = start;
      start = end;
      end = tmp;
    }

    final int totalMs = end.difference(start).inMilliseconds;
    final int safeTotalMs = totalMs <= 0 ? 1 : totalMs;

    final int elapsedMs = item.difference(start).inMilliseconds;
    final double ratio = (elapsedMs / safeTotalMs).clamp(0.0, 1.0).toDouble();

    return ratio * usableWidth;
  }

  _MarkerTextParts _formatMarkerPartsLocal(DateTime dt) {
    final DateTime local = _toLocal(dt);

    const months = [
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
    final String month = months[local.month - 1];
    final int day = local.day;

    int hour = local.hour;
    final int minute = local.minute;
    final bool isPm = hour >= 12;

    int displayHour = hour % 12;
    if (displayHour == 0) displayHour = 12;

    final String mm = minute.toString().padLeft(2, '0');
    final String ampm = isPm ? 'PM' : 'AM';

    return _MarkerTextParts(
      dateLine: '$month $day',
      timeLine: '$displayHour:$mm $ampm',
    );
  }
}

class _MarkerSpec {
  final DateTime timeForPositionUtc;
  final DateTime timeForLabelExact;
  final bool isEmphasized;

  const _MarkerSpec({
    required this.timeForPositionUtc,
    required this.timeForLabelExact,
    required this.isEmphasized,
  });
}

class _MarkerTextParts {
  final String dateLine;
  final String timeLine;

  const _MarkerTextParts({
    required this.dateLine,
    required this.timeLine,
  });
}

class _TimelineStoryWidget extends StatelessWidget {
  final TimelineStoryItem item;
  final VoidCallback? onTap;
  final double barYPosition;

  const _TimelineStoryWidget({
    Key? key,
    required this.item,
    required this.barYPosition,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: TimelineWidget._storyMarkerWidth,
        child: Column(
          children: [
            _buildStoryCard(),

            // spacing above bar (no connector)
            SizedBox(height: TimelineWidget._connectorAboveBar.h),

            // bar height spacer
            SizedBox(height: TimelineWidget._barHeight.h),

            // connector BELOW bar (thin, square ends)
            Container(
              width: 2, // slightly thinner
              height: TimelineWidget._connectorBelowBar.h,
              color: appTheme.deep_purple_A100, // muted gridline
            ),

            _buildAvatar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard() {
    return Container(
      width: TimelineWidget._cardWidth,
      height: TimelineWidget._cardHeight.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.h), // slightly reduced
        border: Border.all(
          color: appTheme.deep_purple_A200,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6.h),
        child: CachedNetworkImage(
          imageUrl: item.backgroundImage,
          key: ValueKey(
              'story_thumbnail_${item.storyId}_${item.backgroundImage.hashCode}'),
          fit: BoxFit.cover,
          memCacheWidth: 200, // Optimize memory cache size
          memCacheHeight: 280,
          maxHeightDiskCache: 400, // Optimize disk cache size
          maxWidthDiskCache: 280,
          fadeInDuration: const Duration(milliseconds: 200),
          fadeOutDuration: const Duration(milliseconds: 100),
          placeholder: (context, url) => Container(
            color: const Color(0xFF2A2A3A),
            alignment: Alignment.center,
            child: SizedBox(
              width: 16.h,
              height: 16.h,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  appTheme.deep_purple_A100.withAlpha(128),
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) {
            // CRITICAL FIX: Retry loading image on error
            // This ensures thumbnails reload properly after viewing stories
            print(
                '🔄 TIMELINE: Thumbnail load failed for ${item.storyId}, retrying...');

            return FutureBuilder(
              future: Future.delayed(
                const Duration(milliseconds: 500),
                () => CachedNetworkImage(
                  imageUrl: item.backgroundImage,
                  fit: BoxFit.cover,
                  memCacheWidth: 200,
                  memCacheHeight: 280,
                  errorWidget: (context, url, retryError) => Container(
                    color: const Color(0xFF2A2A3A),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.refresh,
                      color: Colors.white38,
                      size: 18.h,
                    ),
                  ),
                ),
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    color: const Color(0xFF2A2A3A),
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 16.h,
                      height: 16.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          appTheme.deep_purple_A100.withAlpha(128),
                        ),
                      ),
                    ),
                  );
                }

                return snapshot.data ??
                    Container(
                      color: const Color(0xFF2A2A3A),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.white38,
                        size: 18.h,
                      ),
                    );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return SizedBox(
      width: TimelineWidget._avatarSize.h,
      height: TimelineWidget._avatarSize.h,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: item.userAvatar,
          key: ValueKey('avatar_${item.storyId}_${item.userAvatar.hashCode}'),
          fit: BoxFit.cover,
          memCacheWidth: 80,
          memCacheHeight: 80,
          maxHeightDiskCache: 120,
          maxWidthDiskCache: 120,
          fadeInDuration: const Duration(milliseconds: 200),
          fadeOutDuration: const Duration(milliseconds: 100),
          placeholder: (context, url) => Container(
            color: const Color(0xFF2A2A3A),
            alignment: Alignment.center,
            child: SizedBox(
              width: 12.h,
              height: 12.h,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  appTheme.deep_purple_A100.withAlpha(128),
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: const Color(0xFF2A2A3A),
            alignment: Alignment.center,
            child: Icon(
              Icons.person,
              color: Colors.white38,
              size: 18.h,
            ),
          ),
        ),
      ),
    );
  }
}
