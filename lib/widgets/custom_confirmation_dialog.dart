import '../core/app_export.dart';

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
          ),
          title: Column(
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
            ],
          ),
          content: Text(
            message,
            style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                .copyWith(color: appTheme.blue_gray_300),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                cancelText,
                style: TextStyleHelper.instance.body14MediumPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                confirmText,
                style: TextStyleHelper.instance.body14MediumPlusJakartaSans
                    .copyWith(color: confirmColor ?? Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
