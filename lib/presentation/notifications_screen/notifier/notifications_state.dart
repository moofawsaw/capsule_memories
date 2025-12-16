part of 'notifications_notifier.dart';

class NotificationsState extends Equatable {
  final bool? isLoading;
  final bool? isMarkAsReadSuccess;
  final NotificationsModel? notificationsModel;

  NotificationsState({
    this.isLoading = false,
    this.isMarkAsReadSuccess = false,
    this.notificationsModel,
  });

  @override
  List<Object?> get props => [
        isLoading,
        isMarkAsReadSuccess,
        notificationsModel,
      ];

  NotificationsState copyWith({
    bool? isLoading,
    bool? isMarkAsReadSuccess,
    NotificationsModel? notificationsModel,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      isMarkAsReadSuccess: isMarkAsReadSuccess ?? this.isMarkAsReadSuccess,
      notificationsModel: notificationsModel ?? this.notificationsModel,
    );
  }
}
