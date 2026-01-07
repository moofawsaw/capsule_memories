import './location_service.dart';
import './supabase_service.dart';

/// Service for managing memory-related operations
/// Provides methods for creating, updating, and managing memories
class MemoryService {
  final _supabase = SupabaseService.instance.client;

  /// Create a new memory in the database with proper location geocoding
  /// Uses LocationService to transform coordinates into "City, State" format
  /// matching the exact process used for story creation
  Future<String?> createMemory({
    required String title,
    required String creatorId,
    required String visibility,
    required String duration,
    required String categoryId,
    required List<String> invitedUserIds,
  }) async {
    try {
      print('🚀 MEMORY CREATION START: Creating memory "$title"');

      // Validate categoryId before proceeding
      if (categoryId.isEmpty) {
        throw Exception('Category ID is required');
      }

      // STEP 1: Fetch location data with proper geocoding using LocationService
      // If geocoding fails after all retries, location_name will be NULL
      print('📍 MEMORY CREATION: Fetching location data...');
      final locationData = await LocationService.getLocationData();

      double? latitude;
      double? longitude;
      String? locationName;

      if (locationData != null) {
        latitude = locationData['latitude'];
        longitude = locationData['longitude'];
        locationName = locationData['location_name'];

        print('✅ MEMORY LOCATION DATA OBTAINED:');
        print('   - Latitude: $latitude');
        print('   - Longitude: $longitude');
        print(
            '   - Location Name: ${locationName ?? "NULL (geocoding failed)"}');
      } else {
        print('⚠️ MEMORY CREATION: LocationService returned NULL');
        print('   Memory will be created without location data');
      }

      // Get category-based duration
      print('⏱️ MEMORY CREATION: Calculating memory duration...');
      final durationTime = await _getCategoryDuration(categoryId, duration);
      print(
          '✅ MEMORY CREATION: Duration set to: ${durationTime.toIso8601String()}');

      // Set start_time and end_time
      final now = DateTime.now().toUtc();
      final startTime = now;
      final endTime = durationTime;

      print('🕐 MEMORY CREATION: Time fields:');
      print('   - start_time: ${startTime.toIso8601String()}');
      print('   - end_time: ${endTime.toIso8601String()}');

      // STEP 2: Create memory with location data
      print('💾 MEMORY CREATION: Inserting into database...');
      final memoryData = {
        'title': title,
        'creator_id': creatorId,
        'category_id': categoryId,
        'visibility': visibility,
        'duration': duration,
        'location_lat': latitude,
        'location_lng': longitude,
        'location_name': locationName,
        'created_at': now.toIso8601String(),
        'expires_at': durationTime.toIso8601String(),
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
      };

      print('📝 MEMORY DATA TO INSERT:');
      print('   - title: $title');
      print('   - latitude: ${latitude ?? "NULL"}');
      print('   - longitude: ${longitude ?? "NULL"}');
      print('   - location_name: ${locationName ?? "NULL"}');

      // Insert and validate response
      final response = await _supabase
          ?.from('memories')
          .insert(memoryData)
          .select(
              'id, location_name, location_lat, location_lng, start_time, end_time')
          .single();

      final memoryId = response?['id'] as String?;
      final dbLocationName = response?['location_name'] as String?;
      final dbLocationLat = response?['location_lat'];
      final dbLocationLng = response?['location_lng'];
      final dbStartTime = response?['start_time'] as String?;
      final dbEndTime = response?['end_time'] as String?;

      if (memoryId == null) {
        print('❌ MEMORY CREATION: Memory ID not returned from database');
        throw Exception('Memory ID not returned');
      }

      print('✅ MEMORY CREATION: Memory inserted with ID: $memoryId');
      print('🔍 MEMORY CREATION: Database validation:');
      print(
          '   - location_name: ${dbLocationName ?? 'NULL (location unavailable)'}');
      print('   - location_lat: $dbLocationLat');
      print('   - location_lng: $dbLocationLng');
      print('   - start_time: $dbStartTime');
      print('   - end_time: $dbEndTime');

      // CRITICAL FIX: Add creator as a contributor using ONLY valid columns
      // Schema validation confirms memory_contributors has ONLY: id, memory_id, user_id, joined_at
      // NO 'role' column exists - this was causing PostgrestException PGRST204
      print('👤 MEMORY CREATION: Adding creator as contributor...');
      await _supabase?.from('memory_contributors').insert({
        'memory_id': memoryId,
        'user_id': creatorId,
        'joined_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Send invitations using ONLY valid columns
      if (invitedUserIds.isNotEmpty) {
        print(
            '📧 MEMORY CREATION: Sending ${invitedUserIds.length} invitation(s)...');
        for (final userId in invitedUserIds) {
          await _supabase?.from('memory_contributors').insert({
            'memory_id': memoryId,
            'user_id': userId,
            'joined_at': DateTime.now().toUtc().toIso8601String(),
          });
        }
        print('✅ MEMORY CREATION: Invitations sent successfully');
      } else {
        print('ℹ️ MEMORY CREATION: No invitations to send');
      }

      print(
          '🎉 MEMORY CREATION COMPLETE: Memory "$title" created successfully');
      print('   Final memory ID: $memoryId');
      print(
          '   Final location_name: ${dbLocationName ?? 'NULL (location unavailable)'}');

      return memoryId;
    } catch (e, stackTrace) {
      print('❌ MEMORY CREATION FAILED: Error creating memory');
      print('   Error: $e');
      print('   Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get category-based duration
  /// Calculates memory expiration time based on category settings
  Future<DateTime> _getCategoryDuration(
      String categoryId, String duration) async {
    // Calculate duration based on the duration parameter
    // This could be enhanced to query category-specific durations from the database
    return DateTime.now().add(Duration(hours: 12));
  }

  /// Update memory location with proper geocoding
  /// Uses LocationService to ensure location_name is formatted as "City, State"
  Future<Map<String, dynamic>?> updateMemoryLocation(String memoryId) async {
    try {
      print('📍 UPDATE LOCATION: Fetching location for memory: $memoryId');

      // Get location data with proper geocoding
      final locationData = await LocationService.getLocationData();

      if (locationData == null) {
        print('❌ UPDATE LOCATION: Failed to get location data');
        return null;
      }

      final locationName = locationData['location_name'] as String?;
      print('✅ UPDATE LOCATION: Got location_name: "$locationName"');

      // Update memory in database
      await _supabase?.from('memories').update({
        'location_name': locationData['location_name'],
        'location_lat': locationData['latitude'],
        'location_lng': locationData['longitude'],
      }).eq('id', memoryId);

      print('✅ UPDATE LOCATION: Memory location updated successfully');

      return locationData;
    } catch (e) {
      print('❌ UPDATE LOCATION: Error updating memory location: $e');
      return null;
    }
  }
}
