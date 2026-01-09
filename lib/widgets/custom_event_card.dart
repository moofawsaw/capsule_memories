import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/app_export.dart';
import './custom_image_view.dart';

class CustomEventCard extends StatelessWidget {
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

  bool _isNetworkUrl(String s) => s.startsWith('http://') || s.startsWith('https://');
  bool _isSvg(String s) => s.toLowerCase().split('?').first.endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    final String iconPath = (iconButtonImagePath ?? '').trim().isNotEmpty
        ? iconButtonImagePath!.trim()
        : ImageConstant.imgFrame13;

    final bool isNetwork = _isNetworkUrl(iconPath);
    final bool isSvg = isNetwork && _isSvg(iconPath);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: appTheme.gray_900_01,
        border: Border(
          bottom: BorderSide(color: appTheme.blue_gray_900, width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(12.h, 12.h, 12.h, 12.h),
      child: Column(
        children: [
          Row(
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
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: EdgeInsets.only(top: 14.h),
      child: GestureDetector(
        onTap: onBackTap,
        child: CustomImageView(
          imagePath: ImageConstant.imgArrowLeft,
          width: 24.h,
          height: 24.h,
        ),
      ),
    );
  }

  Widget _buildIconButton(String iconPath, bool isNetwork, bool isSvg) {
    return Padding(
      padding: EdgeInsets.only(top: 14.h),
      child: GestureDetector(
        onTap: onIconButtonTap,
        child: Container(
          width: 42.h,
          height: 42.h,
          // color: appTheme.color41C124,
          // padding: EdgeInsets.all(6.h),
          alignment: Alignment.center,
          child: _buildIcon(iconPath, isNetwork, isSvg),
        ),
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
      errorWidget: (context, url, error) => CustomImageView(
        imagePath: ImageConstant.imgFrame13,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildEventDetails(BuildContext context) {
    final locationText = eventLocation ?? 'no location';

    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(top: 14.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eventTitle ?? 'Event Title',
              style: TextStyleHelper.instance.title18BoldPlusJakartaSans
                  .copyWith(color: appTheme.gray_50, height: 1.22),
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Text(
                  locationText,
                  style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                      .copyWith(height: 1.33),
                ),
                SizedBox(width: 6.h),
                _buildPrivacyButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyButton() {
    final bool isEventPrivate = isPrivate ?? true;
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
            style: TextStyleHelper.instance.body12BoldPlusJakartaSans
                .copyWith(color: appTheme.deep_purple_A100),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarStack() {
    final List<String> avatars = participantImages ??
        [ImageConstant.imgFrame2, ImageConstant.imgFrame1, ImageConstant.imgEllipse81];

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
}
