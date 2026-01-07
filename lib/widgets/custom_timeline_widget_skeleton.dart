import '../core/app_export.dart';

/// Shimmer skeleton placeholder for timeline widget area while loading
class CustomTimelineWidgetSkeleton extends StatefulWidget {
  const CustomTimelineWidgetSkeleton({Key? key}) : super(key: key);

  @override
  State<CustomTimelineWidgetSkeleton> createState() =>
      _CustomTimelineWidgetSkeletonState();
}

class _CustomTimelineWidgetSkeletonState
    extends State<CustomTimelineWidgetSkeleton>
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
          margin: EdgeInsets.symmetric(horizontal: 16.h),
          padding: EdgeInsets.symmetric(vertical: 20.h),
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
            children: [
              // Timeline title bar skeleton
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 100.h,
                    height: 16.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: appTheme.blue_gray_300.withAlpha(77),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 48.h,
                        height: 48.h,
                        margin: EdgeInsets.only(right: 8.h),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24.h),
                          color: appTheme.blue_gray_300.withAlpha(77),
                        ),
                      ),
                      Container(
                        width: 48.h,
                        height: 48.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24.h),
                          color: appTheme.blue_gray_300.withAlpha(77),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              // Timeline dots and cards
              ...List.generate(3, (index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 20.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline dot
                      Column(
                        children: [
                          Container(
                            width: 12.h,
                            height: 12.h,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: appTheme.blue_gray_300.withAlpha(77),
                            ),
                          ),
                          if (index < 2)
                            Container(
                              width: 2.h,
                              height: 60.h,
                              margin: EdgeInsets.symmetric(vertical: 4.h),
                              color: appTheme.blue_gray_300.withAlpha(77),
                            ),
                        ],
                      ),
                      SizedBox(width: 16.h),
                      // Story card skeleton
                      Expanded(
                        child: Container(
                          height: 100.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: appTheme.blue_gray_300.withAlpha(51),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
