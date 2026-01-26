// lib/services/network_connectivity_provider.dart
//
// Lightweight connectivity provider used for:
// - showing "no connection" empty states
// - disabling tap targets while offline
//
// Uses connectivity_plus (already in pubspec).

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool _hasConnectionFromEvent(dynamic event) {
  try {
    if (event is List<ConnectivityResult>) {
      // If ANY interface reports a usable transport, we consider it "online".
      return event.any((r) => r != ConnectivityResult.none);
    }
    if (event is ConnectivityResult) {
      return event != ConnectivityResult.none;
    }
    return true; // be permissive for unknown event shapes
  } catch (_) {
    return true;
  }
}

/// True when device appears offline (no network interfaces).
final isOfflineProvider = StreamProvider.autoDispose<bool>((ref) async* {
  final conn = Connectivity();

  // Initial value
  final initial = await conn.checkConnectivity();
  yield !_hasConnectionFromEvent(initial);

  // Subsequent updates
  await for (final event in conn.onConnectivityChanged) {
    yield !_hasConnectionFromEvent(event);
  }
});

