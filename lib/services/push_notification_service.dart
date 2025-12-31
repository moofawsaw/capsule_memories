import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/navigator_service.dart';
import './notification_preferences_service.dart';
import './supabase_service.dart';

/// Top-level function for handling background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📱 Handling background message: ${message.messageId}');
  // Handle the background message
  await PushNotificationService.instance.handleBackgroundMessage(message);
}

/// Service for handling push notifications using Firebase Cloud Messaging
/// This service manages FCM tokens and displays notifications when app is in foreground/background
class PushNotificationService {
  static final PushNotificationService instance =
      PushNotificationService._internal();
  factory PushNotificationService() => instance;
  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  final SupabaseClient? _client = SupabaseService.instance.client;
  final _preferencesService = NotificationPreferencesService.instance;

  bool _isInitialized = false;
  String? _fcmToken;
  String? _deviceId;

  /// Initialize push notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Flutter Local Notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request FCM permissions
      await _requestPermissions();

      // Setup Firebase Messaging handlers
      await _setupFirebaseMessaging();

      // Generate device ID
      _deviceId = await _generateDeviceId();

      // Get and register FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        await registerToken(_fcmToken!);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        registerToken(newToken);
      });

      _isInitialized = true;
      debugPrint('✅ Push notification service initialized with FCM');
    } catch (error) {
      debugPrint('❌ Error initializing push notifications: $error');
    }
  }

  /// Setup Firebase Messaging handlers
  Future<void> _setupFirebaseMessaging() async {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📱 Received foreground message: ${message.messageId}');
      _handleForegroundMessage(message);
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
          '📱 Notification tapped from background: ${message.messageId}');
      _handleNotificationTap(message);
    });

    // Check for initial message (when app opened from terminated state)
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
          '📱 App opened from notification: ${initialMessage.messageId}');
      _handleNotificationTap(initialMessage);
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    if (Platform.isIOS || Platform.isAndroid) {
      // Request FCM permissions
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('✅ FCM permission status: ${settings.authorizationStatus}');

      // Request local notification permissions
      if (Platform.isIOS) {
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      } else if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>();

        await androidImplementation?.requestNotificationsPermission();
      }
    }
  }

  /// Generate a unique device ID
  Future<String> _generateDeviceId() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final platform = Platform.isAndroid ? 'android' : 'ios';
    return '$platform-$timestamp';
  }

  /// Register FCM token with backend
  Future<void> registerToken(String token) async {
    try {
      final userId = _client?.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('⚠️ Cannot register token: User not authenticated');
        return;
      }

      _fcmToken = token;

      final deviceType = Platform.isAndroid ? 'android' : 'ios';

      await _client?.from('fcm_tokens').upsert({
        'user_id': userId,
        'token': token,
        'device_id': _deviceId,
        'device_type': deviceType,
        'is_active': true,
        'last_used_at': DateTime.now().toIso8601String(),
      }, onConflict: 'device_id,user_id');

      debugPrint('✅ FCM token registered successfully');
    } catch (error) {
      debugPrint('❌ Error registering FCM token: $error');
    }
  }

  /// Unregister FCM token (on logout)
  Future<void> unregisterToken() async {
    try {
      if (_deviceId == null) return;

      final userId = _client?.auth.currentUser?.id;
      if (userId == null) return;

      await _client
          ?.from('fcm_tokens')
          .update({'is_active': false})
          .eq('device_id', _deviceId!)
          .eq('user_id', userId);

      // Delete FCM token from device
      await _firebaseMessaging.deleteToken();

      _fcmToken = null;
      debugPrint('✅ FCM token unregistered');
    } catch (error) {
      debugPrint('❌ Error unregistering FCM token: $error');
    }
  }

  /// Initialize notification channels for Android
  Future<void> initNotificationChannels() async {
    if (Platform.isAndroid) {
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        const List<AndroidNotificationChannel> channels = [
          AndroidNotificationChannel(
            'memories',
            'Memories',
            description: 'Notifications about memories and stories',
            importance: Importance.high,
            playSound: true,
          ),
          AndroidNotificationChannel(
            'social',
            'Social',
            description: 'Friend requests and social updates',
            importance: Importance.high,
            playSound: true,
          ),
          AndroidNotificationChannel(
            'system',
            'System',
            description: 'System notifications',
            importance: Importance.defaultImportance,
          ),
        ];

        for (final channel in channels) {
          await androidImplementation.createNotificationChannel(channel);
        }

        debugPrint('✅ Created ${channels.length} notification channels');
      }
    }
  }

  /// Handle foreground message with image support
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    if (notification == null) return;

    // Check if there's an image
    String? imageUrl =
        notification.android?.imageUrl ?? notification.apple?.imageUrl;

    BigPictureStyleInformation? bigPictureStyle;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        // Download the image
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          bigPictureStyle = BigPictureStyleInformation(
            ByteArrayAndroidBitmap(response.bodyBytes),
            contentTitle: notification.title,
            summaryText: notification.body,
            hideExpandedLargeIcon: false,
          );
        }
      } catch (e) {
        debugPrint('Failed to download notification image: $e');
      }
    }

    // Get channel from data
    final channelId = data['channel_id'] ?? 'system';
    final channelName = _getChannelName(channelId);

    await _flutterLocalNotificationsPlugin.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: bigPictureStyle,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: data['deep_link'],
    );
  }

  /// Get channel name from channel ID
  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'memories':
        return 'Memories';
      case 'social':
        return 'Social';
      case 'system':
        return 'System';
      default:
        return 'System';
    }
  }

  /// Handle background message
  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('📱 Processing background message: ${message.messageId}');
    // Background messages are automatically handled by FCM
    // This method is for additional processing if needed
  }

  /// Handle notification tap with deep link navigation
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final deepLink = data['deep_link'];

    if (deepLink != null && deepLink.isNotEmpty) {
      debugPrint('📱 Navigating to deep link: $deepLink');
      _handleDeepLink(deepLink);
    } else {
      debugPrint('📱 Notification tapped with data: $data');
    }
  }

  /// Handle notification tap from local notifications
  void _onNotificationTapped(NotificationResponse response) {
    final deepLink = response.payload;

    if (deepLink != null && deepLink.isNotEmpty) {
      debugPrint('📱 Navigating to deep link: $deepLink');
      _handleDeepLink(deepLink);
    } else {
      debugPrint('📱 Notification tapped with payload: ${response.payload}');
    }
  }

  /// Handle deep link navigation
  void _handleDeepLink(String deepLink) {
    try {
      final uri = Uri.parse(deepLink);
      final navigatorKey = NavigatorService.navigatorKey;

      if (navigatorKey.currentState == null) {
        debugPrint('⚠️ Navigator not ready, cannot handle deep link');
        return;
      }

      switch (uri.host) {
        case 'memory':
          final memoryId =
              uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
          if (memoryId != null) {
            navigatorKey.currentState
                ?.pushNamed('/memory_details/$memoryId', arguments: memoryId);
          }
          break;
        case 'profile':
          final userId =
              uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
          if (userId != null) {
            navigatorKey.currentState
                ?.pushNamed('/user_profile/$userId', arguments: userId);
          }
          break;
        case 'friends':
          navigatorKey.currentState?.pushNamed('/friends_management');
          break;
        default:
          debugPrint('⚠️ Unknown deep link host: ${uri.host}');
      }
    } catch (e) {
      debugPrint('❌ Error handling deep link: $e');
    }
  }

  /// Show local notification (checks preferences before showing)
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
    String? notificationType,
  }) async {
    final prefs = await _preferencesService.loadPreferences();
    if (prefs != null) {
      final pushEnabled = prefs['push_notifications_enabled'] ?? true;
      if (!pushEnabled) {
        debugPrint('⚠️ Push notifications disabled globally');
        return;
      }

      if (notificationType != null) {
        final typeEnabled = prefs[notificationType] ?? true;
        if (!typeEnabled) {
          debugPrint('⚠️ Notification type $notificationType disabled');
          return;
        }
      }
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'capsule_notifications',
      'Capsule Notifications',
      channelDescription: 'Notifications for Capsule app events',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Create notification channel (Android only)
  Future<void> createNotificationChannel() async {
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'capsule_notifications',
        'Capsule Notifications',
        description: 'Notifications for Capsule app events',
        importance: Importance.high,
      );

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}
