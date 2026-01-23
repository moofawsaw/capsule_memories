import '../core/app_export.dart';

/// Shimmer skeleton placeholder for memory cards while loading
class CustomMemorySkeleton extends StatefulWidget {
  const CustomMemorySkeleton({Key? key}) : super(key: key);

  @override
  State<CustomMemorySkeleton> createState() => _CustomMemorySkeletonState();
}

class _CustomMemorySkeletonState extends State<CustomMemorySkeleton>
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
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          // ✅ Match loaded card width
          width: 300.h,
          height: 348.h,

          // ✅ IMPORTANT: spacing is handled by CustomPublicMemories wrapper margins
          margin: EdgeInsets.zero,

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
              Container(
                height: 180.h,
                decoration: BoxDecoration(
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(16.h)),
                  color: appTheme.blue_gray_300.withAlpha(51),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(14.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40.h,
                      height: 40.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: appTheme.blue_gray_300.withAlpha(77),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      width: 180.h,
                      height: 20.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: appTheme.blue_gray_300.withAlpha(77),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: 120.h,
                      height: 14.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: appTheme.blue_gray_300.withAlpha(77),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    SizedBox(
                      height: 28.h,
                      child: Row(
                        children: List.generate(3, (index) {
                          return Container(
                            width: 28.h,
                            height: 28.h,
                            margin: EdgeInsets.only(
                              right: index < 2 ? 8.w : 0,
                            ),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: appTheme.blue_gray_300.withAlpha(77),
                            ),
                          );
                        }),
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