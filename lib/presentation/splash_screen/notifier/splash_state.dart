part of 'splash_notifier.dart';

class SplashState extends Equatable {
  final SplashModel? splashModel;
  final bool? shouldNavigate;

  SplashState({
    this.splashModel,
    this.shouldNavigate = false,
  });

  @override
  List<Object?> get props => [
        splashModel,
        shouldNavigate,
      ];

  SplashState copyWith({
    SplashModel? splashModel,
    bool? shouldNavigate,
  }) {
    return SplashState(
      splashModel: splashModel ?? this.splashModel,
      shouldNavigate: shouldNavigate ?? this.shouldNavigate,
    );
  }
}
