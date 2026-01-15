// lib/core/services/deep_link_service.dart

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../services/supabase_service.dart';
import '../models/feed_story_context.dart';
import '../utils/navigator_service.dart';

class DeepLinkService with WidgetsBindingObserver {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  bool _isInitialized = false;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  // ===== Invite auth continuation =====
  String? _pendingSessionToken;

  // ===== Story deep link queueing =====
  FeedStoryContext? _pendingStoryArgs;
  bool _navScheduled = false;

  // Optional callbacks
  Function(String message, String type)? onSuccess;
  Function(String message)? onError;

  /// True if we have an invite link waiting for login completion
  bool get hasPendingAction => _pendingSessionToken != null;

  /// True if we have a story navigation queued (prevents splash from stomping nav)
  bool get hasPendingStoryNavigation => _pendingStoryArgs != null;

  Future<void> initialize() async {
    if (_isInitialized) return;

    WidgetsBinding.instance.addObserver(this);

    try {
      // Cold start link (terminated app)
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _handleDeepLink(initialUri);
      }

      // Warm start / running app links
      _sub = _appLinks.uriLinkStream.listen(
            (uri) async => _handleDeepLink(uri),
        onError: (e) => debugPrint('❌ Deep link stream error: $e'),
      );

      _isInitialized = true;
      debugPrint('✅ DeepLinkService initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize deep link service: $e');
    }
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _sub?.cancel();
    _sub = null;
    _isInitialized = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;

