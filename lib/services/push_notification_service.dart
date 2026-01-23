// lib/services/push_notification_service.dart
//
// FIX: removed call to NotificationPreferencesService.arePushEnabled()
// because your NotificationPreferencesService doesn't define that method.
// Notifications will show by default (you can re-add gating once you confirm
// the exact method name in your preferences service).

import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/models/feed_story_context.dart';
import '../core/utils/navigator_service.dart';
import '../firebase_options.dart';
import './notification_preferences_service.dart';
import './supabase_service.dart';
import 'package:flutter_udid/flutter_udid.dart';


// ✅ Platform import that doesn't break web builds.
import 'platform_stub.dart' if (dart.library.io) 'dart:io';

/// ---------------------------------------------------------------------------
/// BACKGROUND HANDLER (CRITICAL – DO NOT TOUCH UI / SUPABASE HERE)
/// ---------------------------------------------------------------------------
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // ignore duplicate init
  }

  debugPrint('📦 BG MESSAGE: ${message.messageId}');

  try {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList('pending_fcm_messages') ?? [];

    pending.add(jsonEncode({
      'data': message.data,
      'sentTime': message.sentTime?.millisecondsSinceEpoch,
    }));

    await prefs.setStringList('pending_fcm_messages', pending);
  } catch (e) {
    debugPrint('❌ BG persist failed: $e');
  }
}

/// ---------------------------------------------------------------------------
/// PUSH NOTIFICATION SERVICE
/// ---------------------------------------------------------------------------
class PushNotificationService {
  static final PushNotificationService instance =
  PushNotificationService._internal();
  factory PushNotificationService() => instance;
  PushNotificationService._internal();

  static String? pendingDeepLink;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  SupabaseClient? get _client => SupabaseService.instance.client;
  final _preferencesService = NotificationPreferencesService.instance;

  bool _isInitialized = false;
  bool _authListenerSetup = false;

  String? _fcmToken;
  String? _deviceId;

  // ✅ Android notification channel constants
  static const String _androidChannelId = 'capsule_default';
  static const String _androidChannelName = 'Capsule Notifications';
  static const String _androidChannelDescription =
      'General notifications for Capsule';

