import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../services/supabase_service.dart';
import '../app_export.dart';
import '../models/feed_story_context.dart';

class DeepLinkService with WidgetsBindingObserver {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();

  StreamSubscription<Uri>? _sub;

  String? _pendingSessionToken;
  bool _isInitialized = false;

  // ===== Story deep link queueing =====
  FeedStoryContext? _pendingStoryArgs;
  bool _navScheduled = false;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  // Callback for success messages
  Function(String message, String type)? onSuccess;

  // Callback for error messages
  Function(String message)? onError;

  bool get hasPendingAction => _pendingSessionToken != null;

  Future<void> initialize() async {
    if (_isInitialized) return;

    WidgetsBinding.instance.addObserver(this);

    try {
      // Cold start link
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _handleDeepLink(initialUri);
      }

      // Warm start / running app links
      _sub = _appLinks.uriLinkStream.listen(
            (uri) async {
          await _handleDeepLink(uri);
        },
        onError: (e) {
          debugPrint('❌ Deep link stream error: $e');
        },
      );

      _isInitialized = true;
      debugPrint('✅ Deep link service initialized (app_links)');
    } catch (e) {
      debugPrint('❌ Failed to initialize deep link service: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;

    // If we got a deep link while backgrounded, run it once we resume
    if (state == AppLifecycleState.resumed) {
      _flushPendingStoryNavigation();
    }
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _sub?.cancel();
    _sub = null;
    _isInitialized = false;
  }

  Future<void> _handleDeepLink(Uri uri) async {
    debugPrint('🔗 Deep link received: $uri');

    // ===========================
    // 1) STORY LINKS (capsulememories)
    // ===========================
    // https://capsulememories.app/s/{storyId}
    // https://capsulememories.app/story/{storyId}
    if (_isCapsuleMemoriesStoryHttpLink(uri)) {
      final storyId = _extractStoryIdFromCapsuleMemoriesHttp(uri);
      if (storyId != null && storyId.isNotEmpty) {
        _openStory(storyId);
      }
      return;
    }

    // capsule://story/{storyId}
    if (_isCapsuleCustomSchemeStoryLink(uri)) {
      final storyId = _extractStoryIdFromCapsuleScheme(uri);
      if (storyId != null && storyId.isNotEmpty) {
        _openStory(storyId);
      }
      return;
    }

    // ===========================
    // 1.5) STORY LINKS (capapp.co)
    // ===========================
    // https://capapp.co/s/{storyId}
    if (_isCapappStoryHttpLink(uri)) {
      final storyId = _extractStoryIdFromCapapp(uri);
      if (storyId != null && storyId.isNotEmpty) {
        _openStory(storyId);
      }
      return;
    }

    // ===========================
    // 2) INVITE / JOIN LINKS (capapp.co)
    // ===========================
    if (uri.host != 'capapp.co') return;
    if (!uri.path.startsWith('/join')) return;

    final segments = uri.pathSegments;
    if (segments.length < 3) return;

    final type = segments[1];
    final code = segments[2];

    await _processInviteLink(type, code);
  }

  // ---------------------------
  // STORY: Helpers
  // ---------------------------

  bool _isCapsuleMemoriesStoryHttpLink(Uri uri) {
    if (uri.scheme != 'https' && uri.scheme != 'http') return false;

    final hostOk = uri.host == 'capsulememories.app' ||
        uri.host == 'www.capsulememories.app';
    if (!hostOk) return false;

    if (uri.pathSegments.isEmpty) return false;

    final first = uri.pathSegments.first;
    if (first != 's' && first != 'story') return false;

    return uri.pathSegments.length >= 2;
  }

  String? _extractStoryIdFromCapsuleMemoriesHttp(Uri uri) {
    if (uri.pathSegments.length < 2) return null;
    return uri.pathSegments[1];
  }

  bool _isCapsuleCustomSchemeStoryLink(Uri uri) {
    return uri.scheme == 'capsule' && uri.host == 'story';
  }

  String? _extractStoryIdFromCapsuleScheme(Uri uri) {
    if (uri.pathSegments.isEmpty) return null;
    return uri.pathSegments.first;
  }

  bool _isCapappStoryHttpLink(Uri uri) {
    if (uri.scheme != 'https' && uri.scheme != 'http') return false;
    if (uri.host != 'capapp.co') return false;
    if (uri.pathSegments.isEmpty) return false;
    return uri.pathSegments.first == 's' && uri.pathSegments.length >= 2;
  }

  String? _extractStoryIdFromCapapp(Uri uri) {
    if (uri.pathSegments.length < 2) return null;
    return uri.pathSegments[1];
  }

  void _openStory(String storyId) {
    debugPrint('✅ Opening story from deep link: $storyId');

    final args = FeedStoryContext(
      feedType: 'deep_link',
      initialStoryId: storyId,
      storyIds: [storyId],
    );

    // Queue it and flush when safe (resumed + next frame)
    _pendingStoryArgs = args;
    _flushPendingStoryNavigation();
  }

  void _flushPendingStoryNavigation() {
    if (_pendingStoryArgs == null) return;

    // If app is not resumed yet, wait.
    if (_lifecycleState != AppLifecycleState.resumed) {
      debugPrint('⏳ App not resumed yet. Waiting to navigate to story...');
      return;
    }

    if (_navScheduled) return;
    _navScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navScheduled = false;

      final args = _pendingStoryArgs;
      _pendingStoryArgs = null;
      if (args == null) return;

      final navState = NavigatorService.navigatorKey.currentState;
      final navContext = NavigatorService.navigatorKey.currentContext;

      if (navState == null || navContext == null) {
        debugPrint('❌ Navigator not ready (state/context null). Re-queue story.');
        _pendingStoryArgs = args;
        return;
      }

      // Hard reset the stack to avoid half-dead StoryViewer state (black screen)
      // You can loosen this later, but this is the most reliable fix.
      try {
        navState.pushNamedAndRemoveUntil(
          AppRoutes.appStoryView,
              (route) => route.isFirst,
          arguments: args,
        );
        debugPrint('✅ Navigated to story (hard reset): ${args.initialStoryId}');
      } catch (e) {
        debugPrint('❌ Story navigation error: $e');
        // If navigation fails for timing, re-queue once.
        _pendingStoryArgs = args;
      }
    });
  }

  // ---------------------------
  // INVITES: Main flow
  // ---------------------------

  Future<void> _processInviteLink(String type, String code) async {
    final client = SupabaseService.instance.client;
    if (client == null) {
      debugPrint('❌ Supabase not initialized');
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

      final data = (response.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};

      if (data['requires_auth'] == true) {
        _pendingSessionToken = data['session_token'] as String?;
        NavigatorService.pushNamed(AppRoutes.authLogin);
        debugPrint('✅ Deep link requires auth. Session token stored.');
        return;
      }

      if (data['success'] == true) {
        final message =
            data['message'] as String? ?? 'Action completed successfully';
        debugPrint('✅ Deep link invite completed: $message');

        onSuccess?.call(message, type);
        _navigateToConfirmation(type);
        return;
      }

      final err = data['error'] as String? ?? 'Failed to process invitation';
      onError?.call(err);
      debugPrint('❌ Deep link invite failed: $err');
    } catch (e) {
      debugPrint('❌ Deep link error: $e');
      onError?.call('Failed to process invitation');
    }
  }

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

      _pendingSessionToken = null;

      final data = (response.data as Map?)?.cast<String, dynamic>();
      return data;
    } catch (e) {
      debugPrint('❌ Complete pending action error: $e');
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
        break;
    }
  }

  void _showError(String message) {
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
