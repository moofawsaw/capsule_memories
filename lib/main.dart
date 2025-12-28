import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './core/utils/theme_provider.dart';
import './services/notification_service.dart';
import './services/supabase_service.dart';
import 'core/app_export.dart';

var globalMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bool supabaseReady = await _initSupabaseSafely();

  if (supabaseReady) {
    _setupGlobalNotificationListener();
  } else {
    debugPrint('Supabase not initialized. Skipping auth listener setup.');
  }

  runApp(
    ProviderScope(
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

  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.signedIn) {
      notificationService.subscribeToNotifications(
        onNewNotification: (notification) {
          debugPrint('New notification: ${notification['title']}');
        },
      );
    } else if (data.event == AuthChangeEvent.signedOut) {
      notificationService.unsubscribeFromNotifications();
    }
  });
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
