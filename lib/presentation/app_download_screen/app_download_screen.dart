import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_qr_info_card.dart';
import 'notifier/app_download_notifier.dart';

class AppDownloadScreen extends ConsumerStatefulWidget {
  AppDownloadScreen({Key? key}) : super(key: key);

  @override
  AppDownloadScreenState createState() => AppDownloadScreenState();
}

class AppDownloadScreenState extends ConsumerState<AppDownloadScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFF5B000000),
        body: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Container(
              width: double.maxFinite,
              height: 848.h,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.maxFinite,
                      height: 550.h,
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
                    width: double.maxFinite,
                    height: double.maxFinite,
                    padding: EdgeInsets.symmetric(
                      horizontal: 26.h,
                      vertical: 30.h,
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 290.h),
                        Container(
                          width: 116.h,
                          height: 12.h,
                          decoration: BoxDecoration(
                            color: appTheme.color3BD81E,
                            borderRadius: BorderRadius.circular(6.h),
                          ),
                        ),
                        _buildAppInfoSection(context),
                        _buildQRCodeSection(context),
                        _buildShareButton(context),
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
  Widget _buildAppInfoSection(BuildContext context) {
    return CustomQrInfoCard(
      title: 'Download memry App',
      description: 'Show this QR code with your phone to download the app',
      textAlign: TextAlign.center,
      margin: EdgeInsets.only(
        top: 40.h,
        left: 24.h,
        right: 24.h,
      ),
    );
  }

  /// Section Widget
  Widget _buildQRCodeSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(appDownloadNotifier);

        return Container(
          margin: EdgeInsets.only(
            top: 14.h,
            left: 62.h,
            right: 62.h,
          ),
          child: QrImageView(
            data: state.appDownloadModel?.qrData ??
                ImageConstant.imgNetworkDownload,
            version: QrVersions.auto,
            size: 200.h,
            backgroundColor: appTheme.whiteCustom,
            foregroundColor: appTheme.blackCustom,
            gapless: false,
            errorStateBuilder: (cxt, err) {
              return Container(
                width: 200.h,
                height: 200.h,
                color: appTheme.whiteCustom,
                child: Center(
                  child: Text(
                    'QR Code Error',
                    style: TextStyleHelper.instance.body14
                        .copyWith(color: appTheme.blackCustom),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Section Widget
  Widget _buildShareButton(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(appDownloadNotifier);

        ref.listen(
          appDownloadNotifier,
          (previous, current) {
            if (current.isShareSuccess ?? false) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('App link shared successfully'),
                  backgroundColor: appTheme.colorFF52D1,
                ),
              );
            }

            if (current.shareError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(current.shareError!),
                  backgroundColor: appTheme.colorFFD81E,
                ),
              );
            }
          },
        );

        return CustomButton(
          text: 'Share App',
          width: double.infinity,
          onPressed: () {
            ref.read(appDownloadNotifier.notifier).shareApp();
          },
          buttonStyle: CustomButtonStyle.fillPrimary,
          buttonTextStyle: CustomButtonTextStyle.bodyMedium,
          margin: EdgeInsets.only(top: 20.h),
        );
      },
    );
  }

  /// Navigates back to the previous screen.
  void onTapBackButton(BuildContext context) {
    NavigatorService.goBack();
  }
}
