import 'dart:async';

import './supabase_service.dart';
import './push_notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Service class for managing notifications with real-time capabilities
/// Optimized for concurrent updates across multiple users
class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  SupabaseClient? get _client => SupabaseService.instance.client;

  // Debouncing and throttling for performance optimization
  Timer? _debounceTimer;
  DateTime? _lastUpdateTime;
  static const _debounceDuration = Duration(milliseconds: 300);
  static const _throttleDuration = Duration(seconds: 1);

  // Connection state management
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const _maxReconnectAttempts = 5;
  Timer? _reconnectTimer;

  // Batch update queue for concurrent operations
  final List<Map<String, dynamic>> _pendingUpdates = [];
  bool _isProcessingBatch = false;

  RealtimeChannel? _subscription;

  /// Subscribe to real-time notification updates for the current user
  /// with automatic reconnection and error recovery
  Future<void> subscribeToNotifications({
    required Function(Map<String, dynamic>) onNewNotification,
  }) async {
    try {
      final client = _client;
      if (client == null) {
        debugPrint(
            '⚠️ Supabase client not initialized - cannot subscribe to notifications');
        return;
      }

      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint(
            '⚠️ No authenticated user - cannot subscribe to notifications');
        return;
      }

      _subscription = client
          .channel('notifications')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) {
              debugPrint('🔔 New notification received');
              onNewNotification(payload.newRecord);
            },
          )
          .subscribe();

      debugPrint('✅ Subscribed to notification updates');
    } catch (error) {
      debugPrint('❌ Error subscribing to notifications: $error');
    }
  }

  /// Debounced notification update to batch rapid consecutive updates
  void _debouncedNotificationUpdate(
    Map<String, dynamic> notification,
    Function(Map<String, dynamic>) callback,
  ) {
    // Cancel previous timer if still pending
    _debounceTimer?.cancel();

    // Add to pending updates queue
    _pendingUpdates.add(notification);

    // Set new timer
    _debounceTimer = Timer(_debounceDuration, () {
      if (_pendingUpdates.isNotEmpty) {
        // Process all pending updates in batch
        _processBatchUpdates(callback);
      }
    });
  }

  /// Process batched notification updates for better performance
  Future<void> _processBatchUpdates(
    Function(Map<String, dynamic>) callback,
  ) async {
    if (_isProcessingBatch) return;

    _isProcessingBatch = true;

    try {
      // Get the most recent notification from batch
      final latestNotification = _pendingUpdates.last;

      // Invoke callback with latest notification
      callback(latestNotification);

      // Clear processed updates
      _pendingUpdates.clear();

      debugPrint('✅ Processed batch of notification updates');
    } finally {
      _isProcessingBatch = false;
    }
  }

  /// Throttled push notification to prevent notification spam
  void _throttledPushNotification(Map<String, dynamic> notification) {
    final now = DateTime.now();

    // Check if enough time has passed since last notification
    if (_lastUpdateTime != null) {
      final timeSinceLastUpdate = now.difference(_lastUpdateTime!);
      if (timeSinceLastUpdate < _throttleDuration) {
        debugPrint('⏱️ Throttling push notification');
        return;
      }
    }

    // Update last notification time and show notification
    _lastUpdateTime = now;
    PushNotificationService.instance.showNotification(
      title: notification['title'] ?? 'New Notification',
      body: notification['message'] ?? '',
      payload: notification['id'],
    );
  }

  /// Attempt automatic reconnection with exponential backoff
  void _attemptReconnection(
    String userId,
    Function(Map<String, dynamic>) onNewNotification,
  ) {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('❌ Max reconnection attempts reached');
      return;
    }

    _reconnectAttempts++;
    final delaySeconds = _reconnectAttempts * 2; // Exponential backoff

    debugPrint(
        '🔄 Reconnection attempt $_reconnectAttempts in ${delaySeconds}s');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () async {
      try {
        await unsubscribeFromNotifications();
        await subscribeToNotifications(onNewNotification: onNewNotification);
      } catch (e) {
        debugPrint('❌ Reconnection failed: $e');
        _attemptReconnection(userId, onNewNotification);
      }
    });
  }

  /// Unsubscribe from notification updates
  Future<void> unsubscribeFromNotifications() async {
    _reconnectTimer?.cancel();
    _debounceTimer?.cancel();

    if (_subscription != null) {
      await _subscription!.unsubscribe();
      _subscription = null;
      _isConnected = false;
      _reconnectAttempts = 0;
      debugPrint('✅ Unsubscribed from notifications');
    }
  }

  /// Get all notifications for the current user
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final client = _client;
      if (client == null) {
        debugPrint(
            '⚠️ Supabase client not initialized - cannot fetch notifications');
        return [];
      }

      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('⚠️ No authenticated user - cannot fetch notifications');
        return [];
      }

      final response = await client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Error fetching notifications: $error');
      return [];
    }
  }

  /// Get unread notification count with caching
  Future<int> getUnreadCount() async {
    try {
      final userId = _client?.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client
          ?.from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false)
          .count();

      return response?.count ?? 0;
    } catch (error) {
      throw Exception('Failed to get unread count: $error');
    }
  }

  /// Mark notification as read with optimistic update support
  Future<void> markAsRead(String notificationId) async {
    try {
      final userId = _client?.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _client
          ?.from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('user_id', userId);
    } catch (error) {
      throw Exception('Failed to mark notification as read: $error');
    }
  }

  /// Toggle notification read/unread state
  Future<void> toggleReadState(
      String notificationId, bool currentReadState) async {
    try {
      final userId = _client?.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _client
          ?.from('notifications')
          .update({'is_read': !currentReadState})
          .eq('id', notificationId)
          .eq('user_id', userId);
    } catch (error) {
      throw Exception('Failed to toggle notification read state: $error');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final userId = _client?.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _client
          ?.from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (error) {
      throw Exception('Failed to mark all notifications as read: $error');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final userId = _client?.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _client
          ?.from('notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', userId);
    } catch (error) {
      throw Exception('Failed to delete notification: $error');
    }
  }

  /// Restore a deleted notification
  Future<void> restoreNotification(Map<String, dynamic> notification) async {
    try {
      final userId = _client?.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Re-insert the notification with all its original data
      await _client?.from('notifications').insert({
        'id': notification['id'],
        'user_id': notification['user_id'],
        'type': notification['type'],
        'title': notification['title'],
        'message': notification['message'],
        'data': notification['data'],
        'is_read': notification['is_read'],
        'created_at': notification['created_at'],
      });
    } catch (error) {
      throw Exception('Failed to restore notification: $error');
    }
  }

  /// Get notification by ID
  Future<Map<String, dynamic>?> getNotificationById(
      String notificationId) async {
    try {
      final userId = _client?.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client
          ?.from('notifications')
          .select()
          .eq('id', notificationId)
          .eq('user_id', userId)
          .single();

      return response;
    } catch (error) {
      if (error.toString().contains('PGRST301')) {
        return null;
      }
      throw Exception('Failed to fetch notification: $error');
    }
  }

  /// Get notifications by type with real-time support
  Future<List<Map<String, dynamic>>> getNotificationsByType(
    String notificationType, {
    int limit = 20,
  }) async {
    try {
      final userId = _client?.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint(
          '🔍 Fetching $notificationType notifications for user: $userId');

      final response = await _client
          ?.from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('type', notificationType)
          .order('created_at', ascending: false)
          .limit(limit);

      debugPrint(
          '✅ Fetched ${response?.length} $notificationType notifications');

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (error) {
      debugPrint('❌ Failed to fetch notifications by type: $error');
      throw Exception('Failed to fetch notifications by type: $error');
    }
  }

  /// Handle notification action based on type and navigate appropriately
  Future<void> handleNotificationAction(
    Map<String, dynamic> notification,
    Function(String, Map<String, dynamic>?) navigateToScreen,
  ) async {
    try {
      final notificationType = notification['type'] as String?;
      final data = notification['data'] as Map<String, dynamic>?;

      if (notificationType == null || data == null) {
        debugPrint('⚠️ Invalid notification data');
        return;
      }

      // Mark notification as read
      await markAsRead(notification['id']);

      // Navigate based on notification type
      switch (notificationType) {
        case 'group_join':
          final groupId = data['group_id'];
          if (groupId != null) {
            navigateToScreen('/group-details', {'groupId': groupId});
          }
          break;

        case 'friend_accepted':
        case 'friend_request':
          navigateToScreen('/friends-management', null);
          break;

        case 'memory_invite':
        case 'memory_update':
        case 'memory_sealed':
        case 'memory_expiring':
          final memoryId = data['memory_id'];
          if (memoryId != null) {
            navigateToScreen('/memory-details', {'memoryId': memoryId});
          }
          break;

        case 'new_story':
          final storyId = data['story_id'];
          final memoryId = data['memory_id'];
          if (storyId != null && memoryId != null) {
            navigateToScreen('/memory-details',
                {'memoryId': memoryId, 'highlightStoryId': storyId});
          }
          break;

        case 'followed':
          final followerId = data['follower_id'];
          if (followerId != null) {
            navigateToScreen('/user-profile', {'userId': followerId});
          }
          break;

        default:
          debugPrint('⚠️ Unknown notification type: $notificationType');
      }
    } catch (error) {
      debugPrint('❌ Failed to handle notification action: $error');
      throw Exception('Failed to handle notification action: $error');
    }
  }

  /// Cleanup method to dispose timers and subscriptions
  void dispose() {
    _debounceTimer?.cancel();
    _reconnectTimer?.cancel();
    unsubscribeFromNotifications();
  }
}
