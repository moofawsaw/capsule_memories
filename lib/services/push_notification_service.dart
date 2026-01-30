// lib/services/push_notification_service.dart
//
// Supports rich image notifications on Android foreground AND background
// with circular avatar support

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/deep_link_service.dart';
import '../core/utils/navigator_service.dart';
import '../firebase_options.dart';
import './supabase_service.dart';
import 'package:flutter_udid/flutter_udid.dart';

// ✅ Platform import that doesn't break web builds.
import 'platform_stub.dart' if (dart.library.io) 'dart:io';

// ---------------------------------------------------------------------------
// Deep link normalization
// ---------------------------------------------------------------------------
// Keep this as a string constant so it works in background isolate too.
const String _dailyCapsuleDeepLink = '/app/daily-capsule';

String? _normalizeDeepLinkFromData(Map<String, dynamic> data, String? raw) {
  final candidate = (raw ?? '').toString().trim();

  // If server already provided a deep link, normalize common legacy variants.
  if (candidate.isNotEmpty) {
    final v = candidate.replaceAll('\\', '/').trim();
    if (v == '/daily-capsule' || v == '/daily_capsule') return _dailyCapsuleDeepLink;
    if (v == '/app/daily_capsule' || v == '/app/dailycapsule') return _dailyCapsuleDeepLink;
    return v;
  }

  // Fallback to known data keys
  final kind = (data['kind'] ??
          data['type'] ??
          data['notification_type'] ??
          data['notificationType'] ??
          '')
      .toString()
      .trim()
      .toLowerCase();

  // Daily Capsule: reminders + friend completion should navigate to Daily Capsule screen.
  if (kind == 'daily_capsule_reminder' ||
      kind == 'daily-capsule-reminder' ||
      kind == 'friend_daily_capsule_completed' ||
      kind == 'friend-daily-capsule-completed') {
    return _dailyCapsuleDeepLink;
  }

  return null;
}

/// ---------------------------------------------------------------------------
/// TOP-LEVEL HELPER: Create circular bitmap from image bytes
/// Must be top-level so background isolate can access it
/// ---------------------------------------------------------------------------
Future<Uint8List?> _createCircularBitmapFromBytes(Uint8List imageBytes) async {
  try {
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final size = math.min(image.width, image.height).toDouble();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint()..isAntiAlias = true;

    final rect = ui.Rect.fromLTWH(0, 0, size, size);

    // Clip to circle
    canvas.clipPath(ui.Path()..addOval(rect));

    // Center-crop source to square
    final srcLeft = ((image.width.toDouble() - size) / 2.0).clamp(0.0, image.width.toDouble());
    final srcTop = ((image.height.toDouble() - size) / 2.0).clamp(0.0, image.height.toDouble());
    final srcRect = ui.Rect.fromLTWH(srcLeft, srcTop, size, size);

    canvas.drawImageRect(image, srcRect, rect, paint);

    final picture = recorder.endRecording();
    final circularImage = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await circularImage.toByteData(format: ui.ImageByteFormat.png);

    image.dispose();
    circularImage.dispose();

    return byteData?.buffer.asUint8List();
  } catch (e) {
    debugPrint('❌ Circular bitmap creation failed: $e');
    return null;
  }
}

