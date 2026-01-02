import '../../services/push_notification_service.dart';
import '../../services/supabase_service.dart';
import '../app_export.dart';

/// Authentication Guard Middleware
/// Protects routes that require authentication by checking if user is logged in
/// Redirects unauthenticated users to login screen
class AuthGuard {
  /// List of public routes that don't require authentication
  static final List<String> publicRoutes = [
    AppRoutes.authLogin,
    AppRoutes.authRegister,
    AppRoutes.authReset,
    AppRoutes.appFeed,
    AppRoutes.splash,
    AppRoutes.appTimeline,
    AppRoutes.appTimelineSealed,
    AppRoutes.appVideoCall,
    AppRoutes.appProfile,
  ];

  /// Check if the route is public (doesn't require authentication)
  static bool isPublicRoute(String routeName) {
    return publicRoutes.contains(routeName);
  }

  /// Check if user is authenticated
  static bool isAuthenticated() {
    final client = SupabaseService.instance.client;
    if (client == null) return false;
    return client.auth.currentUser != null;
  }

  /// Guard a route - returns true if user can access, false otherwise
  /// Automatically redirects to login if authentication is required but user is not authenticated
  static bool guard(BuildContext context, String routeName) {
    // Public routes are always accessible
    if (isPublicRoute(routeName)) {
      return true;
    }

    // Protected routes require authentication
    if (!isAuthenticated()) {
      // Redirect to login screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.authLogin,
          (route) => false,
        );
      });
      return false;
    }

    // 🎯 NEW: Process any pending deep link from push notification
    PushNotificationService.processPendingDeepLink();

    return true;
  }

  /// Middleware wrapper for route protection
  /// Use this to wrap screens that require authentication
  static Widget protectedRoute(
    BuildContext context,
    String routeName,
    Widget screen,
  ) {
    if (!guard(context, routeName)) {
      return Container(); // Return empty container while redirecting
    }
    return screen;
  }
}
