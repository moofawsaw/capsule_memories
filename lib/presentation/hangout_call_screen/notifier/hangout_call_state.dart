part of 'hangout_call_notifier.dart';

class HangoutCallState extends Equatable {
  final bool? isLoading;
  final bool? shouldExitCall;
  final bool? showMenu;
  final HangoutCallModel? hangoutCallModel;

  HangoutCallState({
    this.isLoading = false,
    this.shouldExitCall = false,
    this.showMenu = false,
    this.hangoutCallModel,
  });

  @override
  List<Object?> get props => [
        isLoading,
        shouldExitCall,
        showMenu,
        hangoutCallModel,
      ];

  HangoutCallState copyWith({
    bool? isLoading,
    bool? shouldExitCall,
    bool? showMenu,
    HangoutCallModel? hangoutCallModel,
  }) {
    return HangoutCallState(
      isLoading: isLoading ?? this.isLoading,
      shouldExitCall: shouldExitCall ?? this.shouldExitCall,
      showMenu: showMenu ?? this.showMenu,
      hangoutCallModel: hangoutCallModel ?? this.hangoutCallModel,
    );
  }
}
