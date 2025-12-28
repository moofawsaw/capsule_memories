import '../core/app_export.dart';
import './custom_button.dart';

class CustomConfirmationDialog {
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Delete',
    String cancelText = 'Cancel',
    Color? confirmColor,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: appTheme.gray_900_01,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.h),
            side: BorderSide(
              color: appTheme.blue_gray_300.withAlpha(51),
              width: 1.0,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Container(
                  padding: EdgeInsets.all(12.h),
                  decoration: BoxDecoration(
                    color: (confirmColor ?? appTheme.red_500).withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 32.h,
                    color: confirmColor ?? appTheme.red_500,
                  ),
                ),
                SizedBox(height: 16.h),
              ],
              Text(
                title,
                style: TextStyleHelper.instance.title18BoldPlusJakartaSans
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
                children: [
                  Expanded(
                    child: CustomButton(
                      text: cancelText,
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      buttonStyle: CustomButtonStyle.outlineDark,
                      buttonTextStyle: CustomButtonTextStyle.bodyMediumGray,
                      height: 44.h,
                    ),
                  ),
                  SizedBox(width: 12.h),
                  Expanded(
                    child: CustomButton(
                      text: confirmText,
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      buttonStyle: CustomButtonStyle.fillPrimary,
                      buttonTextStyle: CustomButtonTextStyle.bodyMediumGray,
                      height: 44.h,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
