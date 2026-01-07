import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';

class LocationService {
  /// Check if location services are enabled and request permission if needed
  static Future<bool> checkAndRequestPermission() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      // Check permission status
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } catch (e) {
      print('⚠️ Location permission error: $e');
      return false;
    }
  }

  /// Get current location with medium accuracy
  static Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) {
        print('⚠️ Location permission not granted');
        return null;
      }

      print('📍 Fetching current location...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit:
            const Duration(seconds: 15), // OPTIMIZED: Increased from 10s to 15s
      );
      print('✅ Location obtained: ${position.latitude}, ${position.longitude}');

      return position;
    } on TimeoutException catch (e) {
      print('⏱️ Location fetch timeout: $e');
      return null;
    } catch (e) {
      print('⚠️ Failed to get location: $e');
      return null;
    }
  }

  /// Reverse geocode coordinates to human-readable location with retry and validation
  /// OPTIMIZED: Enhanced geocoding with better retry logic and NULL fallback
  static Future<String?> getLocationName(
      double latitude, double longitude) async {
    // OPTIMIZED: Increased retry attempts from 3 to 4 for better success rate
    for (int attempt = 1; attempt <= 4; attempt++) {
      try {
        print(
            '🗺️ GEOCODING ATTEMPT $attempt/4: Starting reverse geocoding for ($latitude, $longitude)');

        // OPTIMIZED: Increased timeout from 10s to 15s per attempt
        final placemarks =
            await placemarkFromCoordinates(latitude, longitude).timeout(
          Duration(seconds: 15),
          onTimeout: () {
            print('⏱️ GEOCODING ATTEMPT $attempt: Timeout after 15 seconds');
            return <Placemark>[];
          },
        );

        if (placemarks.isEmpty) {
          print(
              '⚠️ GEOCODING ATTEMPT $attempt: No placemarks found, retrying...');
          if (attempt < 4) {
            // OPTIMIZED: Progressive backoff - wait longer between retries
            final waitTime = attempt * 2; // 2s, 4s, 6s
            print('⏳ Waiting ${waitTime}s before retry...');
            await Future.delayed(Duration(seconds: waitTime));
            continue;
          }
          // CRITICAL FIX: Return NULL instead of coordinates when geocoding fails
          print(
              '❌ GEOCODING: All 4 attempts failed - returning NULL for location_name');
          return null;
        }

        // CRITICAL FIX: Safely access first placemark with null check
        final placemark = placemarks.first;

        print('📍 GEOCODING ATTEMPT $attempt: Placemark details:');
        print('   - locality: ${placemark.locality}');
        print('   - subAdministrativeArea: ${placemark.subAdministrativeArea}');
        print('   - administrativeArea: ${placemark.administrativeArea}');
        print('   - country: ${placemark.country}');

        // Format: "City, State" or "City, Country"
        final city = placemark.locality ?? placemark.subAdministrativeArea;
        final state = placemark.administrativeArea;
        final country = placemark.country;

        String? formattedLocation;

        if (city != null && state != null && state.isNotEmpty) {
          formattedLocation = '$city, $state';
        } else if (city != null && country != null && country.isNotEmpty) {
          formattedLocation = '$city, $country';
        } else if (city != null) {
          formattedLocation = city;
        }

        // CRITICAL VALIDATION: Verify the result is NOT coordinates
        if (formattedLocation != null) {
          final parts = formattedLocation.split(',');
          if (parts.length == 2) {
            final firstPart = parts[0].trim();
            final secondPart = parts[1].trim();

            // Check if result looks like coordinates (both parts are numeric)
            final isCoordinates = double.tryParse(firstPart) != null &&
                double.tryParse(secondPart) != null;

            if (isCoordinates) {
              print(
                  '⚠️ GEOCODING ATTEMPT $attempt: Result looks like coordinates ($formattedLocation), retrying...');
              if (attempt < 4) {
                final waitTime = attempt * 2;
                print('⏳ Waiting ${waitTime}s before retry...');
                await Future.delayed(Duration(seconds: waitTime));
                continue;
              }
              // CRITICAL FIX: Return NULL instead of coordinates
              print(
                  '❌ GEOCODING: All attempts returned coordinates, returning NULL');
              return null;
            }
          }

          // Success - we have a proper city/state format
          print('✅ GEOCODING SUCCESS: Location name = "$formattedLocation"');
          return formattedLocation;
        }

        // No valid city found on this attempt
        print(
            '⚠️ GEOCODING ATTEMPT $attempt: No valid city/state found, retrying...');
        if (attempt < 4) {
          final waitTime = attempt * 2;
          print('⏳ Waiting ${waitTime}s before retry...');
          await Future.delayed(Duration(seconds: waitTime));
          continue;
        }

        // CRITICAL FIX: Return NULL instead of coordinates after all retries
        print('❌ GEOCODING: All attempts failed, returning NULL');
        return null;
      } catch (e) {
        print('❌ GEOCODING ATTEMPT $attempt ERROR: $e');
        if (attempt < 4) {
          final waitTime = attempt * 2;
          print('⏳ Waiting ${waitTime}s before retry...');
          await Future.delayed(Duration(seconds: waitTime));
          continue;
        }
        // CRITICAL FIX: Return NULL instead of coordinates on error
        print('❌ GEOCODING: All attempts encountered errors, returning NULL');
        return null;
      }
    }

    // CRITICAL FIX: Ultimate fallback is NULL, not coordinates
    print('❌ GEOCODING: Final fallback - returning NULL');
    return null;
  }

  /// Get location data with formatted name
  /// OPTIMIZED: Better timeout handling and validation
  static Future<Map<String, dynamic>?> getLocationData() async {
    try {
      print('🌍 Starting location data fetch...');
      final position = await getCurrentLocation();
      if (position == null) {
        print('❌ No position obtained - returning NULL');
        return null;
      }

      print('🗺️ Reverse geocoding location...');
      // OPTIMIZED: Wrap geocoding in timeout to prevent hanging
      final locationName = await getLocationName(
        position.latitude,
        position.longitude,
      ).timeout(
        Duration(seconds: 60), // Total 60s timeout for all 4 retry attempts
        onTimeout: () {
          print('⏱️ Geocoding timed out after 60 seconds total');
          return null;
        },
      );

      // CRITICAL VALIDATION: Check if we got a real city name
      if (locationName != null) {
        print('✅ Location data complete: "$locationName"');
        print('   Coordinates: ${position.latitude}, ${position.longitude}');
      } else {
        print('⚠️ Geocoding failed - location_name will be NULL');
        print('   Coordinates: ${position.latitude}, ${position.longitude}');
      }

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'location_name': locationName, // Will be NULL if geocoding failed
      };
    } catch (e) {
      print('⚠️ Failed to get location data: $e');
      return null;
    }
  }
}
