import '../../../core/app_export.dart';

/// This class is used in the [timeline_detail_widget] component.

// ignore_for_file: must_be_immutable
class TimelineDetailModel extends Equatable {
  TimelineDetailModel({
    this.leftDate,
    this.leftTime,
    this.centerLocation,
    this.centerDistance,
    this.rightDate,
    this.rightTime,
  }) {
    leftDate = leftDate ?? "Dec 4";
    leftTime = leftTime ?? "3:18pm";
    centerLocation = centerLocation ?? "Tillsonburg, ON";
    centerDistance = centerDistance ?? "21km";
    rightDate = rightDate ?? "Dec 4";
    rightTime = rightTime ?? "3:18am";
  }

  String? leftDate;
  String? leftTime;
  String? centerLocation;
  String? centerDistance;
  String? rightDate;
  String? rightTime;

  TimelineDetailModel copyWith({
    String? leftDate,
    String? leftTime,
    String? centerLocation,
    String? centerDistance,
    String? rightDate,
    String? rightTime,
  }) {
    return TimelineDetailModel(
      leftDate: leftDate ?? this.leftDate,
      leftTime: leftTime ?? this.leftTime,
      centerLocation: centerLocation ?? this.centerLocation,
      centerDistance: centerDistance ?? this.centerDistance,
      rightDate: rightDate ?? this.rightDate,
      rightTime: rightTime ?? this.rightTime,
    );
  }

  @override
  List<Object?> get props => [
        leftDate,
        leftTime,
        centerLocation,
        centerDistance,
        rightDate,
        rightTime,
      ];
}
