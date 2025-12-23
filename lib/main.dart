import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './core/utils/theme_provider.dart';
import './services/notification_service.dart';
import './services/supabase_service.dart';
import 'core/app_export.dart';

var globalMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
  }

  _setupGlobalNotificationListener();

  runApp(
    ProviderScope(
      child: Sizer(builder: (context, orientation, deviceType) {
        return MyApp();
      }),
    ),
  );
}

void _setupGlobalNotificationListener() {
  final notificationService = NotificationService.instance;

  // Listen to auth state changes to setup/teardown notification subscription
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.signedIn) {
      // Setup notification subscription when user signs in
      notificationService.subscribeToNotifications(
        onNewNotification: (notification) {
          // Global notification handler can be implemented here
          debugPrint('New notification: ${notification['title']}');
        },
      );
    } else if (data.event == AuthChangeEvent.signedOut) {
      // Cleanup subscription when user signs out
      notificationService.unsubscribeFromNotifications();
    }
  });
}

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      theme: ThemeHelper().getThemeData(ThemeMode.light),
      darkTheme: ThemeHelper().getThemeData(ThemeMode.dark),
      themeMode: themeMode,
      title: 'capsule_memories',
      // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
      builder: (context, child) {
        // Update global theme instance on every rebuild
        ThemeHelper().setThemeMode(themeMode);

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
      // 🚨 END CRITICAL SECTION
      navigatorKey: NavigatorService.navigatorKey,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('en', '')],
      initialRoute: AppRoutes.initialRoute,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
