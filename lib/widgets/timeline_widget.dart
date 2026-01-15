import 'package:cached_network_image/cached_network_image.dart';

import '../core/app_export.dart';
import '../presentation/event_timeline_view_screen/widgets/timeline_story_widget.dart';

enum TimelineVariant { sealed, active }

/// Layout variant so we can render a tighter version on memory cards.
enum TimelineLayoutVariant { full, compact }

class TimelineWidget extends StatelessWidget {
  final List<TimelineStoryItem> stories;
  final DateTime memoryStartTime; // stored UTC from DB
  final DateTime memoryEndTime; // stored UTC from DB
  final TimelineVariant variant;
  final Function(String)? onStoryTap;

  /// Controls marker spacing + countdown badge sizing/typography.
  final TimelineLayoutVariant layoutVariant;

  const TimelineWidget({
    Key? key,
    required this.stories,
    required this.memoryStartTime,
    required this.memoryEndTime,
    this.variant = TimelineVariant.active,
    this.onStoryTap,
    this.layoutVariant = TimelineLayoutVariant.full,
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

  // Marker label widths by layout variant
  static const double _markerLabelWidthFull = 72.0;
  static const double _markerLabelWidthCompact = 64.0;

  double get _markerLabelWidth =>
      layoutVariant == TimelineLayoutVariant.compact
          ? _markerLabelWidthCompact
          : _markerLabelWidthFull;

  // Keep markers away from the edges
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

  String _countdownWidthTemplate({required bool isCompact}) {
    // Reserve a fixed text width so the badge NEVER jitters as seconds tick.
    // If you expect 3-digit days, change to '888d 88:88:88'.
    return isCompact ? '88d 88:88:88' : '';
  }

  // ============================
  // URL SAFETY (AVATAR + THUMBNAIL)
  // ============================

  bool _isValidNetworkUrl(String? s) {
    if (s == null) return false;
    final v = s.trim();
    if (v.isEmpty) return false;
    if (v == 'null' || v == 'undefined') return false;
    return v.startsWith('http://') || v.startsWith('https://');
  }

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
      final double centerX = _calculateTimePosition(story.postedAt, usableWidth);

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

  // ============================
  // MIDPOINT COUNTDOWN BADGE
  // ============================

  String _formatRemainingClock(Duration d) {
    if (d.isNegative || d.inSeconds <= 0) return '00:00:00';

    final int totalSeconds = d.inSeconds;

    final int days = totalSeconds ~/ 86400;
    final int hoursTotal = (totalSeconds % 86400) ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;

    final String hh = hoursTotal.toString().padLeft(2, '0');
    final String mm = minutes.toString().padLeft(2, '0');
    final String ss = seconds.toString().padLeft(2, '0');

    // ✅ Only show days when days > 0 (never "0d")
    if (days > 0) return '${days}d $hh:$mm:$ss';
    return '$hh:$mm:$ss';
  }

  Widget _buildCountdownBadge(
      DateTime endUtc, {
        double? maxWidth,
        bool isCompact = false,
      }) {
    if (variant == TimelineVariant.sealed) {
      return _countdownBadgeShell(
        value: '00:00:00',
        maxWidth: maxWidth,
        isCompact: isCompact,
      );
    }

    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
      builder: (context, snapshot) {
        final DateTime nowUtc = DateTime.now().toUtc();
        final Duration remaining = endUtc.difference(nowUtc);
        final String clock = _formatRemainingClock(remaining);

        return _countdownBadgeShell(
          value: clock,
          maxWidth: maxWidth,
          isCompact: isCompact,
        );
      },
    );
  }

  Widget _countdownBadgeShell({
    required String value,
    double? maxWidth,
    bool isCompact = false,
  }) {
    // Compact pill sizing (memory cards)
    final double pillHeight = isCompact ? 30.h : 34.h;
    final double horizontalPadding = isCompact ? 12.h : 14.h;
    final double iconSize = isCompact ? 14.h : 16.h;
    final double gap = isCompact ? 6.h : 8.h;

    // FULL keeps its stronger min width, COMPACT can shrink
    final double desiredMinWidth = isCompact ? 0.0 : 150.h;

    final double fallbackMaxWidth = isCompact ? 260.h : 220.h;
    final double effectiveMaxWidth =
    (maxWidth ?? fallbackMaxWidth).clamp(0.0, 99999.0);

    final double effectiveMinWidth =
    desiredMinWidth > effectiveMaxWidth ? effectiveMaxWidth : desiredMinWidth;

    final TextStyle baseStyle =
        TextStyleHelper.instance.body14BoldPlusJakartaSans;

    final TextStyle textStyle = isCompact
        ? baseStyle.copyWith(
      fontSize: 12.h,
      height: 1.0,
      letterSpacing: 0.1,
      color: appTheme.gray_50,
    )
        : baseStyle.copyWith(
      color: appTheme.gray_50,
      height: 1.0,
      letterSpacing: 0.2,
    );

    final String template = _countdownWidthTemplate(isCompact: isCompact);

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: effectiveMinWidth,
        maxWidth: effectiveMaxWidth,
      ),
      child: Container(
        height: pillHeight,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        decoration: BoxDecoration(
          color: appTheme.deep_purple_A100.withAlpha(40),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          // COMPACT wraps; FULL can fill its lane
          mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Icon(
              Icons.access_time_rounded,
              size: iconSize,
              color: appTheme.gray_50.withAlpha(220),
            ),
            SizedBox(width: gap),
            Flexible(
              child: isCompact
                  ? Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Invisible template reserves constant width (prevents jitter)
                  Opacity(
                    opacity: 0.0,
                    child: Text(
                      template,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: textStyle,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle,
                  ),
                ],
              )
                  : Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Markers: Start (bold), Midpoint (COUNTDOWN BADGE), End (bold)
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
        timeForLabelExact: memoryStartTime,
        isEmphasized: true,
      ),
      _MarkerSpec(
        timeForPositionUtc: midUtc,
        timeForLabelExact: midUtc,
        isEmphasized: false,
      ),
      _MarkerSpec(
        timeForPositionUtc: endUtc,
        timeForLabelExact: memoryEndTime,
        isEmphasized: true,
      ),
    ];

    final widgets = <Widget>[];
    final double halfLabel = _markerLabelWidth / 2;

    for (int i = 0; i < markers.length; i++) {
      final m = markers[i];
      final bool isMidpoint = i == 1;

      final double rawPos =
      _calculateTimePosition(m.timeForPositionUtc, usableWidth);

      final double minCenter = _markerEdgeInset;
      final double maxCenter = (usableWidth - _markerEdgeInset)
          .clamp(0.0, double.infinity)
          .toDouble();
      final double clampedCenter = rawPos.clamp(minCenter, maxCenter).toDouble();

      final double leftPos = (padding + clampedCenter - halfLabel).toDouble();

      if (isMidpoint) {
        // FULL view: use marker label widths to keep the badge inside the label columns.
        if (layoutVariant == TimelineLayoutVariant.full) {
          final double badgeMaxWidth = (usableWidth - (_markerLabelWidth * 2))
              .clamp(0.0, usableWidth)
              .toDouble();

          widgets.add(
            Positioned(
              left: padding,
              right: padding,
              bottom: 34.h,
              child: Center(
                child: _buildCountdownBadge(
                  endUtc,
                  maxWidth: badgeMaxWidth,
                  isCompact: false,
                ),
              ),
            ),
          );
          continue;
        }

        // COMPACT view: do RAW px math (no .h) against usableWidth (also raw px),
        // then hard-trim slightly so it never kisses the left/right markers.
        final double avatarRadiusPx = _avatarSize / 2.0; // RAW px
        const double extraPx = 14.0; // tweak 10–18
        const double trimPx = 12.0; // increase to make badge narrower

        final double safeInsetPx = avatarRadiusPx + extraPx;

        final double badgeMaxWidth = (usableWidth - (safeInsetPx * 2) - trimPx)
            .clamp(0.0, usableWidth)
            .toDouble();

        widgets.add(
          Positioned(
            left: padding,
            right: padding,
            bottom: 30.h,
            child: Center(
              // Use a fixed-width slot so width changes are obvious and consistent.
              child: SizedBox(
                width: badgeMaxWidth,
                child: Center(
                  child: _buildCountdownBadge(
                    endUtc,
                    maxWidth: badgeMaxWidth,
                    isCompact: true,
                  ),
                ),
              ),
            ),
          ),
        );
        continue;
      }

      final _MarkerTextParts parts = _formatMarkerPartsLocal(m.timeForLabelExact);

      widgets.add(
        Positioned(
          left: leftPos,
          bottom: 0,
          child: Column(
            children: [
              Container(
                width: 2,
                height: 8.h,
                color: appTheme.blue_gray_900_02,
              ),
              SizedBox(height: 6.h),
              SizedBox(
                width: _markerLabelWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      parts.dateLine,
                      textAlign: TextAlign.center,
                      style: (m.isEmphasized
                          ? TextStyleHelper.instance.body14BoldPlusJakartaSans
                          : TextStyleHelper
                          .instance.body14RegularPlusJakartaSans)
                          .copyWith(color: appTheme.gray_50),
                      maxLines: 1,
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      parts.timeLine,
                      textAlign: TextAlign.center,
                      style: TextStyleHelper.instance.body14RegularPlusJakartaSans
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

  bool _isValidNetworkUrl(String? s) {
    if (s == null) return false;
    final v = s.trim();
    if (v.isEmpty) return false;
    if (v == 'null' || v == 'undefined') return false;
    return v.startsWith('http://') || v.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: TimelineWidget._storyMarkerWidth,
        child: Column(
          children: [
            _buildStoryCard(),
            SizedBox(height: TimelineWidget._connectorAboveBar.h),
            SizedBox(height: TimelineWidget._barHeight.h),
            Container(
              width: 2,
              height: TimelineWidget._connectorBelowBar.h,
              color: appTheme.deep_purple_A100,
            ),
            _buildAvatar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard() {
    final String url = item.backgroundImage.trim();

    return Container(
      width: TimelineWidget._cardWidth,
      height: TimelineWidget._cardHeight.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.h),
        border: Border.all(
          color: appTheme.deep_purple_A200,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6.h),
        child: _isValidNetworkUrl(url)
            ? CachedNetworkImage(
          imageUrl: url,
          key: ValueKey('story_thumbnail_${item.storyId}_${url.hashCode}'),
          fit: BoxFit.cover,
          memCacheWidth: 200,
          memCacheHeight: 280,
          maxHeightDiskCache: 400,
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
          errorWidget: (context, url, error) => Container(
            color: const Color(0xFF2A2A3A),
            alignment: Alignment.center,
            child: Icon(
              Icons.image_not_supported,
              color: Colors.white38,
              size: 18.h,
            ),
          ),
        )
            : Container(
          color: const Color(0xFF2A2A3A),
          alignment: Alignment.center,
          child: Icon(
            Icons.image_not_supported,
            color: Colors.white38,
            size: 18.h,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final String url = item.userAvatar.trim();

    return SizedBox(
      width: TimelineWidget._avatarSize.h,
      height: TimelineWidget._avatarSize.h,
      child: Container(
        padding: const EdgeInsets.all(1),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF222D3E),
        ),
        child: ClipOval(
          child: _isValidNetworkUrl(url)
              ? CachedNetworkImage(
            imageUrl: url,
            key: ValueKey('avatar_${item.storyId}_${url.hashCode}'),
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
          )
              : Container(
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
