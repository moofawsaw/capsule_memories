import 'package:flutter/material.dart';
import '../core/app_export.dart';

class CustomHeaderRow extends StatelessWidget {
  CustomHeaderRow({
    Key? key,
    required this.title,
    this.onIconTap,
    this.textAlignment,
    this.margin,
  }) : super(key: key);

  final String title;
  final VoidCallback? onIconTap;

  /// Supported because FeatureRequestScreen is already trying to use this.
  final TextAlign? textAlignment;

  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final align = textAlignment ?? TextAlign.left;

    return Container(
      margin: margin ?? EdgeInsets.symmetric(horizontal: 12.h, vertical: 18.h),
      child: Row(
        children: [
          // Left spacer to truly center title (balances the close button width)
          SizedBox(width: 42.h),

          // Title
          Expanded(
            child: Text(
              title,
              style: TextStyleHelper.instance.headline24ExtraBoldPlusJakartaSans,
              textAlign: align,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),

          // Close button (X)
          GestureDetector(
            onTap: onIconTap,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 42.h,
              height: 42.h,
              child: Center(
                child: Icon(
                  Icons.close,
                  color: appTheme.whiteCustom,
                  size: 24.h,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
