import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class LocationService {
  /// Check if location services are enabled and request permission if needed
  static Future<bool> checkAndRequestPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ Location services are disabled');
        return false;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('⚠️ Location permission denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('⚠️ Location permission denied forever');
        return false;
      }

      print('✅ Location permission granted: $permission');
      return true;
    } catch (e) {
      print('⚠️ Location permission error: $e');
      return false;
    }
  }
  /// Fast coords-only fetch (no reverse geocode).
  /// Safe for "post now" flows.
  static Future<Map<String, dynamic>?> getCoordsOnly({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      final position = await getCurrentLocation().timeout(timeout, onTimeout: () {
        print('⏱️ Coords-only timeout after ${timeout.inSeconds}s');
        return null;
      });

      if (position == null) return null;

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      print('⚠️ getCoordsOnly failed: $e');
      return null;
    }
  }

  /// Best-effort reverse geocode with a shorter cap than your current 60s.
  /// Use this in background backfill only.
  static Future<String?> getLocationNameBestEffort(
      double latitude,
      double longitude, {
        Duration timeout = const Duration(seconds: 6),
      }) async {
    try {
      return await getLocationName(latitude, longitude)
          .timeout(timeout, onTimeout: () {
        print('⏱️ Best-effort geocode timeout after ${timeout.inSeconds}s');
        return null;
      });
    } catch (e) {
      print('⚠️ getLocationNameBestEffort failed: $e');
      return null;
    }
  }

  /// Get current location with reliable fallbacks
  ///
  /// Key fix:
  /// - Try last-known location immediately (works after resume/background, faster)
  /// - Then try a fresh fix with a shorter timeout
  /// - If fresh fails, return last-known instead of null
  static Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) {
        print('⚠️ Location permission not granted');
        return null;
      }

      // 1) Try last known immediately
      Position? lastKnown;
      try {
        lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          print(
              '✅ Using last known location: ${lastKnown.latitude}, ${lastKnown.longitude}');
        } else {
          print('ℹ️ No last known location available');
        }
      } catch (e) {
        print('⚠️ Failed to get last known position: $e');
      }

      // 2) Try a fresh fix (do not hard-fail if it times out)
      print('📍 Fetching current location (fresh fix)...');
      try {
        final fresh = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );

        print('✅ Fresh location obtained: ${fresh.latitude}, ${fresh.longitude}');
        return fresh;
      } on TimeoutException catch (e) {
        print('⏱️ Fresh location fetch timeout: $e');
        return lastKnown;
      } catch (e) {
        print('⚠️ Failed to get fresh location: $e');
        return lastKnown;
      }
    } catch (e) {
      print('⚠️ Failed to get location: $e');
      return null;
    }
  }

  /// Public reverse geocode entrypoint
  static Future<String?> getLocationName(
      double latitude, double longitude) async {
    // IMPORTANT: geocoding package is not supported on web; use HTTP reverse geocode instead.
    if (kIsWeb) {
      return _getLocationNameWeb(latitude, longitude);
    }
    return _getLocationNameNative(latitude, longitude);
  }

  /// Native (Android/iOS) reverse geocoding using geocoding plugin
  static Future<String?> _getLocationNameNative(
      double latitude, double longitude) async {
    for (int attempt = 1; attempt <= 4; attempt++) {
      try {
        print(
            '🗺️ GEOCODING (NATIVE) ATTEMPT $attempt/4 for ($latitude, $longitude)');

        final placemarks =
        await placemarkFromCoordinates(latitude, longitude).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            print(
                '⏱️ GEOCODING (NATIVE) ATTEMPT $attempt: Timeout after 15 seconds');
            return <Placemark>[];
          },
        );

        if (placemarks.isEmpty) {
          print('⚠️ GEOCODING (NATIVE) ATTEMPT $attempt: No placemarks found');
          if (attempt < 4) {
            final waitTime = attempt * 2;
            print('⏳ Waiting ${waitTime}s before retry...');
            await Future.delayed(Duration(seconds: waitTime));
            continue;
          }
          return null;
        }

        final p = placemarks.first;

        final city = (p.locality?.trim().isNotEmpty ?? false)
            ? p.locality!.trim()
            : (p.subAdministrativeArea?.trim().isNotEmpty ?? false)
            ? p.subAdministrativeArea!.trim()
            : null;

        final country = p.country?.trim();
        final admin = p.administrativeArea
            ?.trim(); // e.g., "Ontario" or "New York"

        final stateAbbrev = _abbreviateRegion(admin, country);

        final formatted = _formatLocation(
          city: city,
          region: stateAbbrev ?? admin,
          country: country,
        );

        if (formatted != null) {
          print('✅ GEOCODING (NATIVE) SUCCESS: "$formatted"');
          return formatted;
        }

        print('⚠️ GEOCODING (NATIVE) ATTEMPT $attempt: No valid city/region');
        if (attempt < 4) {
          final waitTime = attempt * 2;
          print('⏳ Waiting ${waitTime}s before retry...');
          await Future.delayed(Duration(seconds: waitTime));
          continue;
        }
        return null;
      } catch (e) {
        print('❌ GEOCODING (NATIVE) ATTEMPT $attempt ERROR: $e');
        if (attempt < 4) {
          final waitTime = attempt * 2;
          print('⏳ Waiting ${waitTime}s before retry...');
          await Future.delayed(Duration(seconds: waitTime));
          continue;
        }
        return null;
      }
    }
    return null;
  }

  /// Web reverse geocoding using OpenStreetMap Nominatim
  static Future<String?> _getLocationNameWeb(
      double latitude, double longitude) async {
    for (int attempt = 1; attempt <= 4; attempt++) {
      try {
        print(
            '🗺️ GEOCODING (WEB) ATTEMPT $attempt/4 for ($latitude, $longitude)');

        final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
          'format': 'jsonv2',
          'lat': latitude.toString(),
          'lon': longitude.toString(),
          'zoom': '10',
          'addressdetails': '1',
        });

        final res = await http.get(
          uri,
          headers: {
            // Nominatim requires an identifying User-Agent.
            'User-Agent': 'CapsuleMemories/1.0 (contact: support@yourdomain.com)',
            'Accept': 'application/json',
          },
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException('Web geocoding timeout');
          },
        );

        if (res.statusCode != 200) {
          print(
              '⚠️ GEOCODING (WEB) ATTEMPT $attempt: HTTP ${res.statusCode}');
          if (attempt < 4) {
            final waitTime = attempt * 2;
            print('⏳ Waiting ${waitTime}s before retry...');
            await Future.delayed(Duration(seconds: waitTime));
            continue;
          }
          return null;
        }

        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final address = (data['address'] as Map?)?.cast<String, dynamic>();

        if (address == null) {
          print(
              '⚠️ GEOCODING (WEB) ATTEMPT $attempt: Missing address in response');
          if (attempt < 4) {
            final waitTime = attempt * 2;
            print('⏳ Waiting ${waitTime}s before retry...');
            await Future.delayed(Duration(seconds: waitTime));
            continue;
          }
          return null;
        }

        // Nominatim uses different keys depending on area.
        final city = _firstNonEmptyString([
          address['city'],
          address['town'],
          address['village'],
          address['hamlet'],
          address['municipality'],
          address['county'],
        ]);

        final country = _firstNonEmptyString([address['country']]);
        final stateFull =
        _firstNonEmptyString([address['state']]); // Ontario, New York
        final stateAbbrev = _abbreviateRegion(stateFull, country);

        final formatted = _formatLocation(
          city: city,
          region: stateAbbrev ?? stateFull,
          country: country,
        );

        if (formatted != null) {
          print('✅ GEOCODING (WEB) SUCCESS: "$formatted"');
          return formatted;
        }

        print('⚠️ GEOCODING (WEB) ATTEMPT $attempt: No valid city/region');
        if (attempt < 4) {
          final waitTime = attempt * 2;
          print('⏳ Waiting ${waitTime}s before retry...');
          await Future.delayed(Duration(seconds: waitTime));
          continue;
        }
        return null;
      } catch (e) {
        print('❌ GEOCODING (WEB) ATTEMPT $attempt ERROR: $e');
        if (attempt < 4) {
          final waitTime = attempt * 2;
          print('⏳ Waiting ${waitTime}s before retry...');
          await Future.delayed(Duration(seconds: waitTime));
          continue;
        }
        return null;
      }
    }
    return null;
  }

  static String? _formatLocation({
    required String? city,
    required String? region,
    required String? country,
  }) {
    final c = city?.trim();
    final r = region?.trim();
    final co = country?.trim();

    if (c != null && c.isNotEmpty && r != null && r.isNotEmpty) {
      return '$c, $r';
    }
    if (c != null && c.isNotEmpty && co != null && co.isNotEmpty) {
      return '$c, $co';
    }
    if (c != null && c.isNotEmpty) {
      return c;
    }
    return null;
  }

  static String? _firstNonEmptyString(List<dynamic> values) {
    for (final v in values) {
      if (v is String) {
        final s = v.trim();
        if (s.isNotEmpty) return s;
      }
    }
    return null;
  }

  /// Converts "Ontario" -> "ON", "New York" -> "NY" when possible.
  static String? _abbreviateRegion(String? adminArea, String? country) {
    if (adminArea == null) return null;
    final a = adminArea.trim();
    if (a.isEmpty) return null;

    final c = (country ?? '').toLowerCase();

    if (c.contains('canada')) {
      return _canadaProvinceAbbrev[a] ?? a;
    }

    if (c.contains('united states') || c.contains('usa')) {
      return _usStateAbbrev[a] ?? a;
    }

    return null;
  }

  static const Map<String, String> _canadaProvinceAbbrev = {
    'Alberta': 'AB',
    'British Columbia': 'BC',
    'Manitoba': 'MB',
    'New Brunswick': 'NB',
    'Newfoundland and Labrador': 'NL',
    'Nova Scotia': 'NS',
    'Northwest Territories': 'NT',
    'Nunavut': 'NU',
    'Ontario': 'ON',
    'Prince Edward Island': 'PE',
    'Quebec': 'QC',
    'Saskatchewan': 'SK',
    'Yukon': 'YT',
  };

  static const Map<String, String> _usStateAbbrev = {
    'Alabama': 'AL',
    'Alaska': 'AK',
    'Arizona': 'AZ',
    'Arkansas': 'AR',
    'California': 'CA',
    'Colorado': 'CO',
    'Connecticut': 'CT',
    'Delaware': 'DE',
    'Florida': 'FL',
    'Georgia': 'GA',
    'Hawaii': 'HI',
    'Idaho': 'ID',
    'Illinois': 'IL',
    'Indiana': 'IN',
    'Iowa': 'IA',
    'Kansas': 'KS',
    'Kentucky': 'KY',
    'Louisiana': 'LA',
    'Maine': 'ME',
    'Maryland': 'MD',
    'Massachusetts': 'MA',
    'Michigan': 'MI',
    'Minnesota': 'MN',
    'Mississippi': 'MS',
    'Missouri': 'MO',
    'Montana': 'MT',
    'Nebraska': 'NE',
    'Nevada': 'NV',
    'New Hampshire': 'NH',
    'New Jersey': 'NJ',
    'New Mexico': 'NM',
    'New York': 'NY',
    'North Carolina': 'NC',
    'North Dakota': 'ND',
    'Ohio': 'OH',
    'Oklahoma': 'OK',
    'Oregon': 'OR',
    'Pennsylvania': 'PA',
    'Rhode Island': 'RI',
    'South Carolina': 'SC',
    'South Dakota': 'SD',
    'Tennessee': 'TN',
    'Texas': 'TX',
    'Utah': 'UT',
    'Vermont': 'VT',
    'Virginia': 'VA',
    'Washington': 'WA',
    'West Virginia': 'WV',
    'Wisconsin': 'WI',
    'Wyoming': 'WY',
    'District of Columbia': 'DC',
  };

  /// Get location data with formatted name
  static Future<Map<String, dynamic>?> getLocationData() async {
    try {
      print('🌍 Starting location data fetch...');
      final position = await getCurrentLocation();
      if (position == null) {
        print('❌ No position obtained - returning NULL');
        return null;
      }

      final lat = position.latitude;
      final lng = position.longitude;

      print('✅ Coordinates obtained: $lat, $lng');
      print('🗺️ Reverse geocoding location...');

      final locationName =
      await getLocationName(lat, lng).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          print('⏱️ Geocoding timed out after 60 seconds total');
          return null;
        },
      );

      if (locationName != null) {
        print('✅ Location data complete: "$locationName"');
      } else {
        print('⚠️ Geocoding failed - location_name will be NULL');
      }

      return {
        'latitude': lat,
        'longitude': lng,
        'location_name': locationName,
      };
    } catch (e) {
      print('⚠️ Failed to get location data: $e');
      return null;
    }
  }
}
