import './supabase_service.dart';
import './push_notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Service class for managing notifications with real-time capabilities
class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final dynamic _client = SupabaseService.instance.client;
  dynamic _notificationChannel;

  /// Subscribe to real-time notification updates for the current user
  Future<void> subscribeToNotifications({
    required Function(Map<String, dynamic>) onNewNotification,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      _notificationChannel = _client
          .channel('notifications:$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            callback: (payload) async {
              final notification = payload.newRecord;
              onNewNotification(notification);

              // Show local notification when app is in foreground
              if (PushNotificationService.instance.isInitialized) {
                await PushNotificationService.instance.showNotification(
                  title: notification['title'] ?? 'New Notification',
                  body: notification['message'] ?? '',
                  payload: notification['id'],
                );
              }
            },
          )
          .subscribe();
    } catch (error) {
      throw Exception('Failed to subscribe to notifications: $error');
    }
  }

  /// Unsubscribe from notification updates
  Future<void> unsubscribeFromNotifications() async {
    if (_notificationChannel != null) {
      await _client.removeChannel(_notificationChannel!);
      _notificationChannel = null;
    }
  }

  /// Get all notifications for the current user
  Future<List<Map<String, dynamic>>> getNotifications({
    bool? isRead,
    int limit = 50,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ No authenticated user found');
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 Fetching notifications for user: $userId');

      var query = _client.from('notifications').select().eq('user_id', userId);

      if (isRead != null) {
        query = query.eq('is_read', isRead);
      }

      final response =
          await query.order('created_at', ascending: false).limit(limit);

      debugPrint('✅ Fetched ${response.length} notifications from database');

      if (response.isEmpty) {
        debugPrint('⚠️ No notifications found for user $userId');
      } else {
        debugPrint('📋 First notification: ${response.first}');
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('❌ Error fetching notifications: $error');
      throw Exception('Failed to fetch notifications: $error');
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false)
          .count();

      return response.count ?? 0;
    } catch (error) {
      throw Exception('Failed to get unread count: $error');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _client
          .from('notifications')
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
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _client
          .from('notifications')
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
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _client
          .from('notifications')
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
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _client
          .from('notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', userId);
    } catch (error) {
      throw Exception('Failed to delete notification: $error');
    }
  }

  /// Get notification by ID
  Future<Map<String, dynamic>?> getNotificationById(
      String notificationId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client
          .from('notifications')
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

  /// Get notifications by type
  Future<List<Map<String, dynamic>>> getNotificationsByType(
    String notificationType, {
    int limit = 20,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('type', notificationType)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch notifications by type: $error');
    }
  }
}
