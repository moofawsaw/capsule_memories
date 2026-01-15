import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './core/services/deep_link_service.dart';
import './core/utils/theme_provider.dart';
import './firebase_options.dart';
import './presentation/notifications_screen/notifier/notifications_notifier.dart';
import './services/notification_service.dart';
import './services/push_notification_service.dart';
import './services/supabase_service.dart';
import 'core/app_export.dart';

var globalMessengerKey = GlobalKey<ScaffoldMessengerState>();

// Global ProviderContainer for notification state management
// Reusing container prevents memory leaks from repeated creation
late ProviderContainer _globalContainer;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific configuration
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize global provider container once
  _globalContainer = ProviderContainer();

  // Initialize Supabase with improved error handling
  final bool supabaseReady = await _initSupabaseSafely();

  if (supabaseReady) {
    // Setup notification listener
    _setupGlobalNotificationListener();
  } else {
    // Provide clear feedback when Supabase is not initialized
    debugPrint('⚠️ Supabase not initialized. App will run in limited mode.');
    debugPrint('   To enable full functionality, set environment variables:');
    debugPrint(
        '   flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key');
  }

  // 🎯 Initialize notification channels
  await PushNotificationService.instance.initNotificationChannels();

  // 🎯 Initialize push notifications with FCM token registration
  // This also sets up all notification handlers internally
  await PushNotificationService.instance.initialize();

  // 🎯 Initialize deep link service for QR code handling
  await DeepLinkService().initialize();

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

    // Verify the client is accessible
    final client = SupabaseService.instance.client;
    if (client == null) {
      debugPrint('⚠️ Supabase client is null after initialization');
      return false;
    }

    // Additional verification
    debugPrint('✅ Supabase client verified and ready');
    return true;
  } catch (e, st) {
    debugPrint('❌ Failed to initialize Supabase: $e');
    debugPrint('Stack trace: $st');
    return false;
  }
}

/// 🎯 Setup notification handlers for deep link navigation
/// Handles notification taps when app is in foreground, background, or terminated
/// NOTE: This function is now deprecated as PushNotificationService handles all notification logic internally
@Deprecated('Use PushNotificationService.instance.initialize() instead')
Future<void> _setupNotificationHandlers() async {
  // This function is no longer needed as PushNotificationService handles everything
  debugPrint('⚠️ _setupNotificationHandlers is deprecated and does nothing');
}

void _setupGlobalNotificationListener() {
  try {
    final client = SupabaseService.instance.client;
    if (client == null) {
      debugPrint(
          '⚠️ Cannot setup notification listener - Supabase client is null');
      return;
    }

    final notificationService = NotificationService.instance;

    client.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedIn) {
        debugPrint(
            '✅ User signed in successfully: ${data.session?.user.email}');

        // 🔥 STEP 1: Load initial notification count on login
        await _loadInitialNotificationCount();

        // 🔥 STEP 2: Subscribe to real-time updates with optimized callback
        notificationService.subscribeToNotifications(
          onNewNotification: (notification) async {
            debugPrint('New notification: ${notification['title']}');
            // 🔥 STEP 3: Reload notification count when new notification arrives
            await _loadInitialNotificationCount();
          },
        );

        // 🎯 ENHANCED: Navigate to feed after successful sign-in
        // This ensures OAuth redirects properly route to app content
        try {
          // Short delay to ensure UI is ready for navigation
          await Future.delayed(const Duration(milliseconds: 500));

          // Navigate to feed screen, removing all previous routes
          NavigatorService.pushNamedAndRemoveUntil(
            AppRoutes.appFeed,
          );

          debugPrint('✅ Navigated to feed after OAuth sign-in');
        } catch (navError) {
          debugPrint('⚠️ Navigation error after sign-in: $navError');
          // Non-critical error - user is still authenticated
        }
      } else if (data.event == AuthChangeEvent.signedOut) {
        debugPrint('👋 User signed out');
        notificationService.unsubscribeFromNotifications();
      }
    });

    // 🔥 STEP 4: Load notification count if user is already logged in
    if (client.auth.currentUser != null) {
      debugPrint('✅ User already logged in on app start');
      _loadInitialNotificationCount();
    }
  } catch (e, st) {
    debugPrint('❌ Error setting up notification listener: $e');
    debugPrint('Stack trace: $st');
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
      theme: ThemeHelper().lightTheme(),
      darkTheme: ThemeHelper().darkTheme(),
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
      initialRoute: AppRoutes.initialRoute, // now /splash
      onGenerateRoute: AppRoutes.onGenerateRoute,

    );
  }
}
