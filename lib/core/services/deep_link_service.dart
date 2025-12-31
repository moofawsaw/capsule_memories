import 'package:flutter/services.dart';

import '../../services/supabase_service.dart';
import '../app_export.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  static const platform = MethodChannel('capapp.co/deep_links');
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set up method channel to receive deep links from native code
      platform.setMethodCallHandler(_handleDeepLink);

      // Check for initial link (when app is opened from deep link)
      final initialLink = await _getInitialLink();
      if (initialLink != null) {
        await _processDeepLink(initialLink);
      }

      _isInitialized = true;
      debugPrint('✅ Deep link service initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize deep link service: $e');
    }
  }

  Future<String?> _getInitialLink() async {
    try {
      final String? link = await platform.invokeMethod('getInitialLink');
      return link;
    } catch (e) {
      debugPrint('Error getting initial link: $e');
      return null;
    }
  }

  Future<void> _handleDeepLink(MethodCall call) async {
    if (call.method == 'onDeepLink') {
      final String? link = call.arguments as String?;
      if (link != null) {
        await _processDeepLink(link);
      }
    }
  }

  Future<void> _processDeepLink(String link) async {
    try {
      final uri = Uri.parse(link);

      // Handle capsule.app/join/{type}/{code} URLs
      if (uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'join') {
        if (uri.pathSegments.length >= 3) {
          final type = uri.pathSegments[1];
          final code = uri.pathSegments[2];

          await _handleJoinLink(type, code);
        }
      }
    } catch (e) {
      debugPrint('Error processing deep link: $e');
    }
  }

  Future<void> _handleJoinLink(String type, String code) async {
    try {
      final client = SupabaseService.instance.client;
      if (client == null) {
        debugPrint('Supabase not initialized');
        return;
      }

      // Check if user is authenticated
      final user = client.auth.currentUser;
      if (user == null) {
        // Store pending action and redirect to login
        await _storePendingAction(type, code);
        NavigatorService.pushNamed(AppRoutes.authLogin);
        return;
      }

      // Process the join action
      final response = await client.functions.invoke(
        'handle-qr-scan',
        body: {
          'type': type,
          'code': code,
        },
      );

      if (response.status == 200) {
        // Navigate to appropriate confirmation screen
        _navigateToConfirmation(type);
      } else {
        _showError(response.data['error'] ?? 'Failed to process invitation');
      }
    } catch (e) {
      _showError('Error processing invitation: $e');
    }
  }

  Future<void> _storePendingAction(String type, String code) async {
    // Store pending action in shared preferences or secure storage
    // This will be processed after user logs in
    debugPrint('Storing pending action: $type - $code');
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
    // Show error toast or snackbar
    debugPrint('Deep link error: $message');
  }
}
