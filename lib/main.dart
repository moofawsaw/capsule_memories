import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './core/utils/theme_provider.dart';
import './presentation/notifications_screen/notifier/notifications_notifier.dart';
import './services/notification_service.dart';
import './services/supabase_service.dart';
import 'core/app_export.dart';

var globalMessengerKey = GlobalKey<ScaffoldMessengerState>();

// Global ProviderContainer for notification state management
// Reusing container prevents memory leaks from repeated creation
late ProviderContainer _globalContainer;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize global provider container once
  _globalContainer = ProviderContainer();

  final bool supabaseReady = await _initSupabaseSafely();

  if (supabaseReady) {
    _setupGlobalNotificationListener();
  } else {
    debugPrint('Supabase not initialized. Skipping auth listener setup.');
  }

  runApp(
    ProviderScope(
      parent: _globalContainer,
      child: Sizer(
        builder: (context, orientation, deviceType) {
          return MyApp();
        },
      ),
    ),
  );
}

Future<bool> _initSupabaseSafely() async {
  try {
    await SupabaseService.initialize();

    // Hard assertion: ensures the client exists right now
    Supabase.instance.client;
    return true;
  } catch (e, st) {
    debugPrint('Failed to initialize Supabase: $e');
    debugPrint('$st');
    return false;
  }
}

void _setupGlobalNotificationListener() {
  final notificationService = NotificationService.instance;

  Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
    if (data.event == AuthChangeEvent.signedIn) {
      // 🔥 STEP 1: Load initial notification count on login
      await _loadInitialNotificationCount();

      // 🔥 STEP 2: Subscribe to real-time updates with optimized callback
      notificationService.subscribeToNotifications(
        onNewNotification: (notification) async {
          debugPrint('New notification: ${notification['title']}');
          // 🔥 STEP 3: Reload notification count when new notification arrives
          // This is now debounced in NotificationService to prevent excessive updates
          await _loadInitialNotificationCount();
        },
      );
    } else if (data.event == AuthChangeEvent.signedOut) {
      notificationService.unsubscribeFromNotifications();
    }
  });

  // 🔥 STEP 4: Load notification count if user is already logged in
  if (Supabase.instance.client.auth.currentUser != null) {
    _loadInitialNotificationCount();
  }
}

/// Load initial notification count and update global notifier
/// This ensures the notification badge shows correct count on app load
/// Optimized to reuse global container and prevent memory leaks
Future<void> _loadInitialNotificationCount() async {
  try {
    final notificationService = NotificationService.instance;

    // Fetch all notifications to calculate unread count
    // This operation is now optimized with proper error handling
    final notifications = await notificationService.getNotifications();

    // Update the global notifier with notification data
    // Reusing _globalContainer prevents memory leaks from repeated ProviderContainer creation
    _globalContainer
        .read(notificationsNotifier.notifier)
        .setNotifications(notifications);

    debugPrint('✅ Initial notification count loaded: ${notifications.length}');
  } catch (error) {
    debugPrint('❌ Failed to load initial notification count: $error');
    // Graceful degradation - app continues to work even if notification count fails
  }
}

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      theme: ThemeHelper().themeData(),
      darkTheme: ThemeHelper().themeData(),
      themeMode: themeMode,
      title: 'capsule_memories',
      builder: (context, child) {
        ThemeHelper().setThemeMode(themeMode);

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
      navigatorKey: NavigatorService.navigatorKey,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      initialRoute: AppRoutes.initialRoute,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
