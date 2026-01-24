import '../core/app_export.dart';
import './custom_image_view.dart';

/**
 * CustomStoryProgress - A story creation progress component that displays image preview with progress indicator
 * 
 * This component shows a story/memory creation interface with:
 * - Image preview with optional overlay controls
 * - Linear progress indicator showing creation progress
 * - Profile avatar indicator
 * - Action button for additional functionality
 * 
 * Features:
 * - Responsive design using SizeUtils extensions
 * - Customizable images and progress values
 * - Optional overlay controls on image preview
 * - Flexible action button positioning
 * 
 * @param mainImagePath - Path to the main preview image
 * @param progressValue - Progress value between 0.0 and 1.0
 * @param profileImagePath - Path to the profile avatar image
 * @param actionIconPath - Path to the action button icon
 * @param showOverlayControls - Whether to show overlay controls on image
 * @param overlayIconPath - Path to the overlay control icon
 * @param onActionTap - Callback for action button tap
 * @param margin - External margin for the component
 */
class CustomStoryProgress extends StatelessWidget {
  final String? mainImagePath;
  final double? progressValue;
  final String? profileImagePath;
  final String? actionIconPath;
  final bool? showOverlayControls;
  final String? overlayIconPath;
  final VoidCallback? onActionTap;
  final EdgeInsetsGeometry? margin;

  const CustomStoryProgress({
    Key? key,
    this.mainImagePath,
    this.progressValue,
    this.profileImagePath,
    this.actionIconPath,
    this.showOverlayControls,
    this.overlayIconPath,
    this.onActionTap,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.symmetric(horizontal: 32.h),
      height: 110.h,
      width: double.infinity,
      child: Stack(
        children: [
          // Main image with overlay controls
          _buildImagePreview(),

          // Progress indicator section
          _buildProgressSection(context),

          // Action button
          _buildActionButton(context),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Positioned(
      top: 0,
      left: 127.h,
      child: Stack(
        children: [
          // Main preview image
          Container(
            width: 38.h,
            height: 56.h,
            decoration: BoxDecoration(
              border: Border.all(
                color: appTheme.deep_purple_A200,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(6.h),
              color: appTheme.gray_900_01,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6.h),
              child: CustomImageView(
                imagePath: mainImagePath ?? '',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Overlay controls
          if (showOverlayControls ?? true)
            Positioned(
              top: 4.h,
              left: 4.h,
              child: Container(
                width: 16.h,
                height: 16.h,
                decoration: BoxDecoration(
                  color: appTheme.color3BD81E,
                  borderRadius: BorderRadius.circular(6.h),
                ),
                padding: EdgeInsets.all(4.h),
                child: Container(
                  decoration: BoxDecoration(
                    color: appTheme.color3BD81E,
                    borderRadius: BorderRadius.circular(8.h),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.photo,
                      size: 12.h,
                      color: appTheme.gray_50,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main progress bar
          Container(
            width: double.infinity,
            height: 4.h,
            decoration: BoxDecoration(
              color: appTheme.deep_purple_A100,
              borderRadius: BorderRadius.circular(2.h),
            ),
          ),

          SizedBox(height: 1.h),

          // Progress indicator with profile
          Row(
            children: [
              // Progress indicator line
              Expanded(
                flex: (progressValue ?? 0.5 * 100).toInt(),
                child: Container(
                  height: 16.h,
                  child: Column(
                    children: [
                      // Vertical indicator line
                      Container(
                        width: 2.h,
                        height: 16.h,
                        color: appTheme.deep_purple_A100,
                      ),
                    ],
                  ),
                ),
              ),

              // Profile image at progress point
              CustomImageView(
                imagePath: profileImagePath ?? '',
                width: 28.h,
                height: 28.h,
                fit: BoxFit.cover,
                isCircular: true,
              ),

              Expanded(
                flex: 100 - (progressValue ?? 0.5 * 100).toInt(),
                child: Container(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return Positioned(
      bottom: 26.h,
      right: 0,
      child: InkWell(
        onTap: onActionTap,
        child: Icon(
          Icons.chevron_right,
          size: 42.h,
          color: appTheme.gray_50,
        ),
      ),
    );
  }
}
