import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateAfterDelay();
    });
  }

  Future<void> _navigateAfterDelay() async {
    // Wait for splash screen animation (3 seconds)
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final client = SupabaseService.instance.client;
    if (client == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.authLogin);
      return;
    }

    // 🔑 SESSION RESTORATION: Wait for potential session recovery
    // After OAuth sign-in, the app restarts and Supabase automatically attempts
    // to restore the session using the refresh token stored in secure storage
    try {
      debugPrint('🔍 Checking for existing session...');

      // Give Supabase time to restore session from refresh token
      // The SDK automatically handles this, we just need to wait briefly
      await Future.delayed(const Duration(milliseconds: 500));

      final session = client.auth.currentSession;
      final currentUser = client.auth.currentUser;

      if (session != null && currentUser != null) {
        debugPrint('✅ Session restored successfully for: ${currentUser.email}');
        debugPrint('   Session expires at: ${session.expiresAt}');
        debugPrint(
            '   Access token present: ${session.accessToken.isNotEmpty}');

        // Navigate to feed screen with restored session
        Navigator.pushReplacementNamed(context, AppRoutes.appFeed);
      } else {
        debugPrint('ℹ️ No active session found, redirecting to login');
        Navigator.pushReplacementNamed(context, AppRoutes.authLogin);
      }
    } catch (e) {
      debugPrint('❌ Error during session check: $e');
      // On error, safely redirect to login
      Navigator.pushReplacementNamed(context, AppRoutes.authLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6A42C2), // Deep purple background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Centered splash logo image
            Image.asset(
              'assets/images/android_splash.png',
              width: 200.0,
              height: 200.0,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}
