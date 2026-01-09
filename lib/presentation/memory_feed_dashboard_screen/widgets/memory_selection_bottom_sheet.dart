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
    bool isExpiringUrgently = false;
    final expirationText = (memory['expiration_text'] ?? '').toString();
    if (expirationText.isNotEmpty) {
      final regex = RegExp(r'(\d+)\s*(hour|minute)');
      final match = regex.firstMatch(expirationText);
      if (match != null) {
        final value = int.tryParse(match.group(1) ?? '0') ?? 0;
        final unit = match.group(2);
        if (unit == 'hour' && value < 3) {
          isExpiringUrgently = true;
        } else if (unit == 'minute') {
          isExpiringUrgently = true;
        }
      }
    }

    final rawVis = memory['visibility'];
    final normVis = (rawVis ?? '').toString().trim().toLowerCase();
    final isPublic = normVis == 'public';

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

            SizedBox(width: 20.h), // 👈 increased spacing between icon & text

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── TITLE + VISIBILITY BADGE ───────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          memory['title'] ?? 'Untitled Memory',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyleHelper
                              .instance
                              .title16BoldPlusJakartaSans
                              .copyWith(
                            fontSize: 17, // slightly larger
                            fontWeight: FontWeight.w600,
                            color: appTheme.gray_50,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.h,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: memory['visibility'] == 'public'
                              ? appTheme.green_500.withOpacity(0.15)
                              : appTheme.blue_gray_300.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12.h),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              memory['visibility'] == 'public'
                                  ? Icons.public
                                  : Icons.lock,
                              size: 14.h,
                              color: memory['visibility'] == 'public'
                                  ? appTheme.green_500
                                  : appTheme.blue_gray_300,
                            ),
                            SizedBox(width: 4.h),
                            Text(
                              memory['visibility'] == 'public'
                                  ? 'Public'
                                  : 'Private',
                              style: TextStyleHelper
                                  .instance
                                  .body12MediumPlusJakartaSans
                                  .copyWith(
                                color: memory['visibility'] == 'public'
                                    ? appTheme.green_500
                                    : appTheme.blue_gray_300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 6.h),

                  // ── METADATA ───────────────────────────────────────────────
                  Text(
                    memory['expiration_text'] ?? 'No expiration',
                    style: TextStyleHelper
                        .instance
                        .body12MediumPlusJakartaSans
                        .copyWith(
                      fontSize: 12,
                      color: isExpiringUrgently
                          ? appTheme.deep_orange_A700
                          : appTheme.blue_gray_300.withOpacity(0.85),
                    ),
                  ),

                  SizedBox(height: 2.h),

                  Text(
                    'created ${memory['created_date'] ?? 'Unknown'}'
                        '${(memory['creator_name'] != null && memory['creator_name'].toString().isNotEmpty) ? ' by ${memory['creator_name']}' : ''}',
                    style: TextStyleHelper.instance.body12MediumPlusJakartaSans.copyWith(
                      fontSize: 11.h,
                      color: appTheme.blue_gray_300.withAlpha(179),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
