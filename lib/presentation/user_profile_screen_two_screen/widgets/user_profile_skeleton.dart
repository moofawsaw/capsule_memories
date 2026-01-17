import '../../../core/app_export.dart';
import '../../../widgets/custom_story_skeleton.dart';

class UserProfileSkeleton extends StatelessWidget {
  const UserProfileSkeleton({
    Key? key,
    this.showActions = false,
  }) : super(key: key);

  final bool showActions;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        top: 24.h,
        left: 18.h,
        right: 18.h,
      ),
      child: Column(
        children: [
          _buildHeaderSkeleton(),
          SizedBox(height: 12.h),
          _buildStatsSkeleton(),
          if (showActions) ...[
            SizedBox(height: 16.h),
            _buildActionsSkeleton(),
          ],
          SizedBox(height: 28.h),
          _buildStoriesGridSkeleton(),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }

  Widget _buildHeaderSkeleton() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.h, vertical: 14.h),
      decoration: BoxDecoration(
        color: appTheme.gray_900_01,
        borderRadius: BorderRadius.circular(22.h),
        border: Border.all(
          color: appTheme.gray_900_01.withAlpha(120),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Avatar circle
          Container(
            height: 96.h,
            width: 96.h,
            decoration: BoxDecoration(
              color: appTheme.blue_gray_300.withAlpha(35),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(height: 12.h),

          // Display name line
          _skeletonLine(width: 140.h, height: 14.h, radius: 10.h),
          SizedBox(height: 8.h),

          // Username line
          _skeletonLine(width: 110.h, height: 12.h, radius: 10.h),
        ],
      ),
    );
  }

  Widget _buildStatsSkeleton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _statCardSkeleton(),
        SizedBox(width: 12.h),
        _statCardSkeleton(),
      ],
    );
  }

  Widget _statCardSkeleton() {
    return Container(
      width: 128.h,
      padding: EdgeInsets.symmetric(horizontal: 14.h, vertical: 12.h),
      decoration: BoxDecoration(
        color: appTheme.gray_900_01,
        borderRadius: BorderRadius.circular(18.h),
        border: Border.all(
          color: appTheme.gray_900_01.withAlpha(120),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _skeletonLine(width: 44.h, height: 16.h, radius: 10.h),
          SizedBox(height: 8.h),
          _skeletonLine(width: 60.h, height: 12.h, radius: 10.h),
        ],
      ),
    );
  }

  Widget _buildActionsSkeleton() {
    return Row(
      children: [
        Expanded(child: _buttonSkeleton()),
        SizedBox(width: 8.h),
        Expanded(child: _buttonSkeleton()),
      ],
    );
  }

  Widget _buttonSkeleton() {
    return Container(
      height: 46.h,
      decoration: BoxDecoration(
        color: appTheme.gray_900_01,
        borderRadius: BorderRadius.circular(14.h),
        border: Border.all(
          color: appTheme.gray_900_01.withAlpha(120),
          width: 1,
        ),
      ),
      child: Center(
        child: _skeletonLine(width: 90.h, height: 12.h, radius: 10.h),
      ),
    );
  }

  Widget _buildStoriesGridSkeleton() {
    const gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: 1,
      mainAxisSpacing: 1,
      childAspectRatio: 0.65,
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: gridDelegate,
      itemCount: 9, // 3x3 gives a solid "profile grid loading" look
      itemBuilder: (_, __) => const CustomStorySkeleton(),
    );
  }

  Widget _skeletonLine({
    required double width,
    required double height,
    required double radius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: appTheme.blue_gray_300.withAlpha(35),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
