import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

class AndroidMediaStoreService {
  static const MethodChannel _ch = MethodChannel('com.capsule.app/media_store');

  /// Returns milliseconds since epoch, or null if unavailable.
  static Future<int?> getDateTakenMillis(String uri) async {
    if (kIsWeb) return null;

    try {
      final res = await _ch.invokeMethod<dynamic>('getDateTaken', {'uri': uri});
      if (res is int) return res;
      if (res is double) return res.toInt();
      return null;
    } catch (_) {
      return null;
    }
  }
}