
import '../core/app_export.dart';
import './custom_button.dart';

/**
 * CustomWarningModal - Reusable warning modal for destructive actions
 * 
 * Use this modal to confirm destructive actions with clear warning messages
 */
class CustomWarningModal extends StatelessWidget {
  const CustomWarningModal({
    Key? key,
    required this.title,
    required this.message,
    required this.confirmButtonText,
    required this.onConfirm,
    this.cancelButtonText = 'Cancel',
    this.confirmButtonColor,
    this.icon,
  }) : super(key: key);

  final String title;
  final String message;
  final String confirmButtonText;
  final VoidCallback onConfirm;
  final String cancelButtonText;
  final Color? confirmButtonColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: appTheme.gray_900_01,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.h),
      ),
      child: Container(
        padding: EdgeInsets.all(24.h),
        decoration: BoxDecoration(
          color: appTheme.gray_900_01,
          borderRadius: BorderRadius.circular(20.h),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                height: 64.h,
                width: 64.h,
                decoration: BoxDecoration(
                  color: (confirmButtonColor ?? appTheme.red_500).withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: confirmButtonColor ?? appTheme.red_500,
                  size: 32.h,
                ),
              ),
              SizedBox(height: 20.h),
            ],
            Text(
              title,
              style: TextStyleHelper.instance.title20BoldPlusJakartaSans
                  .copyWith(color: appTheme.gray_50),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              message,
              style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                  .copyWith(color: appTheme.blue_gray_300),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            Row(
              spacing: 12.h,
              children: [
                Expanded(
                  child: CustomButton(
                    text: cancelButtonText,
                    onPressed: () => Navigator.of(context).pop(),
                    buttonStyle: CustomButtonStyle(
                      backgroundColor: appTheme.gray_900,
                    ),
                    buttonTextStyle: CustomButtonTextStyle(
                      color: appTheme.gray_50,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: CustomButton(
                    text: confirmButtonText,
                    onPressed: () {
                      Navigator.of(context).pop();
                      onConfirm();
                    },
                    buttonStyle: CustomButtonStyle(
                      backgroundColor: confirmButtonColor ?? appTheme.red_500,
                    ),
                    buttonTextStyle: CustomButtonTextStyle(
                      color: appTheme.gray_50,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Shows warning modal with custom parameters
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmButtonText,
    required VoidCallback onConfirm,
    String cancelButtonText = 'Cancel',
    Color? confirmButtonColor,
    IconData? icon,
  }) {
    return showDialog(
      context: context,
      builder: (context) => CustomWarningModal(
        title: title,
        message: message,
        confirmButtonText: confirmButtonText,
        onConfirm: onConfirm,
        cancelButtonText: cancelButtonText,
        confirmButtonColor: confirmButtonColor,
        icon: icon,
      ),
    );
  }
}