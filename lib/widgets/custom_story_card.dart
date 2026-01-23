import '../core/app_export.dart';
import '../core/utils/memory_categories.dart';
import './custom_image_view.dart';

class CustomStoryCard extends StatelessWidget {
  CustomStoryCard({
    Key? key,
    required this.userName,
    required this.userAvatar,
    required this.backgroundImage,
    this.categoryText,
    this.categoryIcon,
    this.timestamp,
    this.onTap,
    this.onLongPress,
    this.enableLongPressActions = true,
    this.width,
    this.height,
    this.margin,
    this.showDelete = false,
    this.onDelete,

    // ✅ optional, so you can override ONLY on /profile
    this.borderRadius,
  }) : super(key: key);

  final String userName;
  final String userAvatar;
  final String backgroundImage;

  final String? categoryText;
  final String? categoryIcon;
  final String? timestamp;

  final VoidCallback? onTap;

  /// ✅ Long-press hook (parent shows action sheet/dialog)
  final VoidCallback? onLongPress;

  /// ✅ Allows disabling long-press even if handler is passed
  final bool enableLongPressActions;

  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;

  // ✅ Delete support (UI only)
  final bool showDelete;
  final VoidCallback? onDelete;

  // ✅ override card radius per usage (profile-only, feed can keep default)
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final category = categoryText != null && (categoryIcon == null)
        ? MemoryCategories.getByName(categoryText!)
        : MemoryCategories.custom;

    // ✅ Single source of truth for this card's radius
    final BorderRadius cardRadius = borderRadius ?? BorderRadius.circular(8.h);

    // ✅ Long-press enabled only if a handler is provided and flag is true
    final bool longPressEnabled =
        enableLongPressActions && onLongPress != null;

    return Container(
      width: width ?? 116.h,
      height: height ?? 202.h,
      margin: margin,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: longPressEnabled ? () => onLongPress!.call() : null,
        child: Container(
          decoration: BoxDecoration(
            color: appTheme.gray_900_01,
            border: Border.all(
              color: appTheme.gray_900_02,
              width: 1,
            ),
            borderRadius: cardRadius,
          ),
          child: Stack(
            children: [
              // Background story image (FULL CARD)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: cardRadius,
                  child: _CoverImage(
                    imagePath: backgroundImage,
                  ),
                ),
              ),

              // ✅ Delete button overlay (top-right)
              if (showDelete)
                Positioned(
                  top: 8.h,
                  right: 8.h,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onDelete,
                    child: Container(
                      padding: EdgeInsets.all(6.h),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(140),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withAlpha(40),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        size: 18.h,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // Overlay content
              Positioned(
                left: 6.h,
                right: 6.h,
                top: 12.h,
                bottom: 12.h,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileAvatar(context),
                    Spacer(),
                    _buildUserInfo(context, category),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context) {
    final double size = 32.h;

    return Container(
      width: size,
      height: size,
      margin: EdgeInsets.only(left: 4.h),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: appTheme.deep_purple_A100,
          width: 2,
        ),
        color: const Color(0xFF222D3E),
      ),
      child: ClipOval(
        child: _CoverAvatar(
          imagePath: userAvatar,
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, MemoryCategory category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (userName.isNotEmpty)
          Text(
            userName,
            style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                .copyWith(color: appTheme.white_A700, height: 1.29),
          ),
        if (categoryText != null) ...[
          SizedBox(height: userName.isNotEmpty ? 18.h : 0),
          _buildCategoryBadge(context, category),
        ],
        if (timestamp != null) ...[
          SizedBox(height: 4.h),
          Text(
            timestamp!,
            style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                .copyWith(color: appTheme.white_A700, height: 1.33),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryBadge(BuildContext context, MemoryCategory category) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.h, vertical: 2.h),
      decoration: BoxDecoration(
        color: appTheme.gray_900_02,
        borderRadius: BorderRadius.circular(12.h),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (categoryIcon != null && categoryIcon!.isNotEmpty)
            CustomImageView(
              imagePath: categoryIcon!,
              width: 20.h,
              height: 20.h,
              fit: BoxFit.contain,
            )
          else
            Text(
              category.emoji,
              style: TextStyle(fontSize: 20.h),
            ),
          SizedBox(width: 8.h),
          Text(
            categoryText ?? '',
            style: TextStyleHelper.instance.body12BoldPlusJakartaSans
                .copyWith(color: appTheme.gray_50, height: 1.33),
          ),
        ],
      ),
    );
  }
}

/// Forces true cover behavior for story card backgrounds (prevents stretching).
class _CoverImage extends StatelessWidget {
  final String imagePath;

  const _CoverImage({
    Key? key,
    required this.imagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isNetwork = imagePath.startsWith('http');

    if (isNetwork) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => Container(
          color: appTheme.gray_900_02,
          child: Icon(
            Icons.image_not_supported_outlined,
            color: appTheme.blue_gray_300,
          ),
        ),
      );
    }

    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      width: double.infinity,
      height: double.infinity,
    );
  }
}

/// Forces true cover behavior for avatars (prevents stretching).
class _CoverAvatar extends StatelessWidget {
  final String imagePath;

  const _CoverAvatar({
    Key? key,
    required this.imagePath,
  }) : super(key: key);

  bool _isNetwork(String s) =>
      s.trim().startsWith('http://') || s.trim().startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final String path = imagePath.trim();

    if (path.isEmpty || path == 'null' || path == 'undefined') {
      return Container(
        color: appTheme.gray_900_02,
        alignment: Alignment.center,
        child: Icon(
          Icons.person,
          color: appTheme.blue_gray_300,
          size: 18.h,
        ),
      );
    }

    if (_isNetwork(path)) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => Container(
          color: appTheme.gray_900_02,
          alignment: Alignment.center,
          child: Icon(
            Icons.person,
            color: appTheme.blue_gray_300,
            size: 18.h,
          ),
        ),
      );
    }

    return Image.asset(
      path,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      width: double.infinity,
      height: double.infinity,
    );
  }
}