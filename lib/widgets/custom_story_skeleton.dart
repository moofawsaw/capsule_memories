import '../core/app_export.dart';

/// Shimmer skeleton placeholder for story cards while loading
class CustomStorySkeleton extends StatefulWidget {
  final bool isCompact;
  final bool squareTop; // ✅ MUST EXIST

  const CustomStorySkeleton({
    Key? key,
    this.isCompact = false,
    this.squareTop = false, // ✅ MUST EXIST
  }) : super(key: key);

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool hasTightWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0;
        final bool hasTightHeight =
            constraints.maxHeight.isFinite && constraints.maxHeight > 0;

        // Fallbacks (used only when not tightly constrained)
        final double fallbackW = widget.isCompact ? 90.h : 140.h;
        final double fallbackH = widget.isCompact ? 120.h : 202.h;

        // GridView cells will drive these sizes (profile case = third size)
        final double w = hasTightWidth ? constraints.maxWidth : fallbackW;
        final double h = hasTightHeight ? constraints.maxHeight : fallbackH;

        // ✅ CRITICAL:
        // If squareTop=true (profile grid), the entire card MUST be square,
        // including the header block.
        final bool forceSquare = widget.squareTop;
        final double cardRadius =
        forceSquare ? 0.h : 12.h;

        // Instagram-style profile grid: media-only tiles (no avatar/meta skeleton).
        if (forceSquare) {
          return AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, _) {
              return Container(
                width: w,
                height: h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.zero,
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
              );
            },
          );
        }

        // Internal layout scales to any size
        final double pad = (h * 0.06).clamp(6.h, 10.h);
        final double avatar = (h * 0.13).clamp(16.h, 22.h);
        final double lineH = (h * 0.07).clamp(8.h, 12.h);
        final double badgeH = (h * 0.10).clamp(14.h, 18.h);
        final double gap = (h * 0.035).clamp(4.h, 8.h);

        final double bottomArea = pad * 2 + avatar + gap + badgeH;
        final double imageH = (h - bottomArea).clamp(50.h, h);

        final double textW = (w * 0.52).clamp(40.h, 70.h);
        final double badgeW = (w * 0.62).clamp(52.h, 90.h);

        return AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, _) {
            return Container(
              width: w,
              height: h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(cardRadius),
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
                  // Header / image block
                  Container(
                    height: imageH,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: appTheme.blue_gray_300.withAlpha(51),
                      // ✅ GUARANTEED: profile grid passes squareTop:true => no rounding here
                      borderRadius: forceSquare
                          ? BorderRadius.zero
                          : BorderRadius.vertical(
                        top: Radius.circular(12.h),
                      ),
                    ),
                  ),

                  // Meta area
                  Padding(
                    padding: EdgeInsets.all(pad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: avatar,
                          child: Row(
                            children: [
                              Container(
                                width: avatar,
                                height: avatar,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: appTheme.blue_gray_300.withAlpha(77),
                                ),
                              ),
                              SizedBox(width: gap),
                              Container(
                                width: textW,
                                height: lineH,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4.h),
                                  color: appTheme.blue_gray_300.withAlpha(77),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: gap),
                        Container(
                          width: badgeW,
                          height: badgeH,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.h),
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
      },
    );
  }
}
