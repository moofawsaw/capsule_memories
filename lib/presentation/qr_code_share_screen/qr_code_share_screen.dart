import 'package:qr_flutter/qr_flutter.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_notification_card.dart';
import 'notifier/qr_code_share_notifier.dart';

class QRCodeShareScreen extends ConsumerStatefulWidget {
  QRCodeShareScreen({Key? key}) : super(key: key);

  @override
  QRCodeShareScreenState createState() => QRCodeShareScreenState();
}

class QRCodeShareScreenState extends ConsumerState<QRCodeShareScreen> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.maxFinite,
        decoration: BoxDecoration(
          color: appTheme.gray_900_02,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.h),
            topRight: Radius.circular(20.h),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12.h),
            // Drag handle indicator
            Container(
              width: 48.h,
              height: 5.h,
              decoration: BoxDecoration(
                color: appTheme.colorFF3A3A,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            SizedBox(height: 20.h),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.h),
                child: _buildContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(qrCodeShareNotifier);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 116.h,
              height: 12.h,
              decoration: BoxDecoration(
                color: appTheme.color3BD81E,
                borderRadius: BorderRadius.circular(6.h),
              ),
            ),
            SizedBox(height: 20.h),
            CustomNotificationCard(
              iconPath: ImageConstant.imgFrameDeepOrangeA700,
              title: 'Family Xmas 2025',
              description: 'Scan to join memory',
              isRead: true,
              onToggleRead: () {},
              titleFontSize: 20.0,
              descriptionAlignment: TextAlign.center,
              margin: EdgeInsets.zero,
            ),
            SizedBox(height: 16.h),
            _buildQRCodeSection(context),
            SizedBox(height: 20.h),
            _buildUrlSection(context),
            SizedBox(height: 20.h),
            _buildActionButtons(context),
            SizedBox(height: 20.h),
            _buildInfoText(context),
          ],
        );
      },
    );
  }

  /// Section Widget
  Widget _buildQRCodeSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(qrCodeShareNotifier);

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 68.h),
          child: QrImageView(
            data: state.qrCodeShareModel?.qrCodeData ??
                ImageConstant.imgNetworkR812309r72309r572093t722323t23t23t08,
            version: QrVersions.auto,
            size: 254.h,
            backgroundColor: appTheme.whiteCustom,
            foregroundColor: appTheme.blackCustom,
          ),
        );
      },
    );
  }

  /// Section Widget
  Widget _buildUrlSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(qrCodeShareNotifier);

        ref.listen(
          qrCodeShareNotifier,
          (previous, current) {
            if (current.isUrlCopied ?? false) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Link copied to clipboard'),
                  backgroundColor: appTheme.colorFF52D1,
                ),
              );
            }
          },
        );

        return Container(
          margin: EdgeInsets.only(left: 4.h, right: 16.h),
          child: Row(
            spacing: 22.h,
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.h,
                    vertical: 16.h,
                  ),
                  decoration: BoxDecoration(
                    color: appTheme.gray_900,
                    borderRadius: BorderRadius.circular(8.h),
                  ),
                  child: Text(
                    state.qrCodeShareModel?.shareUrl ??
                        ImageConstant
                            .imgNetworkR812309r72309r572093t722323t23t23t08,
                    style: TextStyleHelper
                        .instance.title16RegularPlusJakartaSans
                        .copyWith(color: appTheme.gray_50),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => onTapCopyUrl(context),
                child: CustomImageView(
                  imagePath: ImageConstant.imgIcon14,
                  height: 24.h,
                  width: 24.h,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Section Widget
  Widget _buildActionButtons(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(qrCodeShareNotifier);

        ref.listen(
          qrCodeShareNotifier,
          (previous, current) {
            if (current.isDownloadSuccess ?? false) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('QR Code downloaded successfully'),
                  backgroundColor: appTheme.colorFF52D1,
                ),
              );
            }
            if (current.isShareSuccess ?? false) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Link shared successfully'),
                  backgroundColor: appTheme.colorFF52D1,
                ),
              );
            }
          },
        );

        return Row(
          spacing: 12.h,
          children: [
            Expanded(
              child: CustomButton(
                text: 'Download QR',
                leftIcon: ImageConstant.imgIcon15,
                onPressed: () => onTapDownloadQR(context),
                buttonStyle: CustomButtonStyle.fillDark,
                buttonTextStyle: CustomButtonTextStyle
                    .bodyMedium, // Modified: Replaced unavailable bodyMediumWhite with bodyMedium
                padding: EdgeInsets.symmetric(
                  horizontal: 22.h,
                  vertical: 12.h,
                ),
              ),
            ),
            Expanded(
              child: CustomButton(
                text: 'Share Link',
                leftIcon: ImageConstant.imgIcon16,
                onPressed: () => onTapShareLink(context),
                buttonStyle: CustomButtonStyle.fillPrimary,
                buttonTextStyle: CustomButtonTextStyle
                    .bodyMedium, // Modified: Replaced unavailable bodyMediumWhite with bodyMedium
                padding: EdgeInsets.symmetric(
                  horizontal: 30.h,
                  vertical: 12.h,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Section Widget
  Widget _buildInfoText(BuildContext context) {
    return Text(
      'People who scan this code or open the link can join your memory and add their own stories',
      style: TextStyleHelper.instance.body14RegularPlusJakartaSans
          .copyWith(color: appTheme.blue_gray_300, height: 1.21),
      textAlign: TextAlign.center,
    );
  }

  /// Handles copying URL to clipboard
  void onTapCopyUrl(BuildContext context) {
    ref.read(qrCodeShareNotifier.notifier).copyUrlToClipboard();
  }

  /// Handles downloading QR code
  void onTapDownloadQR(BuildContext context) {
    ref.read(qrCodeShareNotifier.notifier).downloadQRCode();
  }

  /// Handles sharing link
  void onTapShareLink(BuildContext context) {
    ref.read(qrCodeShareNotifier.notifier).shareLink();
  }
}
