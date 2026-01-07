import '../core/app_export.dart';

/// Shimmer skeleton placeholder for timeline header (event card) while loading
class CustomTimelineHeaderSkeleton extends StatefulWidget {
  const CustomTimelineHeaderSkeleton({Key? key}) : super(key: key);

  @override
  State<CustomTimelineHeaderSkeleton> createState() =>
      _CustomTimelineHeaderSkeletonState();
}

class _CustomTimelineHeaderSkeletonState
    extends State<CustomTimelineHeaderSkeleton>
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
          margin: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h),
          padding: EdgeInsets.all(16.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.h),
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
              // Back button and options row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40.h,
                    height: 40.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: appTheme.blue_gray_300.withAlpha(77),
                    ),
                  ),
                  Container(
                    width: 40.h,
                    height: 40.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: appTheme.blue_gray_300.withAlpha(77),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              // Category icon
              Container(
                width: 48.h,
                height: 48.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: appTheme.blue_gray_300.withAlpha(77),
                ),
              ),
              SizedBox(height: 12.h),
              // Title
              Container(
                width: 200.h,
                height: 24.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: appTheme.blue_gray_300.withAlpha(77),
                ),
              ),
              SizedBox(height: 8.h),
              // Date
              Container(
                width: 150.h,
                height: 16.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: appTheme.blue_gray_300.withAlpha(77),
                ),
              ),
              SizedBox(height: 12.h),
              // Participant avatars
              Row(
                children: List.generate(4, (index) {
                  return Container(
                    width: 32.h,
                    height: 32.h,
                    margin: EdgeInsets.only(right: index < 3 ? 8.h : 0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: appTheme.blue_gray_300.withAlpha(77),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
