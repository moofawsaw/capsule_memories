// lib/services/supabase_service.dart
import 'package:meta/meta.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_tus_uploader.dart';
import 'video_pipeline_warmup.dart';


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

  // ✅ One shared uploader instance for the whole app lifecycle.
  // This is critical for:
  // - keeping the same http.Client (keep-alive socket reuse)
  // - keeping the in-memory URL store cache
  SupabaseTusUploader? _sharedTusUploader;

  /// Shared uploader (throws if Supabase isn't initialized)
  SupabaseTusUploader get sharedTusUploader {
    final c = clientOrThrow;
    return _sharedTusUploader ??= SupabaseTusUploader(c);
  }

  // Initialize Supabase client with credentials
  static Future<void> initialize() async {
    try {
      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        // ignore: avoid_print
        print('⚠️ Supabase credentials not configured');
        // ignore: avoid_print
        print('   Run: flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...');
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

      // ignore: avoid_print
      print('✅ Supabase initialized successfully');
      // ignore: avoid_print
      print('   URL: $supabaseUrl');
      // ignore: avoid_print
      print('   OAuth Deep Link: io.supabase.capsulememories://login-callback/');
      // ignore: avoid_print
      print('   Auto-refresh enabled: Session will persist across app restarts');
    } catch (e) {
      // ignore: avoid_print
      print('❌ Failed to initialize Supabase: $e');
      // ignore: avoid_print
      print('   Check your SUPABASE_URL and SUPABASE_ANON_KEY values');
      rethrow;
    }
  }

  // Mark service as initialized (called after successful Supabase.initialize)
  void markAsInitialized() {
    _isInitialized = true;
  }

  // Get Supabase client safely (returns null if not initialized)
  SupabaseClient? get client {
    if (!_isInitialized) {
      // ignore: avoid_print
      print('⚠️ Supabase not initialized - returning null');
      // ignore: avoid_print
      print('   Call SupabaseService.initialize() before using the client');
      return null;
    }
    try {
      return Supabase.instance.client;
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error getting Supabase client: $e');
      return null;
    }
  }

  // Get Supabase client with exception if not initialized
  SupabaseClient get clientOrThrow {
    final c = client;
    if (c == null) {
      throw Exception(
        'Supabase client not initialized. Call SupabaseService.initialize() first.',
      );
    }
    return c;
  }

  // ✅ Best-effort warmup to reduce “first upload after launch” delay.
  // Call this at:
  // - app start (after initialize), OR
  // - when opening camera/story flow
  Future<void> warmUploadPipeline() async {
    try {
      final c = client;
      if (c == null) return;

      c.auth.currentUser?.id;

      // ✅ Warm video plugins too
      VideoPipelineWarmup.warm();

      await sharedTusUploader.prewarm();
    } catch (_) {}
  }

  // Check if user session exists (session restoration check)
  Future<bool> hasActiveSession() async {
    try {
      final session = client?.auth.currentSession;
      if (session != null) {
        // ignore: avoid_print
        print('✅ Active session found');
        // ignore: avoid_print
        print('   User: ${session.user.email}');
        // ignore: avoid_print
        print('   Expires: ${session.expiresAt}');
        return true;
      }
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error checking session: $e');
      return false;
    }
  }

  // Explicit session restoration verification
  Future<Session?> restoreSession() async {
    try {
      final session = client?.auth.currentSession;

      if (session != null) {
        // ignore: avoid_print
        print('✅ Session restored successfully');
        // ignore: avoid_print
        print('   User: ${session.user.email}');
        // ignore: avoid_print
        print('   Access token: ${session.accessToken.substring(0, 20)}...');
        // ignore: avoid_print
        print('   Refresh token present: ${session.refreshToken != null}');
        // ignore: avoid_print
        print('   Expires at: ${session.expiresAt}');

        final expiresAt =
        DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
        final needsRefresh = expiresAt.difference(DateTime.now()).inHours < 1;

        if (needsRefresh) {
          // ignore: avoid_print
          print('⏰ Token expires soon, triggering refresh...');
          await Future.delayed(const Duration(milliseconds: 100));
        }

        return session;
      } else {
        // ignore: avoid_print
        print('ℹ️ No previous session found to restore');
        return null;
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error during session restoration: $e');
      return null;
    }
  }

  /// Resolve storage path to full Supabase Storage URL
  /// Handles both relative paths and already-resolved full URLs
  String? getStorageUrl(String? path, {String bucket = 'story-media'}) {
    if (path == null || path.isEmpty) return null;

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    try {
      return client?.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error resolving storage URL for path: $path - $e');
      return null;
    }
  }

  /// Optional: call if you want to close the shared http client
  void dispose() {
    try {
      _sharedTusUploader?.dispose();
    } catch (_) {}
    _sharedTusUploader = null;
  }
}