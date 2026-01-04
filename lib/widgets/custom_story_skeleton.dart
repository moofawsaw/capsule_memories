import '../core/app_export.dart';

/// Shimmer skeleton placeholder for story cards while loading
class CustomStorySkeleton extends StatefulWidget {
  final bool isCompact;

  const CustomStorySkeleton({Key? key, this.isCompact = false})
      : super(key: key);

  @override
  State<CustomStorySkeleton> createState() => _CustomStorySkeletonState();
}

class _CustomStorySkeletonState extends State<CustomStorySkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use compact dimensions for smaller story cards (160.h) or default (202.h)
    final double containerHeight = widget.isCompact ? 160.h : 202.h;
    final double imageHeight = widget.isCompact ? 100.h : 140.h;
    final double bottomPadding = widget.isCompact ? 6.h : 8.h;
    final double avatarSize = widget.isCompact ? 16.h : 20.h;
    final double textWidth = widget.isCompact ? 40.h : 50.h;
    final double textHeight = widget.isCompact ? 8.h : 10.h;
    final double badgeWidth = widget.isCompact ? 60.h : 70.h;
    final double badgeHeight = widget.isCompact ? 14.h : 16.h;
    final double spacingBetweenElements = widget.isCompact ? 4.h : 6.h;

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          height: containerHeight,
          width: 140.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(-1.0 - _shimmerController.value * 2, 0.0),
              end: Alignment(1.0 - _shimmerController.value * 2, 0.0),
              colors: [
                appTheme.gray_900_01,
                appTheme.gray_900_01.withAlpha(179),
                appTheme.gray_900_01,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skeleton image area - compact or default
              Container(
                height: imageHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  color: appTheme.blue_gray_300.withAlpha(51),
                ),
              ),
              // Skeleton text area - compact or default
              Padding(
                padding: EdgeInsets.all(bottomPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info skeleton
                    Row(
                      children: [
                        Container(
                          width: avatarSize,
                          height: avatarSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: appTheme.blue_gray_300.withAlpha(77),
                          ),
                        ),
                        SizedBox(width: spacingBetweenElements),
                        Container(
                          width: textWidth,
                          height: textHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: appTheme.blue_gray_300.withAlpha(77),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spacingBetweenElements),
                    // Category badge skeleton
                    Container(
                      width: badgeWidth,
                      height: badgeHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: appTheme.blue_gray_300.withAlpha(77),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