    // If we got a deep link while backgrounded, run it once we resume
    if (state == AppLifecycleState.resumed) {
      _flushPendingStoryNavigation();
    }
  }

  // ===========================
  // Deep link router
  // ===========================

  Future<void> _handleDeepLink(Uri uri) async {
    debugPrint('🔗 Deep link received: $uri');

    // ---------------------------
    // 1) STORY LINKS (PUBLIC VIEWER)
    // ---------------------------

    // ✅ Current web route:
    // https://capapp.co/story/{storyIdOrShareCode}
    if (_isCapappStoryHttpLink(uri)) {
      final storyId = _extractStoryIdFromCapapp(uri);
      if (storyId != null && storyId.isNotEmpty) {
        _openStory(storyId);
      }
      return;
    }

    // Optional legacy support (keep if old links exist):
    // https://capapp.co/s/{id}
    if (_isCapappLegacySLink(uri)) {
      final storyId = _extractStoryIdFromCapappLegacyS(uri);
      if (storyId != null && storyId.isNotEmpty) {
        _openStory(storyId);
      }
      return;
    }

    // Optional share domain support:
    // https://share.capapp.co/{shareCodeOrStoryId}
    if (_isShareCapappLink(uri)) {
      final storyId = _extractIdFromShareCapapp(uri);
      if (storyId != null && storyId.isNotEmpty) {
        _openStory(storyId);
      }
      return;
    }

    // Custom scheme (optional):
    // capsule://story/{id}
    if (_isCapsuleCustomSchemeStoryLink(uri)) {
      final storyId = _extractStoryIdFromCapsuleScheme(uri);
      if (storyId != null && storyId.isNotEmpty) {
        _openStory(storyId);
      }
      return;
    }

    // ---------------------------
    // 2) INVITE / JOIN LINKS (capapp.co)
    // ---------------------------
    // https://capapp.co/join/{type}/{code}
    if (uri.host != 'capapp.co') return;
    if (!uri.path.startsWith('/join')) return;

    final segments = uri.pathSegments;
    if (segments.length < 3) return;

    final type = segments[1];
    final code = segments[2];

    await _processInviteLink(type, code);
  }

  // ===========================
  // STORY helpers
  // ===========================

  bool _isCapappStoryHttpLink(Uri uri) {
    if (uri.scheme != 'https' && uri.scheme != 'http') return false;
    if (uri.host != 'capapp.co' && uri.host != 'www.capapp.co') return false;
    if (uri.pathSegments.isEmpty) return false;

    // ✅ new format: /story/{id}
    if (uri.pathSegments.first != 'story') return false;
    return uri.pathSegments.length >= 2;
  }

  String? _extractStoryIdFromCapapp(Uri uri) {
    if (uri.pathSegments.length < 2) return null;
    return uri.pathSegments[1];
  }

  bool _isCapappLegacySLink(Uri uri) {
    if (uri.scheme != 'https' && uri.scheme != 'http') return false;
    if (uri.host != 'capapp.co' && uri.host != 'www.capapp.co') return false;
    if (uri.pathSegments.isEmpty) return false;

    // legacy: /s/{id}
    return uri.pathSegments.first == 's' && uri.pathSegments.length >= 2;
  }

  String? _extractStoryIdFromCapappLegacyS(Uri uri) {
    if (uri.pathSegments.length < 2) return null;
    return uri.pathSegments[1];
  }

  bool _isShareCapappLink(Uri uri) {
    if (uri.scheme != 'https' && uri.scheme != 'http') return false;
    if (uri.host != 'share.capapp.co' && uri.host != 'www.share.capapp.co') {
      return false;
    }
    return uri.pathSegments.isNotEmpty;
  }

  String? _extractIdFromShareCapapp(Uri uri) {
    // https://share.capapp.co/{id}
    if (uri.pathSegments.isEmpty) return null;
    return uri.pathSegments.first;
  }

  bool _isCapsuleCustomSchemeStoryLink(Uri uri) {
    return uri.scheme == 'capsule' && uri.host == 'story';
  }

  String? _extractStoryIdFromCapsuleScheme(Uri uri) {
    if (uri.pathSegments.isEmpty) return null;
    return uri.pathSegments.first;
  }

  void _openStory(String storyIdOrShareCode) {
    debugPrint('✅ Queue story open: $storyIdOrShareCode');

    final args = FeedStoryContext(
      feedType: 'deep_link',
      initialStoryId: storyIdOrShareCode,
      storyIds: [storyIdOrShareCode],
    );

    _pendingStoryArgs = args;
    _flushPendingStoryNavigation();
  }

  void _flushPendingStoryNavigation() {
    final args = _pendingStoryArgs;
    if (args == null) return;

    // If app is not resumed yet, wait.
    if (_lifecycleState != AppLifecycleState.resumed) {
      debugPrint('⏳ Not resumed yet. Waiting to navigate...');
      return;
    }

    if (_navScheduled) return;
    _navScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navScheduled = false;

      final stillArgs = _pendingStoryArgs;
      _pendingStoryArgs = null;
      if (stillArgs == null) return;

      final navState = NavigatorService.navigatorKey.currentState;
      if (navState == null) {
        debugPrint('❌ Navigator not ready (state null). Re-queue story.');
        _pendingStoryArgs = stillArgs;
        return;
      }

      try {
        // ✅ CRITICAL: Use PUBLIC route (no AppShell / no AuthGuard)
        navState.pushNamedAndRemoveUntil(
          AppRoutes.storyViewPublic,
              (route) => false,
          arguments: stillArgs,
        );

        debugPrint(
          '✅ Navigated to public story view: ${stillArgs.initialStoryId}',
        );
      } catch (e) {
        debugPrint('❌ Story navigation error: $e');
        // Re-queue once if timing issue
        _pendingStoryArgs = stillArgs;
      }
    });
  }

  // ===========================
  // INVITES
  // ===========================

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
        debugPrint('✅ Invite deep link requires auth. Token stored.');
        return;
      }

      if (data['success'] == true) {
        final message =
            data['message'] as String? ?? 'Action completed successfully';
        debugPrint('✅ Invite deep link completed: $message');

        onSuccess?.call(message, type);
        _navigateToConfirmation(type);
        return;
      }

      final err = data['error'] as String? ?? 'Failed to process invitation';
      onError?.call(err);
      debugPrint('❌ Invite deep link failed: $err');
    } catch (e) {
      debugPrint('❌ Invite deep link error: $e');
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
}
