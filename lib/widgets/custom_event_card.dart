import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/app_export.dart';
import './custom_image_view.dart';

class CustomEventCard extends StatelessWidget {
  final bool isLoading; // NEW

  final String? eventTitle;
  final String? eventDate;
  final String? eventLocation;
  final bool? isPrivate;
  final String? iconButtonImagePath;
  final List<String>? participantImages;
  final VoidCallback? onBackTap;
  final VoidCallback? onIconButtonTap;
  final VoidCallback? onAvatarTap;

  const CustomEventCard({
    Key? key,
    this.isLoading = false, // NEW
    this.eventTitle,
    this.eventDate,
    this.eventLocation,
    this.isPrivate,
    this.iconButtonImagePath,
    this.participantImages,
    this.onBackTap,
    this.onIconButtonTap,
    this.onAvatarTap,
  }) : super(key: key);

  bool _isNetworkUrl(String s) =>
      s.startsWith('http://') || s.startsWith('https://');
  bool _isSvg(String s) => s.toLowerCase().split('?').first.endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    final String? iconPath = (iconButtonImagePath ?? '').trim().isNotEmpty
        ? iconButtonImagePath!.trim()
        : null;

    final bool isNetwork = iconPath != null && _isNetworkUrl(iconPath);
    final bool isSvg = iconPath != null && isNetwork && _isSvg(iconPath);


    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: appTheme.gray_900_01,
        border: Border(
          bottom: BorderSide(color: appTheme.blue_gray_900, width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(12.h, 12.h, 12.h, 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackButton(),
          SizedBox(width: 16.h),
          _buildIconButton(iconPath, isNetwork, isSvg),
          SizedBox(width: 16.h),
          _buildEventDetails(context),
          SizedBox(width: 16.h),
          _buildAvatarStack(),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: EdgeInsets.only(top: 14.h),
      child: GestureDetector(
        onTap: isLoading ? null : onBackTap, // disable while loading
        child: CustomImageView(
          imagePath: ImageConstant.imgArrowLeft,
          width: 24.h,
          height: 24.h,
        ),
      ),
    );
  }

  Widget _buildIconButton(String? iconPath, bool isNetwork, bool isSvg) {
    return Padding(
      padding: EdgeInsets.only(top: 14.h),
      child: SizedBox(
        width: 42.h,
        height: 42.h,
        child: isLoading
            ? _skeletonBox(width: 42.h, height: 42.h, radius: 10.h)
            : (iconPath == null
        // ✅ Keep spacing but render nothing (no flash)
            ? const SizedBox.shrink()
            : GestureDetector(
          onTap: onIconButtonTap,
          child: _buildIcon(iconPath, isNetwork, isSvg),
        )),
      ),
    );
  }


  Widget _buildIcon(String iconPath, bool isNetwork, bool isSvg) {
    if (!isNetwork) {
      return CustomImageView(imagePath: iconPath, fit: BoxFit.contain);
    }

    if (isSvg) {
      return SvgPicture.network(
        iconPath,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => SizedBox(
          width: 26.h,
          height: 26.h,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: appTheme.whiteCustom,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: iconPath,
      fit: BoxFit.contain,
      placeholder: (context, url) => SizedBox(
        width: 26.h,
        height: 26.h,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: appTheme.whiteCustom,
        ),
      ),
      errorWidget: (context, url, error) => const SizedBox.shrink(),
    );
  }

  Widget _buildEventDetails(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(top: 14.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoading)
              _skeletonBox(width: 190.h, height: 18.h, radius: 6.h)
            else
              Text(
                eventTitle ?? '', // NO VISIBLE FALLBACK
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyleHelper.instance.title18BoldPlusJakartaSans
                    .copyWith(color: appTheme.gray_50, height: 1.22),
              ),
            SizedBox(height: 4.h),
            Row(
              children: [
                if (isLoading)
                  _skeletonBox(width: 120.h, height: 12.h, radius: 6.h)
                else
                  Text(
                    eventLocation ?? '', // NO VISIBLE FALLBACK
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                        .copyWith(height: 1.33),
                  ),
                SizedBox(width: 6.h),
                if (isLoading)
                  _skeletonBox(width: 64.h, height: 18.h, radius: 6.h)
                else if (isPrivate != null)
                  _buildPrivacyButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyButton() {
    // ✅ If unknown, render nothing (prevents PRIVATE flash)
    if (isPrivate == null) return const SizedBox.shrink();

    final bool isEventPrivate = isPrivate!;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 2.h),
      decoration: BoxDecoration(
        color: appTheme.gray_900_03,
        borderRadius: BorderRadius.circular(6.h),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomImageView(
            imagePath: isEventPrivate
                ? ImageConstant.imgIconDeepPurpleA10014x14
                : ImageConstant.imgIcon14x14,
            height: 14.h,
            width: 14.h,
          ),
          SizedBox(width: 4.h),
          Text(
            isEventPrivate ? 'PRIVATE' : 'PUBLIC',
            style: TextStyleHelper.instance.body12BoldPlusJakartaSans.copyWith(
              color: appTheme.deep_purple_A100,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildAvatarStack() {
    if (isLoading) {
      return Padding(
        padding: EdgeInsets.only(top: 14.h),
        child: SizedBox(
          width: 84.h,
          height: 36.h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(right: 0, child: _skeletonCircle(36.h)),
              Positioned(right: 24.h, child: _skeletonCircle(36.h)),
              Positioned(right: 48.h, child: _skeletonCircle(36.h)),
            ],
          ),
        ),
      );
    }

    final List<String> avatars = participantImages ?? const [];

    Widget avatarAt(int index, double right) {
      if (avatars.length <= index) return const SizedBox.shrink();

      return Positioned(
        right: right,
        child: SizedBox(
          width: 36.h,
          height: 36.h,
          child: ClipOval(
            child: CustomImageView(
              imagePath: avatars[index],
              width: 36.h,
              height: 36.h,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: 14.h),
      child: GestureDetector(
        onTap: onAvatarTap,
        child: SizedBox(
          width: 84.h,
          height: 36.h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              avatarAt(0, 0),
              avatarAt(1, 24.h),
              avatarAt(2, 48.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skeletonBox({
    required double width,
    required double height,
    double radius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: appTheme.gray_900_03, // use your skeleton color
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _skeletonCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: appTheme.gray_900_03,
        shape: BoxShape.circle,
      ),
    );
  }
}
