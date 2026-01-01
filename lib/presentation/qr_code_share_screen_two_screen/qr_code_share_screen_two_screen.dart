import 'package:qr_flutter/qr_flutter.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_notification_card.dart';
import 'notifier/qr_code_share_screen_two_notifier.dart';

class QRCodeShareScreenTwoScreen extends ConsumerStatefulWidget {
  const QRCodeShareScreenTwoScreen({Key? key}) : super(key: key);

  @override
  QRCodeShareScreenTwoScreenState createState() =>
      QRCodeShareScreenTwoScreenState();
}

class QRCodeShareScreenTwoScreenState
    extends ConsumerState<QRCodeShareScreenTwoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(qrCodeShareScreenTwoNotifier.notifier).loadUserFriendCode();
    });
  }

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
        final state = ref.watch(qrCodeShareScreenTwoNotifier);

        if (state.isLoading ?? false) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 100.h),
              child: CircularProgressIndicator(
                color: appTheme.colorFF52D1,
              ),
            ),
          );
        }

        if (state.errorMessage != null) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 100.h),
              child: Column(
                children: [
                  Text(
                    'Unable to load friend code',
                    style: TextStyleHelper.instance.body16RegularPlusJakartaSans
                        .copyWith(color: appTheme.red_500),
                  ),
                  SizedBox(height: 12.h),
                  CustomButton(
                    text: 'Retry',
                    onPressed: () => ref
                        .read(qrCodeShareScreenTwoNotifier.notifier)
                        .loadUserFriendCode(),
                    buttonStyle: CustomButtonStyle.fillPrimary,
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomNotificationCard(
              iconPath: ImageConstant.imgFrameDeepPurpleA100,
              title:
                  state.qrCodeShareScreenTwoModel?.displayName ?? 'Add Friend',
              description: 'Scan to add me as friend',
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

  Widget _buildQRCodeSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(qrCodeShareScreenTwoNotifier);
        final qrCodeUrl = state.qrCodeShareScreenTwoModel?.qrCodeUrl;

        // If qr_code_url exists, display it directly using Image.network
        if (qrCodeUrl != null && qrCodeUrl.isNotEmpty) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 68.h),
            child: Image.network(
              qrCodeUrl,
              width: 254.h,
              height: 254.h,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return SizedBox(
                  width: 254.h,
                  height: 254.h,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: appTheme.colorFF52D1,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                // Fallback to generated QR code if image fails to load
                return QrImageView(
                  data: state.qrCodeShareScreenTwoModel?.qrCodeData ?? '',
                  version: QrVersions.auto,
                  size: 254.h,
                  backgroundColor: appTheme.whiteCustom,
                  foregroundColor: appTheme.blackCustom,
                );
              },
            ),
          );
        }

        // Fallback to generated QR code if URL is not available
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 68.h),
          child: QrImageView(
            data: state.qrCodeShareScreenTwoModel?.qrCodeData ?? '',
            version: QrVersions.auto,
            size: 254.h,
            backgroundColor: appTheme.whiteCustom,
            foregroundColor: appTheme.blackCustom,
          ),
        );
      },
    );
  }

  Widget _buildUrlSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(qrCodeShareScreenTwoNotifier);

        ref.listen(
          qrCodeShareScreenTwoNotifier,
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
                    state.qrCodeShareScreenTwoModel?.shareUrl ?? '',
                    style: TextStyleHelper
                        .instance.title16RegularPlusJakartaSans
                        .copyWith(color: appTheme.gray_50),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
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

  Widget _buildActionButtons(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(qrCodeShareScreenTwoNotifier);

        ref.listen(
          qrCodeShareScreenTwoNotifier,
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
                buttonTextStyle: CustomButtonTextStyle.bodyMedium,
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
                buttonTextStyle: CustomButtonTextStyle.bodyMedium,
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

  Widget _buildInfoText(BuildContext context) {
    return Text(
      'People who scan this code or open the link will be added as your friend automatically',
      style: TextStyleHelper.instance.body14RegularPlusJakartaSans
          .copyWith(color: appTheme.blue_gray_300, height: 1.21),
      textAlign: TextAlign.center,
    );
  }

  void onTapCopyUrl(BuildContext context) {
    ref.read(qrCodeShareScreenTwoNotifier.notifier).copyUrlToClipboard();
  }

  void onTapDownloadQR(BuildContext context) {
    ref.read(qrCodeShareScreenTwoNotifier.notifier).downloadQRCode();
  }

  void onTapShareLink(BuildContext context) {
    ref.read(qrCodeShareScreenTwoNotifier.notifier).shareLink();
  }
}
