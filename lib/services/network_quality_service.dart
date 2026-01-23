// lib/services/network_quality_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkQuality {
  wifi,
  cellular,
  unknown,
}

class NetworkQualityService {
  static final Connectivity _conn = Connectivity();

  // Cache the last known quality so cold start doesn't block uploads
  static NetworkQuality _cached = NetworkQuality.unknown;
  static DateTime _cachedAt = DateTime.fromMillisecondsSinceEpoch(0);

  // Prevent duplicate in-flight checks
  static Future<NetworkQuality>? _inFlight;

  // Keep cache warm by listening to changes (best-effort)
  static StreamSubscription<dynamic>? _sub;
  static bool _primed = false;

  /// Call this once at app start or when opening the camera/story flow.
  /// Non-blocking.
  static void prime() {
    if (_primed) {
      // Still do a quick refresh in case TTL is long and we want fresher data
      _refresh();
      return;
    }
    _primed = true;

    // Subscribe to connectivity changes so cache stays accurate without waiting
    try {
      _sub = _conn.onConnectivityChanged.listen((event) {
        // event can be ConnectivityResult or List<ConnectivityResult> depending on version
        final q = _mapConnectivityEventToQuality(event);
        _cached = q;
        _cachedAt = DateTime.now();
      });
    } catch (_) {
      // If subscription fails for any reason, we still work via checkConnectivity()
    }

    // fire-and-forget; do not await
    _refresh();
  }

  /// Optional: call at app shutdown (not required)
  static Future<void> dispose() async {
    try {
      await _sub?.cancel();
    } catch (_) {}
    _sub = null;
    _primed = false;
  }

  /// Fast: returns cached value if it's fresh, otherwise times out quickly.
  static Future<NetworkQuality> getQuality({
    Duration timeout = const Duration(seconds: 2),
    Duration cacheTtl = const Duration(seconds: 20),
  }) async {
    final now = DateTime.now();
    if (now.difference(_cachedAt) <= cacheTtl) {
      return _cached;
    }

    // If there's already a check running, use it but still protect with timeout
    final fut = _inFlight ?? _refresh();

    try {
      return await fut.timeout(timeout, onTimeout: () => _cached);
    } catch (_) {
      return _cached;
    }
  }

  static Future<NetworkQuality> _refresh() {
    _inFlight ??= () async {
      try {
        final result = await _conn.checkConnectivity();
        final q = _mapConnectivityEventToQuality(result);

        _cached = q;
        _cachedAt = DateTime.now();
        return q;
      } catch (_) {
        _cachedAt = DateTime.now();
        return _cached;
      } finally {
        _inFlight = null;
      }
    }();

    return _inFlight!;
  }

  /// Handles both:
  /// - ConnectivityResult (newer/typical)
  /// - List<ConnectivityResult> (some versions/platforms)
  static NetworkQuality _mapConnectivityEventToQuality(dynamic event) {
    try {
      // If it's a list (some versions), prefer wifi if present, else mobile
      if (event is List<ConnectivityResult>) {
        if (event.contains(ConnectivityResult.wifi)) return NetworkQuality.wifi;
        if (event.contains(ConnectivityResult.mobile)) return NetworkQuality.cellular;
        // Some platforms might report ethernet/vpn/etc — treat as unknown (or wifi-like if you prefer)
        return NetworkQuality.unknown;
      }

      // Typical: single ConnectivityResult
      if (event is ConnectivityResult) {
        if (event == ConnectivityResult.wifi) return NetworkQuality.wifi;
        if (event == ConnectivityResult.mobile) return NetworkQuality.cellular;
        return NetworkQuality.unknown;
      }

      return NetworkQuality.unknown;
    } catch (_) {
      return NetworkQuality.unknown;
    }
  }
}