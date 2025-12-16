import 'package:flutter/material.dart';
import '../core/app_export.dart';
import 'custom_image_view.dart';
import 'custom_button.dart';
import 'custom_icon_button.dart';

/**
 * CustomMemoryCard - A comprehensive memory/story card component that displays category information,
 * participant avatars with overflow counter, and a main image placeholder. Features responsive design,
 * overlapping avatar stack, category tagging with icons, and customizable action buttons.
 */
class CustomMemoryCard extends StatelessWidget {
  CustomMemoryCard({
    Key? key,
    this.categoryIcon,
    this.categoryText,
    this.participantAvatars,
    this.maxVisibleAvatars,
    this.mainImagePath,
    this.actionIconPath,
    this.onActionTap,
    this.onCategoryTap,
    this.onMainImageTap,
    this.backgroundColor,
    this.height,
    this.width,
    this.margin,
    this.padding,
  }) : super(key: key);

  /// Icon path for the category button
  final String? categoryIcon;

  /// Text label for the category
  final String? categoryText;

  /// List of participant avatar image paths
  final List<String>? participantAvatars;

  /// Maximum number of avatars to show before displaying counter
  final int? maxVisibleAvatars;

  /// Main image path or placeholder
  final String? mainImagePath;

  /// Action icon path for top-right button
  final String? actionIconPath;

  /// Callback for action button tap
  final VoidCallback? onActionTap;

  /// Callback for category button tap
  final VoidCallback? onCategoryTap;

  /// Callback for main image tap
  final VoidCallback? onMainImageTap;

  /// Background color of the card
  final Color? backgroundColor;

  /// Height of the card
  final double? height;

  /// Width of the card
  final double? width;

  /// Margin around the card
  final EdgeInsetsGeometry? margin;

  /// Internal padding of the card
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 811.h,
      width: width ?? double.infinity,
      margin: margin,
      padding: padding ?? EdgeInsets.fromLTRB(20.h, 28.h, 20.h, 28.h),
      decoration: BoxDecoration(
        color: backgroundColor ?? Color(0xFF12151D),
        borderRadius: BorderRadius.circular(0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSection(context),
          Spacer(),
          _buildMainImagePlaceholder(context),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              margin: EdgeInsets.only(top: 6.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoryButton(context),
                  SizedBox(height: 16.h),
                  _buildParticipantAvatars(context),
                ],
              ),
            ),
          ),
          if (actionIconPath != null) _buildActionButton(context),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(BuildContext context) {
    if (categoryText == null) return SizedBox.shrink();

    return CustomButton(
      text: categoryText ?? "Category",
      leftIcon: categoryIcon,
      onPressed: onCategoryTap,
      buttonStyle: CustomButtonStyle.fillDark,
      buttonTextStyle: CustomButtonTextStyle
          .bodySmallPrimary, // Modified: Replaced unavailable theme color
      padding: EdgeInsets.fromLTRB(8.h, 8.h, 8.h, 8.h),
    );
  }

  Widget _buildParticipantAvatars(BuildContext context) {
    final avatars = participantAvatars ?? [];
    if (avatars.isEmpty) return SizedBox.shrink();

    final maxVisible = maxVisibleAvatars ?? 3;
    final visibleAvatars = avatars.take(maxVisible).toList();
    final remainingCount = avatars.length - maxVisible;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.h),
      decoration: BoxDecoration(
        color: appTheme.gray_900_01,
        borderRadius: BorderRadius.circular(28.h),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAvatarStack(visibleAvatars, context),
          if (remainingCount > 0) _buildCounterText(remainingCount, context),
        ],
      ),
    );
  }

  Widget _buildAvatarStack(List<String> avatars, BuildContext context) {
    return Container(
      height: 58.h,
      child: Stack(
        children: List.generate(avatars.length, (index) {
          return Positioned(
            left: index * 31.h,
            top: 9.h,
            child: CustomImageView(
              imagePath: avatars[index],
              height: 40.h,
              width: 40.h,
              radius: BorderRadius.circular(20.h),
              fit: BoxFit.cover,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCounterText(int count, BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 4.h),
      decoration: BoxDecoration(
        color: appTheme.gray_900_02,
        borderRadius: BorderRadius.circular(18.h),
      ),
      child: Text(
        '+$count',
        style: TextStyleHelper.instance.body14BoldPlusJakartaSans
            .copyWith(color: appTheme.blue_gray_300),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return CustomIconButton(
      iconPath: actionIconPath ?? ImageConstant.imgFrame19,
      onTap: onActionTap,
      height: 40.h,
      width: 40.h,
    );
  }

  Widget _buildMainImagePlaceholder(BuildContext context) {
    return GestureDetector(
      onTap: onMainImageTap,
      child: Container(
        height: 124.h,
        width: 124.h,
        margin: EdgeInsets.only(bottom: 18.h),
        decoration: BoxDecoration(
          color: mainImagePath != null
              ? appTheme.transparentCustom
              : appTheme.blue_gray_100,
          border: Border.all(
            color: appTheme.gray_400,
            width: 9.h,
          ),
          borderRadius: BorderRadius.circular(62.h),
        ),
        child: mainImagePath != null
            ? CustomImageView(
                imagePath: mainImagePath!,
                height: 124.h,
                width: 124.h,
                radius: BorderRadius.circular(62.h),
                fit: BoxFit.cover,
              )
            : null,
      ),
    );
  }
}
