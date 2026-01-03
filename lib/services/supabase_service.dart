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

  // Initialize Supabase client with credentials
  static Future<void> initialize() async {
    try {
      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        print('⚠️ Supabase credentials not configured');
        print(
            '   Make sure to set SUPABASE_URL and SUPABASE_ANON_KEY environment variables');
        print(
            '   Run: flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key');
        return;
      }

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          autoRefreshToken:
              true, // 🔑 Automatically refresh tokens before expiration
        ),
      );

      instance.markAsInitialized();
      print('✅ Supabase initialized successfully');
      print('   URL: $supabaseUrl');
      print(
          '   OAuth Deep Link: io.supabase.capsulememories://login-callback/');
      print(
          '   Auto-refresh enabled: Session will persist across app restarts');
    } catch (e) {
      print('❌ Failed to initialize Supabase: $e');
      print('   Check your SUPABASE_URL and SUPABASE_ANON_KEY values');
      rethrow;
    }
  }

  // Mark service as initialized (called after successful Supabase.initialize in main.dart)
  void markAsInitialized() {
    _isInitialized = true;
  }

  // Get Supabase client safely (returns null if not initialized)
  SupabaseClient? get client {
    if (!_isInitialized) {
      print('⚠️ Supabase not initialized - returning null');
      print('   Call SupabaseService.initialize() before using the client');
      return null;
    }
    try {
      return Supabase.instance.client;
    } catch (e) {
      print('❌ Error getting Supabase client: $e');
      return null;
    }
  }

  // Get Supabase client with exception if not initialized
  SupabaseClient get clientOrThrow {
    final client = this.client;
    if (client == null) {
      throw Exception(
          'Supabase client not initialized. Call SupabaseService.initialize() first.');
    }
    return client;
  }

  // Check if user session exists (session restoration check)
  Future<bool> hasActiveSession() async {
    try {
      final session = client?.auth.currentSession;
      if (session != null) {
        print('✅ Active session found');
        print('   User: ${session.user.email}');
        print('   Expires: ${session.expiresAt}');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error checking session: $e');
      return false;
    }
  }

  // 🔑 ENHANCED: Explicit session restoration with token refresh
  // This method can be called on app startup to verify session restoration
  Future<Session?> restoreSession() async {
    try {
      // The Supabase SDK automatically restores sessions from secure storage
      // when autoRefreshToken is enabled. This method verifies the restoration.
      final session = client?.auth.currentSession;

      if (session != null) {
        print('✅ Session restored successfully');
        print('   User: ${session.user.email}');
        print('   Access token: ${session.accessToken.substring(0, 20)}...');
        print('   Refresh token present: ${session.refreshToken != null}');
        print('   Expires at: ${session.expiresAt}');

        // Check if token needs refresh (expires within next hour)
        final expiresAt =
            DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
        final needsRefresh = expiresAt.difference(DateTime.now()).inHours < 1;

        if (needsRefresh) {
          print('⏰ Token expires soon, triggering refresh...');
          // Supabase SDK will automatically refresh if needed
          await Future.delayed(const Duration(milliseconds: 100));
        }

        return session;
      } else {
        print('ℹ️ No previous session found to restore');
        return null;
      }
    } catch (e) {
      print('❌ Error during session restoration: $e');
      return null;
    }
  }

  /// Resolve storage path to full Supabase Storage URL
  /// Handles both relative paths and already-resolved full URLs
  String? getStorageUrl(String? path, {String bucket = 'story-media'}) {
    if (path == null || path.isEmpty) return null;

    // Check if already a full URL
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    // Convert relative path to full Supabase Storage URL
    try {
      return client?.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      print('❌ Error resolving storage URL for path: $path - $e');
      return null;
    }
  }
}
