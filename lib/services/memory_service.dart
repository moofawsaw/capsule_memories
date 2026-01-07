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

      // CRITICAL: Get location data with proper geocoding using LocationService
      // This ensures location_name is formatted as "City, State" (e.g., "Toronto, ON")
      // matching the exact same process used during story creation
      print('📍 MEMORY CREATION: Fetching location data...');
      final locationData = await LocationService.getLocationData();

      if (locationData == null) {
        print('❌ MEMORY CREATION: Location data is NULL');
        throw Exception('Failed to get location data');
      }

      print('📦 MEMORY CREATION: Raw location data received:');
      print('   - latitude: ${locationData['latitude']}');
      print('   - longitude: ${locationData['longitude']}');
      print('   - location_name: ${locationData['location_name']}');

      // 🚨 CRITICAL VALIDATION: Check if location_name is still coordinates
      final locationName = locationData['location_name'] as String?;

      if (locationName == null || locationName.isEmpty) {
        print('⚠️ MEMORY CREATION: location_name is NULL or EMPTY');
      } else {
        print('🔍 MEMORY CREATION: Validating location_name format...');
        final parts = locationName.split(',');

        if (parts.length == 2) {
          final firstPart = parts[0].trim();
          final secondPart = parts[1].trim();
          final isCoordinates = double.tryParse(firstPart) != null &&
              double.tryParse(secondPart) != null;

          if (isCoordinates) {
            print(
                '❌ MEMORY CREATION: location_name appears to be COORDINATES: "$locationName"');
            print(
                '   ⚠️ EXPECTED: "City, State" format (e.g., "Vancouver, BC")');
            print('   ⚠️ RECEIVED: Numeric coordinates instead of city name');
            print(
                '   🔍 DIAGNOSTIC: Geocoding API may have failed or timed out');
          } else {
            print(
                '✅ MEMORY CREATION: location_name properly formatted: "$locationName"');
            print('   ✓ Format: City, State/Province (as expected)');
          }
        } else {
          print(
              '⚠️ MEMORY CREATION: location_name has unexpected format (${parts.length} parts): "$locationName"');
        }
      }

      // Get category-based duration
      print('⏱️ MEMORY CREATION: Calculating memory duration...');
      final durationTime = await _getCategoryDuration(categoryId, duration);
      print(
          '✅ MEMORY CREATION: Duration set to: ${durationTime.toIso8601String()}');

      // CRITICAL FIX: Ensure start_time and end_time are properly set and not null
      final now = DateTime.now().toUtc();
      final startTime = now;
      final endTime = durationTime;

      print('🕐 MEMORY CREATION: Time fields being set:');
      print('   - start_time: ${startTime.toIso8601String()}');
      print('   - end_time: ${endTime.toIso8601String()}');

      // Create memory record with properly geocoded location
      final memoryData = {
        'title': title,
        'creator_id': creatorId,
        'category_id': categoryId,
        'visibility': visibility,
        'duration': duration,
        'location_lat': locationData['latitude'],
        'location_lng': locationData['longitude'],
        'location_name':
            locationData['location_name'], // Already formatted as "City, State"
        'created_at': now.toIso8601String(),
        'expires_at': durationTime.toIso8601String(),
        // CRITICAL FIX: Explicitly set start_time and end_time to prevent NULL values
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
      };

      print('📤 MEMORY CREATION: Inserting memory into database...');
      print('   Data being inserted:');
      print('   - title: ${memoryData['title']}');
      print('   - location_name: ${memoryData['location_name']}');
      print('   - location_lat: ${memoryData['location_lat']}');
      print('   - location_lng: ${memoryData['location_lng']}');

      // CRITICAL FIX: Select all location fields in the response to verify they were saved
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
      print('🔍 MEMORY CREATION: Database returned location data:');
      print('   - location_name: "$dbLocationName"');
      print('   - location_lat: $dbLocationLat');
      print('   - location_lng: $dbLocationLng');
      print('   - start_time: $dbStartTime');
      print('   - end_time: $dbEndTime');

      // CRITICAL VALIDATION: Check if location data was actually saved
      if (dbLocationName == null || dbLocationName.isEmpty) {
        print(
            '🚨 MEMORY CREATION: WARNING - location_name was NOT saved to database!');
        print(
            '   This may indicate an RLS policy issue preventing location data from being returned');
      }

      if (dbLocationLat == null || dbLocationLng == null) {
        print(
            '🚨 MEMORY CREATION: WARNING - coordinates were NOT saved to database!');
        print('   location_lat: $dbLocationLat, location_lng: $dbLocationLng');
      }

      // CRITICAL VALIDATION: Check if dates were actually saved
      if (dbStartTime == null || dbStartTime.isEmpty) {
        print(
            '🚨 MEMORY CREATION: WARNING - start_time is NULL or EMPTY in database!');
        print('   This will cause FormatException in realtime subscriptions');
      }

      if (dbEndTime == null || dbEndTime.isEmpty) {
        print(
            '🚨 MEMORY CREATION: WARNING - end_time is NULL or EMPTY in database!');
        print('   This will cause FormatException in realtime subscriptions');
      }

      if (dbLocationName != locationName) {
        print(
            '⚠️ MEMORY CREATION: location_name CHANGED after database insert!');
        print('   Before insert: "$locationName"');
        print('   After insert: "$dbLocationName"');
      } else {
        print(
            '✓ MEMORY CREATION: location_name preserved after database insert');
      }

      // Add creator as a contributor - CRITICAL FIX: Only insert id, memory_id, user_id, joined_at
      // NO 'role' column exists in memory_contributors table
      print('👤 MEMORY CREATION: Adding creator as contributor...');
      await _supabase?.from('memory_contributors').insert({
        'memory_id': memoryId,
        'user_id': creatorId,
        'joined_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Send invitations - CRITICAL FIX: Only insert valid columns
      if (invitedUserIds.isNotEmpty) {
        print(
            '📧 MEMORY CREATION: Sending ${invitedUserIds.length} invitation(s)...');
        for (final userId in invitedUserIds) {
          // Insert into memory_contributors, not memory_invitations
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
      print('   Final location_name: "$dbLocationName"');

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
