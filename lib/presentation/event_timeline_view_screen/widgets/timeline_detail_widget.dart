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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTimeColumn(
            model?.leftDate ?? "Dec 4",
            model?.leftTime ?? "3:18pm",
          ),
          Expanded(
            child: Column(
              children: [
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
          ),
          _buildTimeColumn(
            model?.rightDate ?? "Dec 4",
            model?.rightTime ?? "3:18am",
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(String date, String time) {
    return Column(
      children: [
        Text(
          date,
          style: TextStyleHelper.instance.body14BoldPlusJakartaSans
              .copyWith(color: appTheme.gray_50),
        ),
        SizedBox(height: 6.h),
        Text(
          time,
          style: TextStyleHelper.instance.body14RegularPlusJakartaSans
              .copyWith(color: appTheme.blue_gray_300),
        ),
      ],
    );
  }
}
