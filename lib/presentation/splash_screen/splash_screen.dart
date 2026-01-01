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
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final client = SupabaseService.instance.client;
    if (client == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.authLogin);
      return;
    }

    final currentUser = client.auth.currentUser;
    if (currentUser != null) {
      Navigator.pushReplacementNamed(
          context, AppRoutes.appFeed);
    } else {
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
              'assets/images/tmpw3ktllrh-1767232038145.jpg',
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