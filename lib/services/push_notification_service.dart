import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import './supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for handling push notifications using Flutter Local Notifications
/// This service manages FCM tokens and displays notifications when app is in foreground/background
class PushNotificationService {
  static final PushNotificationService instance =
      PushNotificationService._internal();
  factory PushNotificationService() => instance;
  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final SupabaseClient? _client = SupabaseService.instance.client;

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

      // Request permissions
      await _requestPermissions();

      // Generate device ID (in production, use a proper device ID package)
      _deviceId = await _generateDeviceId();

      _isInitialized = true;
      debugPrint('✅ Push notification service initialized');
    } catch (error) {
      debugPrint('❌ Error initializing push notifications: $error');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
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

  /// Generate a unique device ID
  Future<String> _generateDeviceId() async {
    // In production, use device_info_plus package to get actual device ID
    // For now, generate a simple unique ID
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

      // Upsert token in database
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

      _fcmToken = null;
      debugPrint('✅ FCM token unregistered');
    } catch (error) {
      debugPrint('❌ Error unregistering FCM token: $error');
    }
  }

  /// Show local notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
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

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notification tapped with payload: ${response.payload}');
    // Navigate to appropriate screen based on payload
    // This will be handled by the app's navigation logic
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