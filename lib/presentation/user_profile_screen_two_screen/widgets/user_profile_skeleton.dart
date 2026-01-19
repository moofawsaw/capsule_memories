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

          // Matches loaded screen
          SizedBox(height: 6.h),

          _buildStatsSkeleton(),

          if (showActions) ...[
            _buildActionsSkeleton(),
          ],

          SizedBox(height: 28.h),
          _buildStoriesGridSkeleton(),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }

  // ============================
  // HEADER
  // ============================
  Widget _buildHeaderSkeleton() {
    return Stack(
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 68.h),
          padding: EdgeInsets.only(
            left: 18.h,
            right: 18.h,
            top: 0.h,
            bottom: 10.h, // 👈 REDUCED
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.h),
          ),
          child: Column(
            children: [
              Container(
                height: 96.h,
                width: 96.h,
                decoration: BoxDecoration(
                  color: appTheme.blue_gray_300.withAlpha(35),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(height: 20.h),
              _skeletonLine(width: 110.h, height: 14.h, radius: 10.h),
              SizedBox(height: 20.h),
              _skeletonLine(width: 140.h, height: 12.h, radius: 10.h),
            ],
          ),
        ),
      ],
    );
  }


  // ============================
  // STATS (Followers / Following)
  // ============================
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
// This is the Following Button
  Widget _statCardSkeleton() {
    return Container(
      height: 46.h, // 👈 lock height (matches real button)
      padding: EdgeInsets.only(
        top: 12.h,
        bottom: 8.h,
        left: 8.h,
        right: 8.h,
      ),
      decoration: BoxDecoration(
        color: appTheme.gray_900_01,
        borderRadius: BorderRadius.circular(6.h),
        border: Border.all(
          color: appTheme.gray_900_01.withAlpha(120),
          width: 1,
        ),
      ),
      child: Center(
        child: _skeletonLine(width: 72.h, height: 12.h, radius: 10.h),
      ),
    )
    ;
  }

  // ============================
  // ACTION BUTTONS
  // ============================
  Widget _buildActionsSkeleton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center, // center the two buttons
      children: [
        _buttonSkeleton(width: 90.h),
        SizedBox(width: 8.h),
        _buttonSkeleton(width: 90.h),
      ],
    );
  }

  Widget _buttonSkeleton({required double width}) {
    return Container(
      width: width,          // ✅ fixed width now actually applies
      height: 46.h,          // ✅ fixed height
      decoration: BoxDecoration(
        color: appTheme.gray_900_01,
        borderRadius: BorderRadius.circular(14.h),
        border: Border.all(
          color: appTheme.gray_900_01.withAlpha(120),
          width: 1,
        ),
      ),
      child: Center(
        child: _skeletonLine(width: 64.h, height: 12.h, radius: 10.h),
      ),
    );
  }


  // ============================
  // STORIES GRID
  // ============================
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
      itemCount: 9,
      itemBuilder: (_, __) => const CustomStorySkeleton(
        squareTop: true,
      ),
    );
  }

  // ============================
  // SKELETON LINE
  // ============================
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
