import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../models/timeline_detail_model.dart';

class TimelineDetailWidget extends StatelessWidget {
  final TimelineDetailModel? model;

  TimelineDetailWidget({
    Key? key,
    this.model,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          // Location and distance only - date/time removed as it's already shown in event header
          Text(
            model?.centerLocation ?? "Tillsonburg, ON",
            style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                .copyWith(color: appTheme.blue_gray_300),
          ),
          SizedBox(height: 4.h),
          Text(
            model?.centerDistance ?? "21km",
            style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                .copyWith(color: appTheme.blue_gray_300),
          ),
        ],
      ),
    );
  }
}
