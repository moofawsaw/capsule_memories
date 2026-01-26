// lib/core/services/deep_link_service.dart

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../routes/app_routes.dart';
import '../../services/supabase_service.dart';
import '../models/feed_story_context.dart';
import '../utils/memory_nav_args.dart';
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

  // ===== De-dupe (Android often delivers same deep link twice) =====
  String? _lastHandledUri;
  DateTime? _lastHandledAt;

  String? _lastOpenedStoryId;
  DateTime? _lastOpenedStoryAt;

  // ===== Share link resolution (share.capapp.co/<code> -> capapp.co/story/<uuid>) =====
  final Map<String, Future<String?>> _shareResolveInflight = {};

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

  /// Handle a deep link coming from a non-AppLinks source (e.g. push notification tap).
  /// Accepts:
  /// - Full URLs: https://capapp.co/..., https://share.capapp.co/...
  /// - Capsule scheme: capsule://...
  /// - Relative paths: /story/<id>, /memory/<id>, /join/..., /app/...
  Future<void> handleExternalDeepLink(String raw) async {
    final s = raw.trim();
    if (s.isEmpty) return;

    // If it's an internal route, navigate directly (keeps behavior consistent).
    if (s.startsWith('/app/') || s.startsWith('/auth/') || s.startsWith('/join/')) {
      final uri = Uri.parse('https://capapp.co$s');
      final args = uri.queryParameters.isEmpty ? null : Map<String, dynamic>.from(uri.queryParameters);
      _queueNavigation(uri.path, args);
      return;
    }

    Uri uri;
    try {
      uri = Uri.parse(s);
    } catch (_) {
      return;
    }

    // If it's a relative URI like "story/<id>", normalize to capapp.co.
    if (uri.scheme.isEmpty) {
      final path = s.startsWith('/') ? s : '/$s';
      uri = Uri.parse('https://capapp.co$path');
    }

    await _handleDeepLink(uri);
  }

  /// Handle an already-parsed URI from an external source.
  Future<void> handleExternalUri(Uri uri) => _handleDeepLink(uri);

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

    // ------------------------------------------------------------
    // SUPABASE AUTH CALLBACKS (OAuth / magic links / recovery)
    // ------------------------------------------------------------
    // Supabase uses custom schemes like:
    // io.supabase.<anything>://login-callback/...
    // If we ignore these, the OAuth flow will resume the app without a session.
    if (uri.scheme.startsWith('io.supabase')) {
      try {
        final client = SupabaseService.instance.client;
        if (client != null) {
          await client.auth.getSessionFromUrl(uri);
        }
      } catch (e) {
        debugPrint('❌ Supabase auth callback handling failed: $e');
      }
      return;
    }

    if (uri.scheme != 'https' &&
        uri.scheme != 'http' &&
        uri.scheme != 'capsule') {
      return;
    }

    // Android can dispatch both getInitialLink() and uriLinkStream for the same tap.
    // De-dupe within a short window.
    final now = DateTime.now();
    final uriKey = uri.toString();
    final lastAt = _lastHandledAt;
    if (_lastHandledUri == uriKey &&
        lastAt != null &&
        now.difference(lastAt) < const Duration(milliseconds: 1200)) {
      return;
    }
    _lastHandledUri = uriKey;
    _lastHandledAt = now;

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
      final code = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      if (code.isNotEmpty) {
        final resolved = await _resolveShareCodeToStoryId(code);
        _openStory(resolved ?? code);
      }
      return;
    }

    if (_isCapsuleCustomSchemeStoryLink(uri)) {
      final storyId = uri.pathSegments.first;
      if (storyId.isNotEmpty) _openStory(storyId);
      return;
    }

    // ---------- MEMORY + STORY (HTTPS - must be BEFORE plain memory handler) ----------
    if (_isCapappMemoryStoryLink(uri)) {
      final memoryId = uri.pathSegments[1];
      final storyId = uri.pathSegments[3];
      debugPrint('📦 HTTPS Memory+Story deep link: memory=$memoryId, story=$storyId');

      _queueNavigation(
        AppRoutes.appTimeline,
        MemoryNavArgs(memoryId: memoryId, initialStoryId: storyId).toMap(),
      );
      return;
    }

    // ---------- MEMORY + STORY (capsule:// scheme) ----------
    if (_isCapsuleMemoryStoryLink(uri)) {
      final memoryId = uri.pathSegments[1];
      final storyId = uri.pathSegments[3];
      debugPrint('📦 Capsule Memory+Story deep link: memory=$memoryId, story=$storyId');

      _queueNavigation(
        AppRoutes.appTimeline,
        MemoryNavArgs(memoryId: memoryId, initialStoryId: storyId).toMap(),
      );
      return;
    }

    // ---------- MEMORY (plain - must be AFTER memory+story handlers) ----------
    if (_isCapappMemoryLink(uri)) {
      final memoryId = uri.pathSegments[1];
      debugPrint('📦 Memory deep link: $memoryId');

      _queueNavigation(
        AppRoutes.appTimeline,
        MemoryNavArgs(memoryId: memoryId).toMap(),
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
    // De-dupe rapid repeated opens (defensive against double-delivery).
    final now = DateTime.now();
    final lastAt = _lastOpenedStoryAt;
    if (_lastOpenedStoryId == storyId &&
        lastAt != null &&
        now.difference(lastAt) < const Duration(milliseconds: 1200)) {
      return;
    }
    _lastOpenedStoryId = storyId;
    _lastOpenedStoryAt = now;

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

      // IMPORTANT:
      // Keep at least one route in the stack so closing the public story view
      // can safely pop back without hitting Navigator's `_history.isNotEmpty` assertion.
      nav.pushNamedAndRemoveUntil(
        '${AppRoutes.storyViewPublic}/${args.initialStoryId}',
        (route) => route.isFirst,
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

      // ✅ Force widget recreation by removing existing route first
      // This ensures initState() runs fresh with new arguments (e.g., new storyId)
      nav.pushNamedAndRemoveUntil(
        route,
            (r) => r.isFirst, // Keep only the root route
        arguments: args,
      );
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

  // Memory + Story (HTTPS): capapp.co/memory/{id}/story/{id}
  bool _isCapappMemoryStoryLink(Uri uri) =>
      _isCapappHost(uri) &&
          uri.pathSegments.length >= 4 &&
          uri.pathSegments[0] == 'memory' &&
          uri.pathSegments[2] == 'story';

  // Memory + Story (capsule://): capsule://memory/{id}/story/{id}
  bool _isCapsuleMemoryStoryLink(Uri uri) =>
      uri.scheme == 'capsule' &&
          uri.pathSegments.length >= 4 &&
          uri.pathSegments[0] == 'memory' &&
          uri.pathSegments[2] == 'story';

  // Plain memory (HTTPS): capapp.co/memory/{id}
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

  bool _looksLikeUuid(String s) {
    final v = s.trim();
    if (v.length != 36) return false;
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(v);
  }

  Future<String?> _resolveShareCodeToStoryId(String code) {
    final normalized = code.trim();
    if (normalized.isEmpty) return Future.value(null);
    if (_looksLikeUuid(normalized)) return Future.value(normalized);

    final existing = _shareResolveInflight[normalized];
    if (existing != null) return existing;

    final future = () async {
      try {
        final url = Uri.parse('https://share.capapp.co/$normalized');
        final res = await http.get(url);
        final body = res.body;

        // The share page includes a link like:
        // https://capapp.co/story/<uuid>
        final match = RegExp(
          r'https?://capapp\.co/story/([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})',
        ).firstMatch(body);

        final id = match?.group(1);
        return (id != null && id.isNotEmpty) ? id : null;
      } catch (e) {
        debugPrint('⚠️ Failed to resolve share code "$normalized": $e');
        return null;
      } finally {
        _shareResolveInflight.remove(normalized);
      }
    }();

    _shareResolveInflight[normalized] = future;
    return future;
  }

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
