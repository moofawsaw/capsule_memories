// lib/main.dart
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_export.dart';
import 'core/app_scaffold_messenger.dart';
import 'core/services/deep_link_service.dart';
import 'core/utils/theme_provider.dart';
import 'firebase_options.dart';
import 'presentation/notifications_screen/notifier/notifications_notifier.dart';
import 'services/network_quality_service.dart';
import 'services/notification_service.dart';
import 'services/push_notification_service.dart';
import 'services/supabase_service.dart';

var globalMessengerKey = GlobalKey<ScaffoldMessengerState>();

// Global ProviderContainer for notification state management
// Reusing container prevents memory leaks from repeated creation
late ProviderContainer _globalContainer;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase exactly once (avoid [core/duplicate-app])
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    final msg = e.toString();
    if (msg.contains('core/duplicate-app') ||
        msg.contains('A Firebase App named "[DEFAULT]" already exists')) {
      debugPrint('⚠️ Firebase already initialized (ignoring duplicate-app).');
    } else {
      rethrow;
    }
  }

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
      '   flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key',
    );
  }

  // 🎯 Initialize notification channels (Android only internally; safe on iOS)
  await PushNotificationService.instance.initNotificationChannels();

  // 🎯 Initialize push notifications with FCM token registration
  // This also sets up all notification handlers internally
  await PushNotificationService.instance.initialize();

  // 🎯 Initialize deep link service for QR code handling
  await DeepLinkService().initialize();

  runApp(
    AppScaffoldMessenger(
      child: ProviderScope(
        parent: _globalContainer,
        child: Sizer(
          builder: (context, orientation, deviceType) {
            return MyApp();
          },
        ),
      ),
    ),
  );
}

Future<bool> _initSupabaseSafely() async {
  try {
    await SupabaseService.initialize();

    final client = SupabaseService.instance.client;
    if (client == null) return false;

    // ✅ warms TUS DNS/TLS + store + auth path
    unawaited(SupabaseService.instance.warmUploadPipeline());

    // ✅ prime network quality cache
    NetworkQualityService.prime();

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
  debugPrint('⚠️ _setupNotificationHandlers is deprecated and does nothing');
}

void _setupGlobalNotificationListener() {
  try {
    final client = SupabaseService.instance.client;
    if (client == null) {
      debugPrint('⚠️ Cannot setup notification listener - Supabase client is null');
      return;
    }

    final notificationService = NotificationService.instance;

    client.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedIn) {
        debugPrint('✅ User signed in successfully: ${data.session?.user.email}');

        // 🔥 STEP 1: Load initial notification count on login
        await _loadInitialNotificationCount();

        // 🔥 STEP 2: Subscribe to real-time updates with optimized callback
        notificationService.subscribeToNotifications(
          onNewNotification: (notification) async {
            debugPrint('New notification: ${notification['title']}');

            // OPTIONAL: local notification for foreground (Android handled by channels internally)
            // Safe on iOS (no-op internally if not supported)
            await PushNotificationService.instance.showNotification(
              title: (notification['title'] ?? 'Capsule').toString(),
              body: (notification['body'] ?? '').toString(),
              payload: notification['deep_link']?.toString(),
            );

            // 🔥 STEP 3: Reload notification count when new notification arrives
            await _loadInitialNotificationCount();
          },
        );

        // 🎯 ENHANCED: Navigate to feed after successful sign-in
        try {
          await Future.delayed(const Duration(milliseconds: 500));

          NavigatorService.pushNamedAndRemoveUntil(
            AppRoutes.appFeed,
          );

          debugPrint('✅ Navigated to feed after OAuth sign-in');
        } catch (navError) {
          debugPrint('⚠️ Navigation error after sign-in: $navError');
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
Future<void> _loadInitialNotificationCount() async {
  try {
    final notificationService = NotificationService.instance;

    final notifications = await notificationService.getNotifications();

    _globalContainer
        .read(notificationsNotifier.notifier)
        .setNotifications(notifications);

    debugPrint('✅ Initial notification count loaded: ${notifications.length}');
  } catch (error) {
    debugPrint('❌ Failed to load initial notification count: $error');
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
      title: 'Capsule',
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