  /// -------------------------------------------------------------------------
  /// ANDROID CHANNELS (SAFE NO-OP ON iOS/WEB)
  /// -------------------------------------------------------------------------
  Future<void> initNotificationChannels() async {
    if (kIsWeb) return;
    if (!Platform.isAndroid) return;

    try {
      final androidPlugin =
      _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin == null) return;

      const channel = AndroidNotificationChannel(
        _androidChannelId,
        _androidChannelName,
        description: _androidChannelDescription,
        importance: Importance.high,
      );

      await androidPlugin.createNotificationChannel(channel);
      debugPrint('✅ Android notification channel created: $_androidChannelId');
    } catch (e, st) {
      debugPrint('❌ initNotificationChannels failed: $e');
      debugPrint('$st');
    }
  }

  /// -------------------------------------------------------------------------
  /// INIT
  /// -------------------------------------------------------------------------
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const settings =
      InitializationSettings(android: androidInit, iOS: iosInit);

      await _flutterLocalNotificationsPlugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      await _requestPermissions();

      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      await _setupFirebaseMessaging();

      _deviceId = await _generateOrGetDeviceId();
      _fcmToken = await _firebaseMessaging.getToken();

      debugPrint('✅ FCM TOKEN: $_fcmToken');

      _setupAuthStateListener();

      if (_fcmToken != null) {
        await registerToken(_fcmToken!);
      }

      _firebaseMessaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        registerToken(token);
      });

      await _processPendingBackgroundMessages();

      _isInitialized = true;
      debugPrint('✅ PushNotificationService READY');
    } catch (e, st) {
      debugPrint('❌ Push init failed: $e');
      debugPrint('$st');
    }
  }

  /// -------------------------------------------------------------------------
  /// AUTH LISTENER
  /// -------------------------------------------------------------------------
  void _setupAuthStateListener() {
    if (_authListenerSetup) return;
    _authListenerSetup = true;

    _client?.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedIn) {
        await Future.delayed(const Duration(milliseconds: 300));
        await ensureTokenRegistered();
        processPendingDeepLink();
      }

      if (data.event == AuthChangeEvent.signedOut) {
        await unregisterToken();
      }
    });
  }

  Future<void> ensureTokenRegistered() async {
    final userId = _client?.auth.currentUser?.id;
    if (userId == null) return;

    _fcmToken = await _firebaseMessaging.getToken();
    if (_fcmToken != null) {
      await registerToken(_fcmToken!);
    }
  }

  /// -------------------------------------------------------------------------
  /// FIREBASE HANDLERS
  /// -------------------------------------------------------------------------
  Future<void> _setupFirebaseMessaging() async {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    final initial = await _firebaseMessaging.getInitialMessage();
    if (initial != null) {
      _handleNotificationTap(initial);
    }
  }

  /// -------------------------------------------------------------------------
  /// PERMISSIONS
  /// -------------------------------------------------------------------------
  Future<void> _requestPermissions() async {
    if (kIsWeb) return;

    if (Platform.isIOS || Platform.isAndroid) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// -------------------------------------------------------------------------
  /// DEVICE ID
  /// -------------------------------------------------------------------------
  Future<String> _generateOrGetDeviceId() async {
    try {
      // flutter_udid provides a consistent ID that survives app reinstalls
      final udid = await FlutterUdid.consistentUdid;
      debugPrint('✅ Stable device ID: ${udid.substring(0, 8)}...');
      return udid;
    } catch (e) {
      debugPrint('⚠️ FlutterUdid failed, falling back: $e');

      // Fallback to SharedPreferences if flutter_udid fails
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString('fcm_device_id');
      if (existing != null && existing.isNotEmpty) return existing;

      final id = '${Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : 'other')}-${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('fcm_device_id', id);
      return id;
    }
  }

  /// -------------------------------------------------------------------------
  /// TOKEN REGISTRATION
  /// -------------------------------------------------------------------------
  Future<void> registerToken(String token) async {
    final userId = _client?.auth.currentUser?.id;
    if (userId == null) return;

    // Ensure we have a stable device ID
    _deviceId ??= await _generateOrGetDeviceId();

    debugPrint('🔄 Registering FCM token for device: ${_deviceId?.substring(0, 8)}...');

    await _client?.from('fcm_tokens').upsert({
      'user_id': userId,
      'token': token,
      'device_id': _deviceId,
      'device_type': Platform.isIOS
          ? 'ios'
          : (Platform.isAndroid ? 'android' : 'other'),
      'is_active': true,
      'last_used_at': DateTime.now().toIso8601String(),
    }, onConflict: 'device_id,user_id');  // <-- Changed from 'token,user_id'
  }

  Future<void> unregisterToken() async {
    try {
      // Get the CURRENT token from Firebase, not the cached _fcmToken
      final currentToken = await _firebaseMessaging.getToken();

      if (currentToken == null) {
        debugPrint('⚠️ No FCM token to unregister');
        return;
      }

      debugPrint('🔄 Unregistering FCM token: ${currentToken.substring(0, 20)}...');

      // Call the edge function which uses service role and bypasses RLS
      final response = await _client?.functions.invoke(
        'unregister-fcm-token',
        body: {
          'token': currentToken,
          'device_id': _deviceId,
        },
      );

      if (response?.status == 200) {
        debugPrint('✅ FCM token unregistered successfully: ${response?.data}');
      } else {
        debugPrint('❌ Failed to unregister token: ${response?.data}');

        // Fallback: try direct database update
        await _client?.from('fcm_tokens').update({
          'is_active': false,
        }).eq('token', currentToken);
      }

      // Clear cached values
      _fcmToken = null;
    } catch (e, st) {
      debugPrint('❌ Error unregistering FCM token: $e');
      debugPrint('$st');
    }
  }

  /// -------------------------------------------------------------------------
  /// PUBLIC LOCAL NOTIFICATION (USED BY YOUR APP)
  /// - Android: uses channel
  /// - iOS: standard local notification
  /// - Web: no-op
  /// -------------------------------------------------------------------------
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    if (kIsWeb) return;

    try {
      final notificationId =
          id ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);

      final details = NotificationDetails(
        android: Platform.isAndroid
            ? const AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        )
            : null,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e, st) {
      debugPrint('❌ showNotification failed: $e');
      debugPrint('$st');
    }
  }

  /// -------------------------------------------------------------------------
  /// FOREGROUND NOTIFICATION DISPLAY (FCM onMessage)
  /// -------------------------------------------------------------------------
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;

    // NOTE: preference gating removed to fix compilation.
    // If you want gating, paste your NotificationPreferencesService file
    // and I’ll wire it to the correct method name.

    await showNotification(
      title: n.title ?? 'Capsule',
      body: n.body ?? '',
      payload: message.data['deep_link']?.toString(),
      id: message.hashCode,
    );
  }

  /// -------------------------------------------------------------------------
  /// TAP HANDLING
  /// -------------------------------------------------------------------------
  void _handleNotificationTap(RemoteMessage message) {
    final link = message.data['deep_link'];
    if (link != null) _handleDeepLink(link);
  }

  void _onNotificationTapped(NotificationResponse response) {
    final link = response.payload;
    if (link != null) _handleDeepLink(link);
  }

  /// -------------------------------------------------------------------------
  /// DEEP LINK SAFE HANDLING
  /// -------------------------------------------------------------------------
  Future<void> _handleDeepLink(String deepLink) async {
    for (int i = 0; i < 3; i++) {
      if (NavigatorService.navigatorKey.currentState != null) {
        _navigateToPath(deepLink);
        return;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    pendingDeepLink = deepLink;
  }

  static void processPendingDeepLink() {
    if (pendingDeepLink != null) {
      instance._navigateToPath(pendingDeepLink!);
      pendingDeepLink = null;
    }
  }

  void _navigateToPath(String deepLink) {
    final uri = Uri.parse(deepLink);
    final nav = NavigatorService.navigatorKey.currentState;
    if (nav == null || uri.pathSegments.isEmpty) return;

    switch (uri.pathSegments.first) {
      case 'story':
        if (uri.pathSegments.length < 2) return;
        nav.pushNamed(
          '/app/story/view',
          arguments: FeedStoryContext(
            feedType: 'deep_link',
            initialStoryId: uri.pathSegments[1],
            storyIds: [uri.pathSegments[1]],
          ),
        );
        break;
    }
  }

  /// -------------------------------------------------------------------------
  /// BACKGROUND PAYLOAD REPLAY
  /// -------------------------------------------------------------------------
  Future<void> _processPendingBackgroundMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('pending_fcm_messages') ?? [];
    if (stored.isEmpty) return;

    for (final raw in stored) {
      final decoded = jsonDecode(raw);
      debugPrint('📦 Replayed BG payload: $decoded');
    }

    await prefs.remove('pending_fcm_messages');
  }

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;
}