/// ---------------------------------------------------------------------------
/// BACKGROUND HANDLER (CRITICAL – DO NOT TOUCH UI / SUPABASE HERE)
/// ---------------------------------------------------------------------------
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}

  debugPrint('📦 BG MESSAGE: ${message.messageId}');

  // ✅ On iOS, the system ALREADY displays the notification via APNs
  // NotificationServiceExtension handles rich content (images)
  // Do NOT create a duplicate local notification
  final bool isIOS = Platform.isIOS;

  if (!isIOS) {
    // Android: Show rich notification with circular avatar support
    final title = message.notification?.title ?? message.data['title'];
    final body = message.notification?.body ?? message.data['body'];

    if (title != null && body != null) {
      try {
        final plugin = FlutterLocalNotificationsPlugin();

        const androidInit = AndroidInitializationSettings('@drawable/ic_stat_notification');
        await plugin.initialize(
          const InitializationSettings(android: androidInit),
        );

        // Extract image info from data payload
        String? imageUrl = message.notification?.android?.imageUrl;
        if (imageUrl == null || imageUrl.isEmpty) {
          imageUrl = message.data['image'] as String?;
        }
        if (imageUrl == null || imageUrl.isEmpty) {
          imageUrl = message.data['image_url'] as String?;
        }
        if (imageUrl == null || imageUrl.isEmpty) {
          imageUrl = message.data['fcm_options_image'] as String?;
        }

        final String? imageType = message.data['image_type'] as String?;
        final bool isAvatar = imageType == 'user_avatar' || imageType == 'avatar';
        final bool isIcon = imageType == 'icon';
        final bool useCompactLargeIcon = isAvatar || isIcon;

        debugPrint(
            '📦 BG image: $imageUrl, type: $imageType, isAvatar: $isAvatar, isIcon: $isIcon');

        AndroidBitmap<Object>? largeIcon;
        StyleInformation? styleInformation;

        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            final response = await http
                .get(Uri.parse(imageUrl))
                .timeout(const Duration(seconds: 10));

            if (response.statusCode == 200) {
              if (useCompactLargeIcon) {
                if (isAvatar) {
                  // Circular avatar for compact largeIcon
                  final circularBytes =
                      await _createCircularBitmapFromBytes(response.bodyBytes);
                  if (circularBytes != null) {
                    largeIcon = ByteArrayAndroidBitmap(circularBytes);
                    debugPrint('✅ BG circular avatar created');
                  }
                } else {
                  // "icon" type: show as compact largeIcon (no circle crop)
                  largeIcon = ByteArrayAndroidBitmap(response.bodyBytes);
                  debugPrint('✅ BG icon largeIcon ready');
                }
              } else {
                // Rectangle BigPicture for expanded view (stories, memories, etc.)
                final tempDir = await getTemporaryDirectory();
                final file = io.File('${tempDir.path}/bg_notification_${message.hashCode}.jpg');
                await file.writeAsBytes(response.bodyBytes, flush: true);

                styleInformation = BigPictureStyleInformation(
                  FilePathAndroidBitmap(file.path),
                  contentTitle: title,
                  summaryText: body,
                  hideExpandedLargeIcon: true,
                );
                debugPrint('✅ BG BigPicture image ready');
              }
            }
          } catch (e) {
            debugPrint('⚠️ BG image download failed: $e');
          }
        }

        await plugin.show(
          message.hashCode,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'capsule_default',
              'Capsule Notifications',
              channelDescription: 'General notifications for Capsule',
              importance: Importance.high,
              priority: Priority.high,
              icon: 'ic_stat_notification',
              largeIcon: largeIcon,
              styleInformation: styleInformation,
            ),
          ),
          payload: _normalizeDeepLinkFromData(
            message.data,
            message.data['deep_link']?.toString(),
          ),
        );

        debugPrint('✅ Android BG notification displayed: $title');
      } catch (e) {
        debugPrint('❌ BG notification display failed: $e');
      }
    }
  } else {
    debugPrint('📱 iOS: System handles notification display, skipping local');
  }

  // Keep existing persistence logic for deep link handling
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

  bool _isInitialized = false;
  bool _authListenerSetup = false;

  String? _fcmToken;
  String? _deviceId;

  // Foreground duplicate prevention:
  // - In this app we can receive both an FCM push AND a realtime DB INSERT
  //   for the same event while the app is foreground.
  // - The realtime path sometimes has an empty body -> "title-only" notification.
  // - We defensively dedupe identical notifications in a short window.
  static const Duration _dedupeWindow = Duration(seconds: 3);
  final Map<String, int> _recentNotificationSignatures = <String, int>{};

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
      AndroidInitializationSettings('@drawable/ic_stat_notification');

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

      // Keep iOS app icon badge in sync on startup (best-effort).
      unawaited(_refreshIosBadgeCount());

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
        unawaited(_refreshIosBadgeCount());
      }

      if (data.event == AuthChangeEvent.signedOut) {
        await unregisterToken();
        unawaited(_setIosBadgeCount(0));
      }
    });
  }

  Future<void> _setIosBadgeCount(int count) async {
    if (kIsWeb) return;
    if (!Platform.isIOS) return;
    try {
      await _flutterLocalNotificationsPlugin.show(
        0,
        null,
        null,
        NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: false,
            presentSound: false,
            presentBadge: true,
            presentBanner: false,
            presentList: false,
            badgeNumber: count,
          ),
        ),
      );
    } catch (e) {
      debugPrint('⚠️ setBadgeCount failed: $e');
    }
  }

  /// Fetch unread notification count from DB and apply to iOS app icon badge.
  Future<void> _refreshIosBadgeCount() async {
    if (kIsWeb) return;
    if (!Platform.isIOS) return;

    try {
      final client = _client;
      final userId = client?.auth.currentUser?.id;
      if (client == null || userId == null) {
        await _setIosBadgeCount(0);
        return;
      }

      // Avoid null-filter API inconsistencies by filtering soft-deletes client-side.
      final res = await client
          .from('notifications')
          .select('id, is_read, deleted_at')
          .eq('user_id', userId);

      final rows = List<Map<String, dynamic>>.from(res);
      final unreadCount = rows
          .where((n) => n['deleted_at'] == null)
          .where((n) => (n['is_read'] as bool?) == false)
          .length;

      await _setIosBadgeCount(unreadCount);
    } catch (e) {
      debugPrint('⚠️ refresh badge failed: $e');
    }
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
      final udid = await FlutterUdid.consistentUdid;
      debugPrint('✅ Stable device ID: ${udid.substring(0, 8)}...');
      return udid;
    } catch (e) {
      debugPrint('⚠️ FlutterUdid failed, falling back: $e');

      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString('fcm_device_id');
      if (existing != null && existing.isNotEmpty) return existing;

      final id =
          '${Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : 'other')}-${DateTime.now().millisecondsSinceEpoch}';
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

    _deviceId ??= await _generateOrGetDeviceId();

    debugPrint(
        '🔄 Registering FCM token for device: ${_deviceId?.substring(0, 8)}...');

    final deviceType =
    Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : 'unknown');

    try {
      await _client
          ?.from('fcm_tokens')
          .update({
        'is_active': false,
      })
          .eq('user_id', userId)
          .eq('device_type', deviceType)
          .neq('device_id', _deviceId!);

      debugPrint('✅ Deactivated old tokens for device type: $deviceType');

      await _client?.from('fcm_tokens').upsert({
        'user_id': userId,
        'token': token,
        'device_id': _deviceId,
        'device_type': deviceType,
        'is_active': true,
        'last_used_at': DateTime.now().toIso8601String(),
      }, onConflict: 'device_id,user_id');

      debugPrint('✅ FCM token registered successfully');
    } catch (e, st) {
      debugPrint('❌ FCM token registration failed: $e');
      debugPrint('$st');
    }
  }

  Future<void> unregisterToken() async {
    try {
      final currentToken = await _firebaseMessaging.getToken();

      if (currentToken == null) {
        debugPrint('⚠️ No FCM token to unregister');
        return;
      }

      debugPrint(
          '🔄 Unregistering FCM token: ${currentToken.substring(0, 20)}...');

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

        await _client
            ?.from('fcm_tokens')
            .update({
          'is_active': false,
        })
            .eq('token', currentToken);
      }

      _fcmToken = null;
    } catch (e, st) {
      debugPrint('❌ Error unregistering FCM token: $e');
      debugPrint('$st');
    }
  }

  /// -------------------------------------------------------------------------
  /// PUBLIC LOCAL NOTIFICATION
  /// - Android: uses channel + supports rich images via BigPictureStyleInformation
  ///            OR circular avatar via largeIcon
  /// - iOS: standard local notification
  /// - Web: no-op
  /// -------------------------------------------------------------------------
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int? id,
    String? imageUrl,
    String? imageType,
  }) async {
    if (kIsWeb) return;

    try {
      final normalizedTitle = title.trim();
      final normalizedBody = body.trim();

      // Avoid "title-only" duplicates (common from realtime insert payloads).
      // If you truly want title-only notifications later, add an explicit flag.
      if (normalizedBody.isEmpty) {
        debugPrint('🔕 Skipping notification with empty body: $normalizedTitle');
        return;
      }

      final signature = [
        normalizedTitle,
        normalizedBody,
        (payload ?? '').trim(),
        (imageUrl ?? '').trim(),
        (imageType ?? '').trim(),
      ].join('|');

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      _pruneRecentNotificationSignatures(nowMs);
      final lastShownMs = _recentNotificationSignatures[signature];
      if (lastShownMs != null &&
          (nowMs - lastShownMs) <= _dedupeWindow.inMilliseconds) {
        debugPrint('🔁 Deduped notification (recently shown): $normalizedTitle');
        return;
      }
      _recentNotificationSignatures[signature] = nowMs;

      // Prefer a stable ID so duplicate calls update instead of creating another.
      final notificationId = id ?? (signature.hashCode & 0x7fffffff);

      StyleInformation? styleInformation;
      AndroidBitmap<Object>? largeIcon;

      if (!kIsWeb && Platform.isAndroid) {
        // Determine if this should show in compact view as a largeIcon
        final bool isAvatar = imageType == 'user_avatar' || imageType == 'avatar';
        final bool isIcon = imageType == 'icon';
        final bool useCompactLargeIcon = isAvatar || isIcon;

        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            debugPrint('🖼️ Downloading notification image: $imageUrl');
            debugPrint(
                '🖼️ Image type: $imageType, isAvatar: $isAvatar, isIcon: $isIcon');

            final response = await http
                .get(Uri.parse(imageUrl))
                .timeout(const Duration(seconds: 10));

            if (response.statusCode == 200) {
              if (useCompactLargeIcon) {
                if (isAvatar) {
                  // Circular avatar for compact largeIcon
                  final circularBytes =
                      await _createCircularBitmapFromBytes(response.bodyBytes);
                  if (circularBytes != null) {
                    largeIcon = ByteArrayAndroidBitmap(circularBytes);
                    debugPrint('✅ Circular avatar created for notification');
                  }
                } else {
                  // "icon" type: show as compact largeIcon (no circle crop)
                  largeIcon = ByteArrayAndroidBitmap(response.bodyBytes);
                  debugPrint('✅ Icon largeIcon ready for notification');
                }
              } else {
                // Rectangle BigPicture for expanded view (stories, memories, etc.)
                final tempDir = await getTemporaryDirectory();
                final file = io.File('${tempDir.path}/notification_$notificationId.jpg');
                await file.writeAsBytes(response.bodyBytes, flush: true);

                styleInformation = BigPictureStyleInformation(
                  FilePathAndroidBitmap(file.path),
                  contentTitle: title,
                  summaryText: body,
                  hideExpandedLargeIcon: true,
                );

                debugPrint('✅ Rich notification image ready: ${file.path}');
              }
            } else {
              debugPrint('⚠️ Failed to download image: HTTP ${response.statusCode}');
            }
          } catch (e) {
            debugPrint('⚠️ Image download failed, showing text-only: $e');
          }
        }
      }

      final details = NotificationDetails(
        android: Platform.isAndroid
            ? AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_stat_notification',
          styleInformation: styleInformation,
          largeIcon: largeIcon,
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
        normalizedTitle,
        normalizedBody,
        details,
        payload: payload,
      );

      debugPrint('✅ Notification displayed: $normalizedTitle');
    } catch (e, st) {
      debugPrint('❌ showNotification failed: $e');
      debugPrint('$st');
    }
  }

  void _pruneRecentNotificationSignatures(int nowMs) {
    if (_recentNotificationSignatures.isEmpty) return;
    final cutoffMs = nowMs - _dedupeWindow.inMilliseconds;
    _recentNotificationSignatures.removeWhere((_, ts) => ts < cutoffMs);
  }

  /// -------------------------------------------------------------------------
  /// FOREGROUND NOTIFICATION DISPLAY (FCM onMessage)
  /// -------------------------------------------------------------------------
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final n = message.notification;

    // On iOS, when the notification payload exists, the system ALREADY displayed it
    if (n != null && !kIsWeb && Platform.isIOS) {
      debugPrint(
          '📱 iOS: System handled notification display, skipping local notification');
      unawaited(_refreshIosBadgeCount());
      return;
    }

    // For Android or data-only messages, show local notification
    final title = n?.title ?? message.data['title'] ?? 'Capsule';
    final body = n?.body ?? message.data['body'] ?? '';

    if (body.isEmpty) return;

    // Extract image URL from various possible locations in the FCM payload
    String? imageUrl;

    // Try notification.android.imageUrl first (standard FCM image)
    imageUrl = n?.android?.imageUrl;

    // Fallback to data payload keys
    if (imageUrl == null || imageUrl.isEmpty) {
      imageUrl = message.data['image'] as String?;
    }
    if (imageUrl == null || imageUrl.isEmpty) {
      imageUrl = message.data['image_url'] as String?;
    }
    if (imageUrl == null || imageUrl.isEmpty) {
      imageUrl = message.data['fcm_options_image'] as String?;
    }

    // Extract image type from edge function
    final String? imageType = message.data['image_type'] as String?;

    debugPrint('📬 Foreground message: $title');
    debugPrint('🖼️ Image URL: $imageUrl, Type: $imageType');

    await showNotification(
      title: title,
      body: body,
      payload: _normalizeDeepLinkFromData(
        message.data,
        message.data['deep_link']?.toString(),
      ),
      id: message.hashCode,
      imageUrl: imageUrl,
      imageType: imageType,
    );

    unawaited(_refreshIosBadgeCount());
  }

  /// -------------------------------------------------------------------------
  /// TAP HANDLING
  /// -------------------------------------------------------------------------
  void _handleNotificationTap(RemoteMessage message) {
    final link = _normalizeDeepLinkFromData(
      message.data,
      message.data['deep_link']?.toString(),
    );
    if (link != null) _handleDeepLink(link);
    unawaited(_refreshIosBadgeCount());
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Local notification payloads are already "deep_link" strings, but still normalize
    // in case older payloads used legacy paths.
    final link = _normalizeDeepLinkFromData(
      const <String, dynamic>{},
      response.payload?.toString(),
    );
    if (link != null) _handleDeepLink(link);
    unawaited(_refreshIosBadgeCount());
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
      DeepLinkService().handleExternalDeepLink(pendingDeepLink!);
      pendingDeepLink = null;
    }
  }

  void _navigateToPath(String deepLink) {
    DeepLinkService().handleExternalDeepLink(deepLink);
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
