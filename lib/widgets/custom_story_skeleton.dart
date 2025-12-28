import '../core/app_export.dart';

/// Shimmer skeleton placeholder for story cards while loading
class CustomStorySkeleton extends StatefulWidget {
  const CustomStorySkeleton({Key? key}) : super(key: key);

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
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          height: 202.h,
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
              // Skeleton image area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(8)),
                    color: appTheme.blue_gray_300.withAlpha(51),
                  ),
                ),
              ),
              // Skeleton text area
              Padding(
                padding: EdgeInsets.all(8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info skeleton
                    Row(
                      children: [
                        Container(
                          width: 24.h,
                          height: 24.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: appTheme.blue_gray_300.withAlpha(77),
                          ),
                        ),
                        SizedBox(width: 8.h),
                        Container(
                          width: 60.h,
                          height: 12.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: appTheme.blue_gray_300.withAlpha(77),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    // Category badge skeleton
                    Container(
                      width: 80.h,
                      height: 20.h,
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
