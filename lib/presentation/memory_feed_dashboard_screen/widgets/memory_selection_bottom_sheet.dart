
import '../../../core/app_export.dart';
import '../../../widgets/custom_image_view.dart';
import '../notifier/memory_feed_dashboard_notifier.dart';
import './native_camera_recording_screen.dart';

class MemorySelectionBottomSheet extends ConsumerWidget {
  const MemorySelectionBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(memoryFeedDashboardProvider);
    final activeMemories = state.activeMemories;

    return Container(
      decoration: BoxDecoration(
        color: appTheme.gray_900_02,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.h)),
      ),
      padding: EdgeInsets.all(24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40.h,
              height: 4.h,
              decoration: BoxDecoration(
                color: appTheme.blue_gray_300,
                borderRadius: BorderRadius.circular(2.h),
              ),
            ),
          ),
          SizedBox(height: 20.h),

          // Title
          Text(
            'Select Memory',
            style: TextStyleHelper.instance.title20BoldPlusJakartaSans
                .copyWith(color: appTheme.gray_50),
          ),
          SizedBox(height: 8.h),
          Text(
            'Choose which memory to post your story to',
            style: TextStyleHelper.instance.body14MediumPlusJakartaSans
                .copyWith(color: appTheme.blue_gray_300),
          ),
          SizedBox(height: 24.h),

          // Memory list
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: activeMemories.length,
            separatorBuilder: (context, index) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final memory = activeMemories[index];
              return _buildMemoryCard(context, memory);
            },
          ),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }

  Widget _buildMemoryCard(BuildContext context, Map<String, dynamic> memory) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NativeCameraRecordingScreen(
              memoryId: memory['id'],
              memoryTitle: memory['title'],
              categoryIcon: memory['category_icon'],
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16.h),
        decoration: BoxDecoration(
          color: appTheme.blue_gray_900_01,
          borderRadius: BorderRadius.circular(12.h),
          border: Border.all(
            color: appTheme.blue_gray_300.withAlpha(51),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            if (memory['category_icon'] != null &&
                memory['category_icon'].toString().isNotEmpty)
              CustomImageView(
                imagePath: memory['category_icon'],
                width: 32.h,
                height: 32.h,
                fit: BoxFit.contain,
              ),
            SizedBox(width: 12.h),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memory['title'] ?? 'Untitled Memory',
                    style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                        .copyWith(color: appTheme.gray_50),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    memory['category_name'] ?? 'Custom',
                    style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                        .copyWith(color: appTheme.blue_gray_300),
                  ),
                ],
              ),
            ),
            CustomImageView(
              imagePath: ImageConstant.imgArrowLeft,
              width: 20.h,
              height: 20.h,
              color: appTheme.gray_50,
            ),
          ],
        ),
      ),
    );
  }
}
