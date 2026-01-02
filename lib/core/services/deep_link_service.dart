import 'package:app_links/app_links.dart';

import '../../services/supabase_service.dart';
import '../app_export.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  String? _pendingSessionToken;
  bool _isInitialized = false;

  // Callback for success messages
  Function(String message, String type)? onSuccess;

  // Callback for error messages
  Function(String message)? onError;

  bool get hasPendingAction => _pendingSessionToken != null;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Handle link that opened the app
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _handleDeepLink(initialUri);
      }

      // Handle links while app is running
      _appLinks.uriLinkStream.listen(_handleDeepLink);

      _isInitialized = true;
      debugPrint('✅ Deep link service initialized with app_links');
    } catch (e) {
      debugPrint('❌ Failed to initialize deep link service: $e');
    }
  }

  Future<void> _handleDeepLink(Uri uri) async {
    // Only handle capapp.co/join links
    if (uri.host != 'capapp.co' || !uri.path.startsWith('/join')) return;

    final segments = uri.pathSegments;
    if (segments.length < 3) return; // Need: join/{type}/{code}

    final type = segments[1]; // friend, group, or memory
    final code = segments[2];

    await _processLink(type, code);
  }

  Future<void> _processLink(String type, String code) async {
    final client = SupabaseService.instance.client;
    if (client == null) {
      debugPrint('Supabase not initialized');
      return;
    }

    final session = client.auth.currentSession;

    try {
      final response = await client.functions.invoke(
        'handle-qr-scan',
        body: {'type': type, 'code': code},
        headers: session != null
            ? {'Authorization': 'Bearer ${session.accessToken}'}
            : null,
      );

      final data = response.data as Map<String, dynamic>;

      if (data['requires_auth'] == true) {
        // User not logged in - store token for later
        _pendingSessionToken = data['session_token'];
        // Navigate to login screen
        NavigatorService.pushNamed(AppRoutes.authLogin);
        debugPrint('Deep link requires auth. Session token stored.');
      } else if (data['success'] == true) {
        // Action completed!
        final message =
            data['message'] as String? ?? 'Action completed successfully';
        debugPrint('Deep link action completed: $message');

        // Call success callback if set
        onSuccess?.call(message, type);

        _navigateToConfirmation(type);
      }
    } catch (e) {
      debugPrint('Deep link error: $e');

      // Call error callback if set
      onError?.call('Failed to process invitation');
    }
  }

  /// Call this after user logs in/signs up
  Future<Map<String, dynamic>?> completePendingAction() async {
    if (_pendingSessionToken == null) return null;

    final client = SupabaseService.instance.client;
    if (client == null) return null;

    final session = client.auth.currentSession;
    if (session == null) return null;

    try {
      final response = await client.functions.invoke(
        'complete-pending-action',
        body: {'session_token': _pendingSessionToken},
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );

      _pendingSessionToken = null; // Clear after use

      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Complete pending action error: $e');
      _pendingSessionToken = null;
      return null;
    }
  }

  void _navigateToConfirmation(String type) {
    switch (type) {
      case 'friend':
        NavigatorService.pushNamed(AppRoutes.appFriends);
        break;
      case 'group':
        NavigatorService.pushNamed(AppRoutes.appGroups);
        break;
      case 'memory':
        NavigatorService.pushNamed(AppRoutes.appMemories);
        break;
      default:
        NavigatorService.pushNamed(AppRoutes.appFeed);
    }
  }

  void _showError(String message) {
    // Show error via global messenger key
    final context = NavigatorService.navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
    debugPrint('Deep link error: $message');
  }
}
