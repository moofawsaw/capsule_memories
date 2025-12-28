import '../core/app_export.dart';
import './custom_icon_button.dart';
import './custom_image_view.dart';

/** 
 * CustomMusicList - A reusable list component for displaying music/audio items
 * 
 * This component renders a vertical list of music items, each containing:
 * - Leading currency/category image
 * - Title and subtitle with story count
 * - Trailing play button
 * 
 * Features:
 * - Responsive design using SizeUtils extensions
 * - Customizable item data through MusicListItem model
 * - Optional callbacks for item and play button interactions
 * - Consistent spacing and styling across all items
 */
class CustomMusicList extends StatelessWidget {
  CustomMusicList({
    Key? key,
    required this.items,
    this.onItemTap,
    this.onPlayTap,
    this.itemSpacing,
    this.margin,
  }) : super(key: key);

  /// List of music items to display
  final List<MusicListItem> items;

  /// Callback when an item is tapped (excluding play button)
  final Function(int index, MusicListItem item)? onItemTap;

  /// Callback when play button is tapped
  final Function(int index, MusicListItem item)? onPlayTap;

  /// Vertical spacing between items
  final double? itemSpacing;

  /// Margin around the entire list
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ListView.builder(
        shrinkWrap: true,
        physics: ClampingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(
              bottom: index < items.length - 1 ? (itemSpacing ?? 46.h) : 0,
            ),
            child: _buildMusicItem(context, index, items[index]),
          );
        },
      ),
    );
  }

  Widget _buildMusicItem(BuildContext context, int index, MusicListItem item) {
    return GestureDetector(
      onTap: onItemTap != null ? () => onItemTap!(index, item) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Leading image
          CustomImageView(
            imagePath: item.leadingImagePath ?? ImageConstant.imgDollar,
            height: 26.h,
            width: 44.h,
          ),

          SizedBox(width: 22.h),

          // Content section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  item.title ?? 'Swag Song',
                  style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                ),

                SizedBox(height: 18.h),

                // Subtitle with icon
                Row(
                  children: [
                    CustomImageView(
                      imagePath: item.subtitleIconPath ??
                          ImageConstant.imgIconsBlueGray300,
                      height: 20.h,
                      width: 20.h,
                    ),
                    SizedBox(width: 4.h),
                    Text(
                      item.subtitle ?? '121 stories',
                      style:
                          TextStyleHelper.instance.body12MediumPlusJakartaSans,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Play button
          CustomIconButton(
            iconPath:
                item.playButtonIconPath ?? ImageConstant.imgPlayCircleGray50,
            height: 34.h,
            width: 34.h,
            padding: EdgeInsets.all(2.h),
            onTap: onPlayTap != null ? () => onPlayTap!(index, item) : null,
          ),
        ],
      ),
    );
  }
}

/// Data model for music list items
class MusicListItem {
  MusicListItem({
    this.title,
    this.subtitle,
    this.leadingImagePath,
    this.subtitleIconPath,
    this.playButtonIconPath,
    this.id,
  });

  /// Main title text
  final String? title;

  /// Subtitle text (e.g., "121 stories")
  final String? subtitle;

  /// Path to the leading image
  final String? leadingImagePath;

  /// Path to the subtitle icon
  final String? subtitleIconPath;

  /// Path to the play button icon
  final String? playButtonIconPath;

  /// Unique identifier for the item
  final String? id;
}
