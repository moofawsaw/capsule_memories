import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_qr_info_card.dart';
import 'notifier/app_download_notifier.dart';
import '../../widgets/custom_qr_code_card.dart';

class AppDownloadScreen extends ConsumerStatefulWidget {
  AppDownloadScreen({Key? key}) : super(key: key);

  @override
  AppDownloadScreenState createState() => AppDownloadScreenState();

  /// Helper method to show this screen as a bottom sheet
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppDownloadScreen(),
    );
  }
}

class AppDownloadScreenState extends ConsumerState<AppDownloadScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
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
          SizedBox(height: 8.h),
          _buildDragHandle(),
          SizedBox(height: 4.h),
          _buildAppInfoSection(context),
          _buildQRCodeSection(context),
          _buildShareButton(context),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  /// Drag handle for bottom sheet
  Widget _buildDragHandle() {
    return Container(
      width: 40.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: appTheme.gray_50.withAlpha(77),
        borderRadius: BorderRadius.circular(2.h),
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
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(appDownloadNotifier);
        final qrData = state.appDownloadModel?.qrData;

        return CustomQrCodeCard(
          qrData: (qrData ?? '').trim(),
          qrSize: 200.h,
          outerPadding: 16.h,
          borderRadius: 16.h,
          margin: EdgeInsets.only(
            top: 14.h,
            left: 62.h,
            right: 62.h,
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
