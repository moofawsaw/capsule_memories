// lib/widgets/custom_story_list.dart

import 'package:cached_network_image/cached_network_image.dart';
import '../core/app_export.dart';

class CustomStoryList extends StatelessWidget {
  CustomStoryList({
    Key? key,
    required this.storyItems,
    this.onStoryTap,
    this.itemGap,
    this.margin,
  }) : super(key: key);

  final List<CustomStoryItem> storyItems;
  final Function(int index)? onStoryTap;
  final double? itemGap;
  final EdgeInsetsGeometry? margin;

  bool _isNetworkUrl(String? s) {
    if (s == null) return false;
    final v = s.trim();
    if (v.isEmpty) return false;
    if (v == 'null' || v == 'undefined') return false;
    return v.startsWith('http://') || v.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 20.h),
            ...List.generate(
              storyItems.length,
                  (index) => Container(
                margin: EdgeInsets.only(right: itemGap ?? 8.h),
                child: _buildStoryItem(context, storyItems[index], index),
              ),
            ),
            SizedBox(width: 12.h),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryItem(BuildContext context, CustomStoryItem item, int index) {
    final String bg = item.backgroundImage.trim();
    final String avatar = item.profileImage.trim();

    return GestureDetector(
      onTap: () => onStoryTap?.call(index),
      child: Container(
        // ✅ bg/avatar are defined right above, so this cannot be "undefined name"
        key: ValueKey(
          'story_${item.storyId ?? index}_${bg}_${avatar}',
        ),
        width: 90.h,
        height: 120.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.h),
          color: appTheme.gray_900_01,
        ),
        child: Stack(
          children: [
            // Background
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.h),
                child: _isNetworkUrl(bg)
                    ? CachedNetworkImage(
                  imageUrl: bg,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: appTheme.gray_900_02,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: appTheme.gray_900_02,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.white38,
                      size: 18.h,
                    ),
                  ),
                )
                    : Container(
                  color: appTheme.gray_900_02,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.white38,
                    size: 18.h,
                  ),
                ),
              ),
            ),

            Positioned(
              left: 12.h,
              top: 12.h,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar ring
                  Container(
                    width: 32.h,
                    height: 32.h,
                    padding: EdgeInsets.all(2.h),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.isRead
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF8B5CF6),
                      border: item.isRead
                          ? Border.all(
                        color: const Color(0xFF9CA3AF),
                        width: 2.h,
                      )
                          : null,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: appTheme.gray_900,
                      ),
                      padding: EdgeInsets.all(1.h),
                      child: ClipOval(
                        child: _isNetworkUrl(avatar)
                            ? CachedNetworkImage(
                          imageUrl: avatar,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: appTheme.gray_900_02,
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: appTheme.gray_900_02,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.person,
                              color: Colors.white38,
                              size: 16.h,
                            ),
                          ),
                        )
                            : Container(
                          color: appTheme.gray_900_02,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.person,
                            color: Colors.white38,
                            size: 16.h,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 50.h),

                  Text(
                    item.timestamp ?? '2 mins ago',
                    style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                        .copyWith(color: appTheme.white_A700, height: 1.33),
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

class CustomStoryItem {
  const CustomStoryItem({
    required this.backgroundImage,
    required this.profileImage,
    this.timestamp,
    this.navigateTo,
    this.storyId,
    this.isRead = false,
  });

  final String backgroundImage;
  final String profileImage;
  final String? timestamp;
  final String? navigateTo;
  final String? storyId;
  final bool isRead;
}
