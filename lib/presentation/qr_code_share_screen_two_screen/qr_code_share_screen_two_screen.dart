import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_edit_text.dart';
import '../../widgets/custom_qr_info_card.dart';
import 'notifier/qr_code_share_screen_two_notifier.dart';

class QRCodeShareScreenTwo extends ConsumerStatefulWidget {
  QRCodeShareScreenTwo({Key? key}) : super(key: key);

  @override
  QRCodeShareScreenTwoState createState() => QRCodeShareScreenTwoState();
}

class QRCodeShareScreenTwoState extends ConsumerState<QRCodeShareScreenTwo> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.black_900,
        body: Container(
          width: double.infinity,
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              height: 848.h,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      height: 572.h,
                      decoration: BoxDecoration(
                        color: appTheme.gray_900_02,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(26.h),
                          topRight: Radius.circular(26.h),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 26.h,
                      vertical: 20.h,
                    ),
                    decoration: BoxDecoration(
                      color: appTheme.color5B0000,
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 276.h),
                        Container(
                          width: 116.h,
                          height: 12.h,
                          decoration: BoxDecoration(
                            color: appTheme.color3BD81E,
                            borderRadius: BorderRadius.circular(6.h),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        CustomQrInfoCard(
                          title: "Share QR code",
                          description:
                              "Share this QR code to become friends with other Memry users",
                          textAlign: TextAlign.center,
                          margin: EdgeInsets.symmetric(horizontal: 26.h),
                        ),
                        SizedBox(height: 16.h),
                        _buildQRCodeSection(context),
                        SizedBox(height: 20.h),
                        _buildUrlSection(context),
                        SizedBox(height: 20.h),
                        _buildDescriptionText(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildQRCodeSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(qrCodeShareScreenTwoNotifier);

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 36.h),
          child: QrImageView(
            data: state.qrCodeShareScreenTwoModel?.qrData ??
                ImageConstant.imgNetworkR812309r72309r572093t722323t23t23t08,
            version: QrVersions.auto,
            size: 200.h,
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
        final state = ref.watch(qrCodeShareScreenTwoNotifier);
        final notifier = ref.read(qrCodeShareScreenTwoNotifier.notifier);

        // Listen for copy success message
        ref.listen(
          qrCodeShareScreenTwoNotifier,
          (previous, current) {
            if (current.showCopySuccess ?? false) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Link copied to clipboard'),
                  backgroundColor: appTheme.colorFF52D1,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        );

        return Container(
          margin: EdgeInsets.only(right: 12.h),
          child: Row(
            children: [
              Expanded(
                child: CustomEditText(
                  controller: state.urlController,
                  hintText: ImageConstant
                      .imgNetworkR812309r72309r572093t722323t23t23t08,
                  textStyle: TextStyleHelper
                      .instance.title16RegularPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                  fillColor: appTheme.gray_900,
                  borderRadius: 8.h,
                  contentPadding: EdgeInsets.fromLTRB(16.h, 16.h, 16.h, 10.h),
                  readOnly: true,
                ),
              ),
              SizedBox(width: 22.h),
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
  Widget _buildDescriptionText(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Text(
        "People who scan this code will automatically add you to their friends list",
        textAlign: TextAlign.center,
        style: TextStyleHelper.instance.body14RegularPlusJakartaSans
            .copyWith(color: appTheme.blue_gray_300, height: 1.21),
      ),
    );
  }

  /// Copies the QR code URL to clipboard
  void onTapCopyUrl(BuildContext context) {
    final notifier = ref.read(qrCodeShareScreenTwoNotifier.notifier);
    notifier.copyUrlToClipboard();
  }

  /// Shares the QR code URL using share functionality
  void onTapShareUrl(BuildContext context) {
    final notifier = ref.read(qrCodeShareScreenTwoNotifier.notifier);
    notifier.shareUrl();
  }
}
