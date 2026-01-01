import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_image_view.dart';
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
        backgroundColor: appTheme.gray_900_02,
        body: Container(
          width: double.maxFinite,
          decoration: BoxDecoration(
            color: appTheme.gray_900_02,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(26.h),
              topRight: Radius.circular(26.h),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12.h),
              _buildAppInfoSection(context),
              _buildQRCodeSection(context),
              _buildShareButton(context),
              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildAppInfoSection(BuildContext context) {
    return CustomQrInfoCard(
      title: 'Download Capsule App',
      description:
          'Scan this QR code with your phone to download the Capsule App',
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
    return Container(
      margin: EdgeInsets.only(
        top: 14.h,
        left: 62.h,
        right: 62.h,
      ),
      child: CustomImageView(
        imagePath: 'assets/images/image-1767240579108.png',
        height: 200.h,
        width: 200.h,
        fit: BoxFit.contain,
      ),
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
          margin: EdgeInsets.only(
            top: 20.h,
            left: 24.h,
            right: 24.h,
          ),
        );
      },
    );
  }

  /// Navigates back to the previous screen.
  void onTapBackButton(BuildContext context) {
    NavigatorService.goBack();
  }
}
