import 'package:flutter/material.dart';
import '../core/app_export.dart';
import 'custom_image_view.dart';

/**
 * CustomPublicMemories - A horizontal scrolling component that displays public memory cards
 * with rich visual content including profile images, media previews, and timeline information.
 * 
 * Features:
 * - Section header with icon and title
 * - Horizontally scrollable memory cards
 * - Profile image stacks with overlapping circular images
 * - Media timeline with preview images and play buttons
 * - Timestamp and location information
 * - Responsive design with SizeUtils extensions
 */
class CustomPublicMemories extends StatelessWidget {
  CustomPublicMemories({
    Key? key,
    this.sectionTitle,
    this.sectionIcon,
    this.memories,
    this.onMemoryTap,
    this.margin,
  }) : super(key: key);

  /// Title text for the section header
  final String? sectionTitle;

  /// Icon path for the section header
  final String? sectionIcon;

  /// List of memory data to display
  final List<CustomMemoryItem>? memories;

  /// Callback when a memory card is tapped
  final Function(CustomMemoryItem)? onMemoryTap;

  /// Margin around the entire component
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: margin ?? EdgeInsets.only(top: 30.h, left: 24.h),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildSectionHeader(context),
          SizedBox(height: 24.h),
          _buildMemoriesScroll(context),
        ]));
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Row(children: [
      CustomImageView(
          imagePath: sectionIcon ?? ImageConstant.imgIcon22x22,
          height: 22.h,
          width: 22.h),
      SizedBox(width: 8.h),
      Text(sectionTitle ?? 'Public Memories',
          style: TextStyleHelper.instance.title16BoldPlusJakartaSans
              .copyWith(color: appTheme.gray_50)),
    ]);
  }

  Widget _buildMemoriesScroll(BuildContext context) {
    final memoryList = memories ?? [];

    if (memoryList.isEmpty) {
      return SizedBox.shrink();
    }

    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
            children: List.generate(memoryList.length, (index) {
          final memory = memoryList[index];
          return Container(
              margin: EdgeInsets.only(
                  right: index == memoryList.length - 1 ? 0 : 12.h),
              child: _buildMemoryCard(context, memory));
        })));
  }

  Widget _buildMemoryCard(BuildContext context, CustomMemoryItem memory) {
    return GestureDetector(
        onTap: () => onMemoryTap?.call(memory),
        child: Container(
            width: 300.h,
            decoration:
                BoxDecoration(borderRadius: BorderRadius.circular(20.h)),
            child: Column(children: [
              _buildMemoryHeader(context, memory),
              _buildMemoryTimeline(context, memory),
              _buildMemoryFooter(context, memory),
            ])));
  }

  Widget _buildMemoryHeader(BuildContext context, CustomMemoryItem memory) {
    return Container(
        padding: EdgeInsets.all(18.h),
        decoration: BoxDecoration(color: Color(0xFFD81E29).withAlpha(59)),
        child: Row(children: [
          Container(
              height: 36.h,
              width: 36.h,
              decoration: BoxDecoration(
                  color: Color(0xFFC1242F).withAlpha(64),
                  borderRadius: BorderRadius.circular(18.h)),
              padding: EdgeInsets.all(6.h),
              child: CustomImageView(
                  imagePath: memory.iconPath ?? ImageConstant.imgFrame13Red600,
                  height: 24.h,
                  width: 24.h)),
          SizedBox(width: 12.h),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(memory.title ?? 'Nixon Wedding 2025',
                    style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                        .copyWith(color: appTheme.gray_50)),
                SizedBox(height: 2.h),
                Text(memory.date ?? 'Dec 4, 2025',
                    style:
                        TextStyleHelper.instance.body12MediumPlusJakartaSans),
              ])),
          _buildProfileStack(context, memory.profileImages ?? []),
        ]));
  }

  Widget _buildProfileStack(BuildContext context, List<String> profileImages) {
    if (profileImages.isEmpty) {
      return SizedBox.shrink();
    }

    return SizedBox(
        width: 84.h,
        height: 36.h,
        child: Stack(
            children: List.generate(
                profileImages.length > 3 ? 3 : profileImages.length, (index) {
          return Positioned(
              left: (index * 24).h,
              child: Container(
                  height: 36.h,
                  width: 36.h,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: appTheme.whiteCustom, width: 1.h)),
                  child: ClipOval(
                      child: CustomImageView(
                          imagePath: profileImages[index],
                          height: 36.h,
                          width: 36.h,
                          fit: BoxFit.cover))));
        })));
  }

  Widget _buildMemoryTimeline(BuildContext context, CustomMemoryItem memory) {
    return Container(
        margin: EdgeInsets.symmetric(horizontal: 4.h),
        child: Stack(children: [
          _buildTimelineContent(context, memory),
          _buildTimelineConnectors(context, memory),
        ]));
  }

  Widget _buildTimelineContent(BuildContext context, CustomMemoryItem memory) {
    return Column(children: [
      SizedBox(height: 28.h),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        if (memory.mediaItems != null && memory.mediaItems!.isNotEmpty)
          ...memory.mediaItems!
              .map((item) => _buildMediaPreview(context, item))
              .toList(),
      ]),
      SizedBox(height: 29.h),
      Row(children: [
        Text('now',
            style: TextStyleHelper.instance.body12BoldPlusJakartaSans
                .copyWith(color: appTheme.black_900)),
      ]),
      SizedBox(height: 18.h),
      Container(
          height: 4.h,
          width: double.infinity,
          color: appTheme.deep_purple_A100),
      SizedBox(height: 15.h),
    ]);
  }

  Widget _buildTimelineConnectors(
      BuildContext context, CustomMemoryItem memory) {
    return Positioned(
        bottom: 15.h,
        left: 0,
        right: 0,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _buildTimelinePoint(context, memory.profileImages?[0]),
          _buildTimelinePoint(context, memory.profileImages?[1]),
        ]));
  }

  Widget _buildTimelinePoint(BuildContext context, String? profileImage) {
    if (profileImage == null) return SizedBox.shrink();

    return Column(children: [
      Container(height: 16.h, width: 2.h, color: appTheme.deep_purple_A100),
      SizedBox(height: 1.h),
      Container(
          height: 28.h,
          width: 28.h,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: appTheme.whiteCustom, width: 1.h)),
          child: ClipOval(
              child: CustomImageView(
                  imagePath: profileImage,
                  height: 28.h,
                  width: 28.h,
                  fit: BoxFit.cover))),
    ]);
  }

  Widget _buildMediaPreview(BuildContext context, CustomMediaItem item) {
    return Container(
        margin: EdgeInsets.only(left: 6.h),
        child: Stack(children: [
          Container(
              height: 56.h,
              width: 40.h,
              decoration: BoxDecoration(
                  color: appTheme.gray_900_01,
                  borderRadius: BorderRadius.circular(6.h),
                  border:
                      Border.all(color: appTheme.deep_purple_A200, width: 1.h)),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(6.h),
                  child: CustomImageView(
                      imagePath: item.imagePath ?? '',
                      height: 56.h,
                      width: 40.h,
                      fit: BoxFit.cover))),
          if (item.hasPlayButton == true)
            Positioned(
                top: 4.h,
                left: 4.h,
                child: Container(
                    height: 16.h,
                    width: 16.h,
                    decoration: BoxDecoration(
                        color: Color(0xFFD81E29).withAlpha(59),
                        borderRadius: BorderRadius.circular(8.h)),
                    child: Center(
                        child: CustomImageView(
                            imagePath: ImageConstant.imgPlayCircle,
                            height: 12.h,
                            width: 12.h)))),
        ]));
  }

  Widget _buildMemoryFooter(BuildContext context, CustomMemoryItem memory) {
    return Container(
        padding: EdgeInsets.all(12.h),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(memory.startDate ?? 'Dec 4',
                style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                    .copyWith(color: appTheme.gray_50)),
            SizedBox(height: 6.h),
            Text(memory.startTime ?? '3:18pm',
                style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300)),
          ]),
          if (memory.location != null)
            Column(children: [
              Text(memory.location!,
                  style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                      .copyWith(color: appTheme.blue_gray_300)),
              if (memory.distance != null) ...[
                SizedBox(height: 4.h),
                Text(memory.distance!,
                    style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                        .copyWith(color: appTheme.blue_gray_300)),
              ],
            ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(memory.endDate ?? 'Dec 4',
                style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                    .copyWith(color: appTheme.gray_50)),
            SizedBox(height: 6.h),
            Text(memory.endTime ?? '3:18am',
                style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300)),
          ]),
        ]));
  }
}

/// Data model for memory items
class CustomMemoryItem {
  CustomMemoryItem({
    this.title,
    this.date,
    this.iconPath,
    this.profileImages,
    this.mediaItems,
    this.startDate,
    this.startTime,
    this.endDate,
    this.endTime,
    this.location,
    this.distance,
  });

  /// Memory title
  final String? title;

  /// Memory date
  final String? date;

  /// Icon path for the memory
  final String? iconPath;

  /// List of profile image paths
  final List<String>? profileImages;

  /// List of media items in the timeline
  final List<CustomMediaItem>? mediaItems;

  /// Start date text
  final String? startDate;

  /// Start time text
  final String? startTime;

  /// End date text
  final String? endDate;

  /// End time text
  final String? endTime;

  /// Location text
  final String? location;

  /// Distance text
  final String? distance;
}

/// Data model for media items in the timeline
class CustomMediaItem {
  CustomMediaItem({
    this.imagePath,
    this.hasPlayButton = false,
  });

  /// Path to the media image
  final String? imagePath;

  /// Whether this media item has a play button overlay
  final bool hasPlayButton;
}
