// lib/core/services/deep_link_service.dart

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../services/supabase_service.dart';
import '../models/feed_story_context.dart';
import '../utils/memory_nav_args.dart'; // ✅ REQUIRED
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

  // ===== Generic navigation queueing =====
  String? _pendingRoute;
  Object? _pendingRouteArgs;
  bool _genericNavScheduled = false;

  // Optional callbacks
  Function(String message, String type)? onSuccess;
  Function(String message)? onError;

  bool get hasPendingAction => _pendingSessionToken != null;
  bool get hasPendingStoryNavigation => _pendingStoryArgs != null;
  bool get hasPendingNavigation => _pendingRoute != null;

  // ===========================
  // INIT / LIFECYCLE
  // ===========================

  Future<void> initialize() async {
    if (_isInitialized) return;

    WidgetsBinding.instance.addObserver(this);

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _handleDeepLink(initialUri);
      }

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

    if (state == AppLifecycleState.resumed) {
      _flushPendingStoryNavigation();
      _flushPendingNavigation();
    }
  }

  // ===========================
  // DEEP LINK ROUTER
  // ===========================

  Future<void> _handleDeepLink(Uri uri) async {
    debugPrint('🔗 Deep link received: $uri');

    if (uri.scheme != 'https' &&
        uri.scheme != 'http' &&
        uri.scheme != 'capsule') {
      return;
    }

    // ---------- STORY (PUBLIC) ----------
    if (_isCapappStoryHttpLink(uri)) {
      final storyId = uri.pathSegments[1];
      if (storyId.isNotEmpty) _openStory(storyId);
      return;
    }

    if (_isCapappLegacySLink(uri)) {
      final storyId = uri.pathSegments[1];
      if (storyId.isNotEmpty) _openStory(storyId);
      return;
    }

    if (_isShareCapappLink(uri)) {
      final storyId = uri.pathSegments.first;
      if (storyId.isNotEmpty) _openStory(storyId);
      return;
    }

    if (_isCapsuleCustomSchemeStoryLink(uri)) {
      final storyId = uri.pathSegments.first;
      if (storyId.isNotEmpty) _openStory(storyId);
      return;
    }

    // ---------- MEMORY ----------
    if (_isCapappMemoryLink(uri)) {
      final memoryId = uri.pathSegments[1];
      debugPrint('📦 Memory deep link: $memoryId');

      _queueNavigation(
        AppRoutes.appTimeline,
        MemoryNavArgs(memoryId: memoryId).toMap(), // ✅ FIXED
      );
      return;
    }

    // ---------- PROFILE ----------
    if (_isCapappProfileLink(uri)) {
      _queueNavigation(
        AppRoutes.appProfileUser,
        {'userId': uri.pathSegments[1]},
      );
      return;
    }

    // ---------- FRIENDS ----------
    if (_isCapappFriendsLink(uri)) {
      _queueNavigation(AppRoutes.appFriends, null);
      return;
    }

    // ---------- GROUP ----------
    if (_isCapappGroupLink(uri)) {
      _queueNavigation(
        AppRoutes.appGroups,
        {'groupId': uri.pathSegments[1]},
      );
      return;
    }

    // ---------- NOTIFICATIONS ----------
    if (_isCapappNotificationsLink(uri)) {
      _queueNavigation(AppRoutes.appNotifications, null);
      return;
    }

    // ---------- INVITES ----------
    if (!_isCapappHost(uri) || !uri.path.startsWith('/join')) return;

    final segments = uri.pathSegments;
    if (segments.length < 3) return;

    await _processInviteLink(segments[1], segments[2]);
  }

  // ===========================
  // STORY NAV
  // ===========================

  void _openStory(String storyId) {
    _pendingStoryArgs = FeedStoryContext(
      feedType: 'deep_link',
      initialStoryId: storyId,
      storyIds: [storyId],
    );
    _flushPendingStoryNavigation();
  }

  void _flushPendingStoryNavigation() {
    if (_pendingStoryArgs == null) return;
    if (_lifecycleState != AppLifecycleState.resumed) return;
    if (_navScheduled) return;

    _navScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navScheduled = false;

      final args = _pendingStoryArgs;
      _pendingStoryArgs = null;
      if (args == null) return;

      final nav = NavigatorService.navigatorKey.currentState;
      if (nav == null) {
        _pendingStoryArgs = args;
        return;
      }

      nav.pushNamedAndRemoveUntil(
        '${AppRoutes.storyViewPublic}/${args.initialStoryId}',
            (_) => false,
        arguments: args,
      );
    });
  }

  // ===========================
  // GENERIC NAV QUEUE
  // ===========================

  void _queueNavigation(String route, Object? args) {
    _pendingRoute = route;
    _pendingRouteArgs = args;
    _flushPendingNavigation();
  }

  void _flushPendingNavigation() {
    if (_pendingRoute == null) return;
    if (_lifecycleState != AppLifecycleState.resumed) return;
    if (_genericNavScheduled) return;

    _genericNavScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _genericNavScheduled = false;

      final route = _pendingRoute;
      final args = _pendingRouteArgs;
      _pendingRoute = null;
      _pendingRouteArgs = null;

      if (route == null) return;

      final nav = NavigatorService.navigatorKey.currentState;
      if (nav == null) {
        _pendingRoute = route;
        _pendingRouteArgs = args;
        return;
      }

      final session = SupabaseService.instance.client?.auth.currentSession;
      if (session == null) {
        _pendingRoute = route;
        _pendingRouteArgs = args;
        nav.pushNamed(AppRoutes.authLogin);
        return;
      }

      nav.pushNamed(route, arguments: args);
    });
  }

  void flushAfterLogin() {
    _flushPendingNavigation();
    _flushPendingStoryNavigation();
  }

  // ===========================
  // URL HELPERS
  // ===========================

  bool _isCapappHost(Uri uri) =>
      uri.host == 'capapp.co' || uri.host == 'www.capapp.co';

  bool _isCapappMemoryLink(Uri uri) =>
      _isCapappHost(uri) &&
          uri.pathSegments.isNotEmpty &&
          uri.pathSegments.first == 'memory';

  bool _isCapappProfileLink(Uri uri) =>
      _isCapappHost(uri) &&
          uri.pathSegments.isNotEmpty &&
          (uri.pathSegments.first == 'profile' ||
              uri.pathSegments.first == 'user');

  bool _isCapappFriendsLink(Uri uri) =>
      _isCapappHost(uri) && uri.pathSegments.first == 'friends';

  bool _isCapappGroupLink(Uri uri) =>
      _isCapappHost(uri) && uri.pathSegments.first == 'group';

  bool _isCapappNotificationsLink(Uri uri) =>
      _isCapappHost(uri) && uri.pathSegments.first == 'notifications';

  bool _isCapappStoryHttpLink(Uri uri) =>
      _isCapappHost(uri) && uri.pathSegments.first == 'story';

  bool _isCapappLegacySLink(Uri uri) =>
      _isCapappHost(uri) && uri.pathSegments.first == 's';

  bool _isShareCapappLink(Uri uri) =>
      uri.host == 'share.capapp.co' || uri.host == 'www.share.capapp.co';

  bool _isCapsuleCustomSchemeStoryLink(Uri uri) =>
      uri.scheme == 'capsule' && uri.host == 'story';

  // ===========================
  // INVITES
  // ===========================

  Future<void> _processInviteLink(String type, String code) async {
    final client = SupabaseService.instance.client;
    if (client == null) return;

    final session = client.auth.currentSession;

    final response = await client.functions.invoke(
      'handle-qr-scan',
      body: {'type': type, 'code': code},
      headers: session != null
          ? {'Authorization': 'Bearer ${session.accessToken}'}
          : null,
    );

    final data = (response.data as Map?)?.cast<String, dynamic>() ?? {};

    if (data['requires_auth'] == true) {
      _pendingSessionToken = data['session_token'];
      NavigatorService.pushNamed(AppRoutes.authLogin);
      return;
    }

    if (data['success'] == true) {
      _navigateToConfirmation(type, data);
    }
  }

  void _navigateToConfirmation(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'friend':
        NavigatorService.pushNamed(AppRoutes.appFriends);
        break;
      case 'group':
        NavigatorService.pushNamed(
          AppRoutes.appGroups,
          arguments: {'groupId': data['group_id']},
        );
        break;
      case 'memory':
        NavigatorService.pushNamed(
          AppRoutes.appTimeline,
          arguments: MemoryNavArgs(memoryId: data['memory_id']).toMap(),
        );
        break;
      default:
        NavigatorService.pushNamed(AppRoutes.appFeed);
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

}
