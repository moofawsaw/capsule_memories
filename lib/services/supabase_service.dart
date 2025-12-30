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
          autoRefreshToken: true,
        ),
      );

      instance.markAsInitialized();
      print('✅ Supabase initialized successfully');
      print('   URL: $supabaseUrl');
      print(
          '   OAuth Deep Link: io.supabase.capsulememories://login-callback/');
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
