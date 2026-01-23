import 'package:flutter/services.dart';

class AndroidMediaStoreDateTaken {
  static const MethodChannel _ch = MethodChannel('capsule/media_store');

  /// Returns milliseconds since epoch, or null if unavailable.
  static Future<int?> getDateTakenMillis(String contentUri) async {
    try {
      final result = await _ch.invokeMethod<dynamic>('getDateTaken', {
        'uri': contentUri,
      });
      if (result is int) return result;
      if (result is double) return result.toInt();
      return null;
    } catch (_) {
      return null;
    }
  }
}