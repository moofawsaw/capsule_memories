part of 'notifications_notifier.dart';

class NotificationsState extends Equatable {
  NotificationsState({
    this.notificationsModel,
    this.isLoading,
    this.isMarkAsReadSuccess,
    this.toggleMessage,
  });

  NotificationsModel? notificationsModel;
  bool? isLoading;
  bool? isMarkAsReadSuccess;
  String? toggleMessage;

  @override
  List<Object?> get props => [
        notificationsModel,
        isLoading,
        isMarkAsReadSuccess,
        toggleMessage,
      ];

  NotificationsState copyWith({
    NotificationsModel? notificationsModel,
    bool? isLoading,
    bool? isMarkAsReadSuccess,
    String? toggleMessage,
  }) {
    return NotificationsState(
      notificationsModel: notificationsModel ?? this.notificationsModel,
      isLoading: isLoading ?? this.isLoading,
      isMarkAsReadSuccess: isMarkAsReadSuccess ?? this.isMarkAsReadSuccess,
      toggleMessage: toggleMessage ?? this.toggleMessage,
    );
  }
}
