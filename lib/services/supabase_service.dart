import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Mark service as initialized (called after successful Supabase.initialize in main.dart)
  void markAsInitialized() {
    _isInitialized = true;
  }

  // Get Supabase client (returns null if not initialized)
  SupabaseClient? get client {
    if (!_isInitialized) {
      print('⚠️ Supabase not initialized - returning null');
      return null;
    }
    try {
      return Supabase.instance.client;
    } catch (e) {
      print('❌ Error getting Supabase client: $e');
      return null;
    }
  }

  // Check if user session exists (session restoration check)
  Future<bool> hasActiveSession() async {
    try {
      final session = client?.auth.currentSession;
      return session != null;
    } catch (e) {
      print('❌ Error checking session: $e');
      return false;
    }
  }

  // Restore session on app startup (called automatically by Supabase)
  Future<void> restoreSession() async {
    try {
      // Session restoration is handled automatically by Supabase SDK
      // This method can be used to verify restoration
      final session = client?.auth.currentSession;
      if (session != null) {
        print(
            '✅ Session restored successfully for user: ${session.user.email}');
      } else {
        print('ℹ️ No previous session found');
      }
    } catch (e) {
      print('❌ Error during session restoration: $e');
    }
  }
}
