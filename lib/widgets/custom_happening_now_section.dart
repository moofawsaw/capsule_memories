import 'package:flutter/material.dart';
import '../core/app_export.dart';
import 'custom_image_view.dart';
import 'custom_button.dart';

/** 
 * CustomHappeningNowSection - A section widget that displays a "Happening Now" header 
 * with a horizontal scrollable list of story cards showing user activities.
 * 
 * Features:
 * - Responsive design using SizeUtils extensions
 * - Customizable story data through HappeningNowStoryData model
 * - Tap navigation support for individual stories
 * - Horizontal scrollable story cards
 * - Profile avatars with decorative borders
 * - Category badges with icons
 * - Timestamp display
 */
class CustomHappeningNowSection extends StatelessWidget {
  CustomHappeningNowSection({
    Key? key,
    this.sectionTitle,
    this.sectionIcon,
    this.stories,
    this.onStoryTap,
    this.margin,
  }) : super(key: key);

  /// Title text for the section header
  final String? sectionTitle;

  /// Icon path for the section header
  final String? sectionIcon;

  /// List of story data to display
  final List<HappeningNowStoryData>? stories;

  /// Callback when a story card is tapped
  final Function(HappeningNowStoryData)? onStoryTap;

  /// Margin around the entire section
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(),
          SizedBox(height: 22.h),
          _buildStoriesList(context),
        ],
      ),
    );
  }

  /// Builds the section header with icon and title
  Widget _buildSectionHeader() {
    return Row(
      children: [
        CustomImageView(
          imagePath: sectionIcon ?? ImageConstant.imgIconDeepPurpleA10022x22,
          height: 22.h,
          width: 22.h,
        ),
        SizedBox(width: 8.h),
        Text(
          sectionTitle ?? 'Happening Now',
          style: TextStyleHelper.instance.title16BoldPlusJakartaSans
              .copyWith(color: appTheme.gray_50),
        ),
      ],
    );
  }

  /// Builds the horizontal scrollable list of story cards
  Widget _buildStoriesList(BuildContext context) {
    final storyList = stories ?? [];

    return SizedBox(
      height: 240.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: storyList.length,
        separatorBuilder: (context, index) => SizedBox(width: 12.h),
        itemBuilder: (context, index) {
          return _buildStoryCard(context, storyList[index]);
        },
      ),
    );
  }

  /// Builds an individual story card
  Widget _buildStoryCard(BuildContext context, HappeningNowStoryData story) {
    return GestureDetector(
      onTap: () => onStoryTap?.call(story),
      child: Container(
        width: 160.h,
        height: 240.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.h),
          color: appTheme.gray_900_01,
        ),
        child: Stack(
          children: [
            CustomImageView(
              imagePath: story.backgroundImage ?? '',
              width: 160.h,
              height: 240.h,
              fit: BoxFit.cover,
              radius: BorderRadius.circular(12.h),
            ),
            Positioned(
              bottom: 8.h,
              left: 18.h,
              right: 18.h,
              child: _buildStoryOverlay(story),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the overlay content on the story card
  Widget _buildStoryOverlay(HappeningNowStoryData story) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildProfileAvatar(story.profileImage ?? ''),
        SizedBox(height: 60.h),
        Text(
          story.userName ?? '',
          style: TextStyleHelper.instance.title16RegularPlusJakartaSans
              .copyWith(color: appTheme.white_A700),
        ),
        SizedBox(height: 14.h),
        _buildCategoryButton(story),
        SizedBox(height: 4.h),
        Text(
          story.timestamp ?? '',
          style: TextStyleHelper.instance.body12MediumPlusJakartaSans
              .copyWith(color: appTheme.white_A700),
        ),
      ],
    );
  }

  /// Builds the profile avatar with purple border
  Widget _buildProfileAvatar(String profileImage) {
    return Container(
      width: 48.h,
      height: 48.h,
      decoration: BoxDecoration(
        border: Border.all(
          color: appTheme.deep_purple_A100,
          width: 4.h,
        ),
        borderRadius: BorderRadius.circular(24.h),
      ),
      child: CustomImageView(
        imagePath: profileImage,
        width: 42.h,
        height: 42.h,
        fit: BoxFit.cover,
        radius: BorderRadius.circular(21.h),
      ),
    );
  }

  /// Builds the category button with icon and text
  Widget _buildCategoryButton(HappeningNowStoryData story) {
    return CustomButton(
      text: story.categoryName ?? '',
      leftIcon: story.categoryIcon,
      buttonStyle: CustomButtonStyle.fillDark,
      buttonTextStyle: CustomButtonTextStyle.bodySmallPrimary,
      padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 8.h),
    );
  }
}

/// Data model for individual story items
class HappeningNowStoryData {
  HappeningNowStoryData({
    this.backgroundImage,
    this.profileImage,
    this.userName,
    this.categoryName,
    this.categoryIcon,
    this.timestamp,
    this.navigationRoute,
  });

  /// Background image path for the story card
  final String? backgroundImage;

  /// Profile image path for the user avatar
  final String? profileImage;

  /// User name to display
  final String? userName;

  /// Category name for the button
  final String? categoryName;

  /// Icon path for the category button
  final String? categoryIcon;

  /// Timestamp text to display
  final String? timestamp;

  /// Route for navigation when tapped
  final String? navigationRoute;
}
