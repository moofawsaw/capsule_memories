import '../core/app_export.dart';
import './custom_button.dart';
import './custom_icon_button.dart';
import './custom_image_view.dart';

/**
 * CustomSocialPostCard - A comprehensive social media post component featuring user profile information,
 * category tags, interactive action buttons, reaction chips, and engagement counters.
 * 
 * This component provides a complete social post layout with:
 * - User avatar with optional status indicator overlay
 * - User information display (name, timestamp)
 * - Category chip with custom icon and styling
 * - Vertical action buttons for post interactions
 * - Horizontal reaction chips with custom labels
 * - Reaction counters with emoji icons and counts
 * - Responsive design and customizable styling
 */
class CustomSocialPostCard extends StatelessWidget {
  const CustomSocialPostCard({
    Key? key,
    required this.userProfileImage,
    required this.userName,
    required this.timestamp,
    this.statusIcon,
    this.onUserTap,
    this.categoryLabel,
    this.categoryIcon,
    this.onCategoryTap,
    this.actionButtons,
    this.reactionChips,
    this.reactionCounters,
    this.backgroundColor,
    this.margin,
    this.padding,
  }) : super(key: key);

  /// User's profile image path
  final String userProfileImage;

  /// User's display name
  final String userName;

  /// Post timestamp text
  final String timestamp;

  /// Optional status indicator icon path
  final String? statusIcon;

  /// Callback when user profile is tapped
  final VoidCallback? onUserTap;

  /// Category chip label text
  final String? categoryLabel;

  /// Category chip icon path
  final String? categoryIcon;

  /// Callback when category chip is tapped
  final VoidCallback? onCategoryTap;

  /// List of action button configurations
  final List<CustomSocialActionButton>? actionButtons;

  /// List of reaction chip configurations
  final List<CustomSocialReactionChip>? reactionChips;

  /// List of reaction counter configurations
  final List<CustomSocialReactionCounter>? reactionCounters;

  /// Background color of the post card
  final Color? backgroundColor;

  /// External margin of the card
  final EdgeInsetsGeometry? margin;

