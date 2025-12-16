import '../../../core/app_export.dart';

/// This class is used in the [group_join_confirmation_screen] screen.

// ignore_for_file: must_be_immutable
class GroupJoinConfirmationModel extends Equatable {
  GroupJoinConfirmationModel({
    this.groupName,
    this.confirmationMessage,
    this.remainingTime,
    this.id,
  }) {
    groupName = groupName ?? "Fmaily Xmas 2025";
    confirmationMessage =
        confirmationMessage ?? "You have successfully joined Family Xmas 2025";
    remainingTime = remainingTime ?? "12 hours remaining";
    id = id ?? "";
  }

  String? groupName;
  String? confirmationMessage;
  String? remainingTime;
  String? id;

  GroupJoinConfirmationModel copyWith({
    String? groupName,
    String? confirmationMessage,
    String? remainingTime,
    String? id,
  }) {
    return GroupJoinConfirmationModel(
      groupName: groupName ?? this.groupName,
      confirmationMessage: confirmationMessage ?? this.confirmationMessage,
      remainingTime: remainingTime ?? this.remainingTime,
      id: id ?? this.id,
    );
  }

  @override
  List<Object?> get props =>
      [groupName, confirmationMessage, remainingTime, id];
}
