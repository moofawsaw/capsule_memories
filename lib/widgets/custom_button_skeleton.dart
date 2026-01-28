import '../core/app_export.dart';

/// Shimmer skeleton placeholder for buttons while loading
class CustomButtonSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;

  const CustomButtonSkeleton({
    Key? key,
    this.width,
    this.height,
    this.margin,
  }) : super(key: key);

  @override
  State<CustomButtonSkeleton> createState() => _CustomButtonSkeletonState();
}

class _CustomButtonSkeletonState extends State<CustomButtonSkeleton>
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
          width: widget.width ?? double.infinity,
          height: widget.height ?? 48.h,
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.h),
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
}
