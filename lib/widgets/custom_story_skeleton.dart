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
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // IMPORTANT:
    // MemoriesDashboardScreen compact skeleton wrapper uses:
    // - item width: 120.h
    // - available height: 140.h
    //
    // So compact MUST be 120.h x 140.h to match the real cards and avoid overflow/mismatch.
    final double containerWidth = widget.isCompact ? 120.h : 140.h;
    final double containerHeight = widget.isCompact ? 140.h : 202.h;

    // Tune the internal blocks to fit within the container.
    final double imageHeight = widget.isCompact ? 92.h : 140.h;
    final double padding = widget.isCompact ? 6.h : 8.h;

    final double avatarSize = widget.isCompact ? 16.h : 20.h;
    final double textWidth = widget.isCompact ? 44.h : 50.h;
    final double textHeight = widget.isCompact ? 8.h : 10.h;

    final double badgeWidth = widget.isCompact ? 56.h : 70.h;
    final double badgeHeight = widget.isCompact ? 14.h : 16.h;

    final double spacing = widget.isCompact ? 4.h : 6.h;

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          height: containerHeight,
          width: containerWidth,
          decoration: BoxDecoration(
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
              // Skeleton image area
              Container(
                height: imageHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
                  color: appTheme.blue_gray_300.withAlpha(51),
                ),
              ),

              // Skeleton meta/text area
              Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        SizedBox(width: spacing),
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
                    SizedBox(height: spacing),
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
