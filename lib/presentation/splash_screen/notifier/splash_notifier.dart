import '../models/splash_model.dart';
import '../../../core/app_export.dart';

part 'splash_state.dart';

final splashNotifier =
    StateNotifierProvider.autoDispose<SplashNotifier, SplashState>(
  (ref) => SplashNotifier(
    SplashState(
      splashModel: SplashModel(),
    ),
  ),
);

class SplashNotifier extends StateNotifier<SplashState> {
  SplashNotifier(SplashState state) : super(state);

  void initialize() {
    // Start splash timer for 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      state = state.copyWith(shouldNavigate: true);
    });
  }
}