  /// Internal padding of the card
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: backgroundColor ?? Color(0xFF12151D),
        borderRadius: BorderRadius.circular(8.h),
      ),
      child: Column(
        children: [
          _buildUserSection(context),
          if (actionButtons?.isNotEmpty == true ||
              reactionChips?.isNotEmpty == true ||
              reactionCounters?.isNotEmpty == true)
            _buildInteractionSection(context),
        ],
      ),
    );
  }

  Widget _buildUserSection(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 14.h, left: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserAvatar(context),
          SizedBox(width: 12.h),
          Expanded(
            child: _buildUserInfo(context),
          ),
          if (categoryLabel != null) _buildCategoryChip(context),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context) {
    return InkWell(
      onTap: onUserTap,
      child: Stack(
        children: [
          CustomImageView(
            imagePath: userProfileImage,
            height: 52.h,
            width: 52.h,
            fit: BoxFit.cover,
            radius: BorderRadius.circular(26.h),
          ),
          if (statusIcon != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: appTheme.gray_900_02,
                    width: 2.h,
                  ),
                  borderRadius: BorderRadius.circular(12.h),
                ),
                child: CustomImageView(
                  imagePath: statusIcon!,
                  height: 20.h,
                  width: 20.h,
                  fit: BoxFit.cover,
                  radius: BorderRadius.circular(10.h),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 7.h),
        Text(
          userName,
          style: TextStyleHelper.instance.title18BoldPlusJakartaSans
              .copyWith(color: appTheme.gray_50),
        ),
        SizedBox(height: 3.h),
        Text(
          timestamp,
          style: TextStyleHelper.instance.body14RegularPlusJakartaSans
              .copyWith(color: appTheme.blue_gray_300),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 11.h),
      child: CustomButton(
        text: categoryLabel,
        leftIcon: categoryIcon,
        onPressed: onCategoryTap,
        buttonStyle: CustomButtonStyle.fillDark,
        buttonTextStyle: CustomButtonTextStyle
            .bodySmallPrimary, // Modified: Replaced unavailable text style
        padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 8.h),
      ),
    );
  }

  Widget _buildInteractionSection(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 16.h, right: 6.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (actionButtons?.isNotEmpty == true) _buildActionButtons(context),
          if (reactionChips?.isNotEmpty == true) _buildReactionChips(context),
          if (reactionCounters?.isNotEmpty == true)
            _buildReactionCounters(context),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.h, vertical: 8.h),
          decoration: BoxDecoration(
            color: appTheme.gray_900_01,
            borderRadius: BorderRadius.circular(26.h),
          ),
          child: Column(
            children: actionButtons!.asMap().entries.map((entry) {
              final index = entry.key;
              final button = entry.value;
              return Container(
                margin: EdgeInsets.only(
                  bottom: index < actionButtons!.length - 1 ? 8.h : 0,
                ),
                child: CustomImageView(
                  imagePath: button.iconPath,
                  height: 40.h,
                  width: 40.h,
                  onTap: button.onTap,
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 104.h),
        ...actionButtons!
            .skip(3)
            .map((button) => Container(
                  margin: EdgeInsets.only(bottom: 24.h),
                  child: CustomIconButton(
                    iconPath: button.iconPath,
                    onTap: button.onTap,
                    backgroundColor: appTheme.color3B8724,
                    borderRadius: 24.h,
                    height: 48.h,
                    width: 48.h,
                  ),
                ))
            .toList(),
      ],
    );
  }

  Widget _buildReactionChips(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 16.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: reactionChips!.asMap().entries.map((entry) {
            final index = entry.key;
            final chip = entry.value;
            return Container(
              margin: EdgeInsets.only(
                  right: index < reactionChips!.length - 1 ? 12.h : 0),
              padding: EdgeInsets.symmetric(horizontal: 18.h, vertical: 12.h),
              decoration: BoxDecoration(
                color: appTheme.color418724,
                borderRadius: BorderRadius.circular(20.h),
              ),
              child: InkWell(
                onTap: chip.onTap,
                child: Text(
                  chip.label,
                  style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildReactionCounters(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 28.h, left: 4.h, right: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: reactionCounters!.map((counter) {
          return InkWell(
            onTap: counter.onTap,
            child: Column(
              children: [
                Container(
                  height: counter.isCustomView ? 64.h : null,
                  width: counter.isCustomView ? 64.h : null,
                  decoration: counter.isCustomView
                      ? BoxDecoration(
                          color: counter.backgroundColor ?? Color(0xFFDD2E44),
                          borderRadius: BorderRadius.circular(32.h),
                        )
                      : null,
                  child: counter.isCustomView
                      ? null
                      : CustomImageView(
                          imagePath: counter.iconPath!,
                          height: counter.iconPath!.contains('heart') ||
                                  counter.iconPath!.contains('thumbsup')
                              ? 56.h
                              : 64.h,
                          width:
                              counter.iconPath!.contains('heart') ? 56.h : 64.h,
                          fit: BoxFit.cover,
                        ),
                ),
                SizedBox(height: 10.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: appTheme.gray_900_01,
                    borderRadius: BorderRadius.circular(16.h),
                  ),
                  child: Text(
                    counter.count.toString(),
                    style: TextStyleHelper.instance.title18BoldPlusJakartaSans
                        .copyWith(color: appTheme.gray_50),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Data model for social post action buttons
class CustomSocialActionButton {
  CustomSocialActionButton({
    required this.iconPath,
    this.onTap,
  });

  /// Path to the action button icon
  final String iconPath;

  /// Callback when button is tapped
  final VoidCallback? onTap;
}

/// Data model for social post reaction chips
class CustomSocialReactionChip {
  CustomSocialReactionChip({
    required this.label,
    this.onTap,
  });

  /// Reaction chip label text
  final String label;

  /// Callback when chip is tapped
  final VoidCallback? onTap;
}

/// Data model for social post reaction counters
class CustomSocialReactionCounter {
  CustomSocialReactionCounter({
    required this.count,
    this.iconPath,
    this.backgroundColor,
    this.isCustomView = false,
    this.onTap,
  });

  /// Reaction count number
  final int count;

  /// Path to the reaction icon (optional for custom views)
  final String? iconPath;

  /// Background color for custom views
  final Color? backgroundColor;

  /// Whether to use custom view instead of image
  final bool isCustomView;

  /// Callback when reaction is tapped
  final VoidCallback? onTap;
}
