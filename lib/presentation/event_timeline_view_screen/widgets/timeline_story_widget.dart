import '../../../core/app_export.dart';
import '../../../widgets/custom_image_view.dart';

/// Timeline Story Widget - Dynamically positions stories along timeline based on timestamps
class TimelineStoryWidget extends StatelessWidget {
  final List<TimelineStoryItem> stories;
  final DateTime memoryStartTime;
  final DateTime memoryEndTime;
  final double timelineHeight;
  final Function(String storyId)? onStoryTap;

  const TimelineStoryWidget({
    Key? key,
    required this.stories,
    required this.memoryStartTime,
    required this.memoryEndTime,
    this.timelineHeight = 200,
    this.onStoryTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) {
      return SizedBox.shrink();
    }

    // Use milliseconds for precise calculations
    final totalDurationMs =
        memoryEndTime.difference(memoryStartTime).inMilliseconds.toDouble();

    if (totalDurationMs <= 0) {
      return SizedBox.shrink();
    }

    return Container(
      height: timelineHeight.h,
      margin: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 12.h),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;

          return Column(
            children: [
              // Story cards positioned using Stack
              Expanded(
                child: Stack(
                  children: _buildPositionedStories(
                      context, totalDurationMs, availableWidth),
                ),
              ),
              SizedBox(height: 16.h),
              // Timeline with avatars
              SizedBox(
                height: 48.h,
                child: Stack(
                  children: [
                    // Pink timeline line
                    Positioned(
                      top: 16.h,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              appTheme.deep_purple_A100.withAlpha(77),
                              appTheme.deep_purple_A100,
                              appTheme.deep_purple_A100.withAlpha(77),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Avatars positioned using same calculations
                    ..._buildPositionedAvatars(
                        context, totalDurationMs, availableWidth),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Single positioning function - returns clamped centerX in logical pixels
  double _centerX({
    required DateTime postedAt,
    required DateTime start,
    required DateTime end,
    required double availableWidth,
    required double clampHalfWidth,
  }) {
    // Milliseconds precision
    final total = (end.difference(start)).inMilliseconds.toDouble();
    final elapsed = (postedAt.difference(start)).inMilliseconds.toDouble();

    // Calculate position percentage
    final p = (elapsed / total).clamp(0.0, 1.0);

    // Raw centerX position
    final rawCenterX = availableWidth * p;

    // Clamp the center ONCE
    final centerX =
        rawCenterX.clamp(clampHalfWidth, availableWidth - clampHalfWidth);

    return centerX;
  }

  /// Build story cards - derives left from centerX
  List<Widget> _buildPositionedStories(
      BuildContext context, double totalDurationMs, double availableWidth) {
    final cardWidth = 90.0.w;
    final cardHalfWidth = cardWidth / 2;
    final sortedStories = List<TimelineStoryItem>.from(stories)
      ..sort((a, b) => a.postedAt.compareTo(b.postedAt));

    return sortedStories.map((story) {
      // Get centerX from single positioning function
      final centerX = _centerX(
        postedAt: story.postedAt,
        start: memoryStartTime,
        end: memoryEndTime,
        availableWidth: availableWidth,
        clampHalfWidth: cardHalfWidth,
      );

      // Derive left position from centerX - NO clamp()
      final cardLeft = centerX - cardHalfWidth;

      return Positioned(
        left: cardLeft,
        top: 0,
        child: _buildStoryCard(context, story, cardWidth),
      );
    }).toList();
  }

  /// Build avatars - derives left from same centerX
  List<Widget> _buildPositionedAvatars(
      BuildContext context, double totalDurationMs, double availableWidth) {
    final avatarSize = 32.0.w;
    final avatarHalfWidth = avatarSize / 2;
    final cardHalfWidth = 90.0.w / 2;
    final sortedStories = List<TimelineStoryItem>.from(stories)
      ..sort((a, b) => a.postedAt.compareTo(b.postedAt));

    return sortedStories.map((story) {
      // Get SAME centerX from single positioning function
      final centerX = _centerX(
        postedAt: story.postedAt,
        start: memoryStartTime,
        end: memoryEndTime,
        availableWidth: availableWidth,
        clampHalfWidth: cardHalfWidth,
      );

      // Derive avatar left position from centerX - NO clamp()
      final avatarLeft = centerX - avatarHalfWidth;

      return Positioned(
        left: avatarLeft,
        top: 8.h,
        child: Container(
          width: avatarSize,
          height: avatarSize,
          padding: EdgeInsets.all(2.0.w),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: appTheme.deep_purple_A100,
              width: 2.0.w,
            ),
            boxShadow: [
              BoxShadow(
                color: appTheme.deep_purple_A100.withAlpha(77),
                blurRadius: 6.h,
                spreadRadius: 1.h,
              ),
            ],
          ),
          child: CustomImageView(
            imagePath: story.userAvatar,
            width: 28.0.w,
            height: 28.0.w,
            fit: BoxFit.cover,
            radius: BorderRadius.circular(14.0.w),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildStoryCard(
      BuildContext context, TimelineStoryItem story, double cardWidth) {
    return GestureDetector(
      onTap: () {
        if (story.storyId != null && onStoryTap != null) {
          onStoryTap!(story.storyId!);
        }
      },
      child: Container(
        width: cardWidth,
        height: 120.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(51),
              blurRadius: 8.h,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Stack(
          children: [
            CustomImageView(
              imagePath: story.backgroundImage,
              width: cardWidth,
              height: 120.h,
              fit: BoxFit.cover,
              radius: BorderRadius.circular(12.0),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withAlpha(102),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8.h,
              left: 8.0.w,
              right: 8.0.w,
              child: Text(
                story.timeLabel ?? _formatTime(story.postedAt),
                style:
                    TextStyleHelper.instance.body10BoldPlusJakartaSans.copyWith(
                  color: appTheme.white_A700,
                  shadows: [
                    Shadow(
                      color: Colors.black.withAlpha(128),
                      blurRadius: 4.h,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}

class TimelineStoryItem {
  const TimelineStoryItem({
    required this.backgroundImage,
    required this.userAvatar,
    required this.postedAt,
    this.timeLabel,
    this.storyId,
    @Deprecated('Use storyId with onStoryTap callback instead') this.onTap,
  });

  final String backgroundImage;
  final String userAvatar;
  final DateTime postedAt;
  final String? timeLabel;
  final String? storyId;
  @Deprecated('Use storyId with onStoryTap callback instead')
  final VoidCallback? onTap;
}
