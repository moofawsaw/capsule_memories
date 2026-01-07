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

  /// Reverse geocode coordinates to human-readable location
  static Future<String?> getLocationName(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) {
        return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
      }

      final placemark = placemarks.first;

      // Format: "City, State" or "City, Country"
      final city = placemark.locality ?? placemark.subAdministrativeArea;
      final state = placemark.administrativeArea;
      final country = placemark.country;

      if (city != null && state != null && state.isNotEmpty) {
        return '$city, $state';
      } else if (city != null && country != null && country.isNotEmpty) {
        return '$city, $country';
      } else if (city != null) {
        return city;
      }

      // Fallback to coordinates display
      return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
    } catch (e) {
      print('⚠️ Geocoding failed: $e');
      // Return coordinates as fallback
      return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
    }
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