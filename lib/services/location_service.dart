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
        timeLimit: const Duration(seconds: 10),
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
  /// CRITICAL FIX: Added timeout, retry logic, and coordinate validation
  static Future<String?> getLocationName(
      double latitude, double longitude) async {
    // Try geocoding with retries (max 3 attempts)
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        print(
            '🗺️ GEOCODING ATTEMPT $attempt: Starting reverse geocoding for ($latitude, $longitude)');

        // Add explicit timeout for geocoding operation
        final placemarks =
            await placemarkFromCoordinates(latitude, longitude).timeout(
          Duration(seconds: 10),
          onTimeout: () {
            print('⏱️ GEOCODING ATTEMPT $attempt: Timeout after 10 seconds');
            return <Placemark>[];
          },
        );

        if (placemarks.isEmpty) {
          print(
              '⚠️ GEOCODING ATTEMPT $attempt: No placemarks found, retrying...');
          if (attempt < 3) {
            await Future.delayed(Duration(seconds: 2)); // Wait before retry
            continue;
          }
          print(
              '❌ GEOCODING: All attempts failed - no placemarks found, returning coordinates');
          return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
        }

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
              if (attempt < 3) {
                await Future.delayed(Duration(seconds: 2));
                continue;
              }
              // Last attempt failed - return coordinates as fallback
              print(
                  '❌ GEOCODING: All attempts returned coordinates, using fallback');
              return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
            }
          }

          // Success - we have a proper city/state format
          print(
              '✅ GEOCODING: Successfully formatted location: $formattedLocation');
          return formattedLocation;
        }

        // No valid city found on this attempt
        print(
            '⚠️ GEOCODING ATTEMPT $attempt: No valid city/state found, retrying...');
        if (attempt < 3) {
          await Future.delayed(Duration(seconds: 2));
          continue;
        }

        // Fallback to coordinates after all retries
        print('❌ GEOCODING: All attempts failed, returning coordinates');
        return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
      } catch (e) {
        print('❌ GEOCODING ATTEMPT $attempt: Error: $e');
        if (attempt < 3) {
          await Future.delayed(Duration(seconds: 2));
          continue;
        }
        // Return coordinates as final fallback
        return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
      }
    }

    // Should never reach here, but return coordinates as ultimate fallback
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  /// Get location data with formatted name
  static Future<Map<String, dynamic>?> getLocationData() async {
    try {
      print('🌍 Starting location data fetch...');
      final position = await getCurrentLocation();
      if (position == null) {
        print('❌ No position obtained');
        return null;
      }

      print('🗺️ Reverse geocoding location...');
      final locationName = await getLocationName(
        position.latitude,
        position.longitude,
      );

      print('✅ Location data complete: $locationName');
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'location_name': locationName,
      };
    } catch (e) {
      print('⚠️ Failed to get location data: $e');
      return null;
    }
  }
}
