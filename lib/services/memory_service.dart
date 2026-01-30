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

    /// ✅ NEW: if created from a group, persist group_id on the memory row
    String? groupId,
  }) async {
    try {
      print('🚀 MEMORY CREATION START: Creating memory "$title"');

      if (categoryId.isEmpty) {
        throw Exception('Category ID is required');
      }

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

      print('⏱️ MEMORY CREATION: Calculating memory duration...');
      final durationTime = await _getCategoryDuration(categoryId, duration);
      print(
          '✅ MEMORY CREATION: Duration set to: ${durationTime.toIso8601String()}');

      final now = DateTime.now().toUtc();
      final startTime = now;
      final endTime = durationTime;

      print('🕐 MEMORY CREATION: Time fields:');
      print('   - start_time: ${startTime.toIso8601String()}');
      print('   - end_time: ${endTime.toIso8601String()}');

      print('💾 MEMORY CREATION: Inserting into database...');

      final memoryData = <String, dynamic>{
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

        // ✅ NEW
        if (groupId != null && groupId.isNotEmpty) 'group_id': groupId,
      };

      print('📝 MEMORY DATA TO INSERT:');
      print('   - title: $title');
      print('   - group_id: ${groupId ?? "NULL"}');
      print('   - latitude: ${latitude ?? "NULL"}');
      print('   - longitude: ${longitude ?? "NULL"}');
      print('   - location_name: ${locationName ?? "NULL"}');

      final response = await _supabase
          ?.from('memories')
          .insert(memoryData)
          .select(
              'id, group_id, location_name, location_lat, location_lng, start_time, end_time')
          .single();

      final memoryId = response?['id'] as String?;
      final dbGroupId = response?['group_id'] as String?;
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
      print('   - group_id: ${dbGroupId ?? "NULL"}');
      print(
          '   - location_name: ${dbLocationName ?? 'NULL (location unavailable)'}');
      print('   - location_lat: $dbLocationLat');
      print('   - location_lng: $dbLocationLng');
      print('   - start_time: $dbStartTime');
      print('   - end_time: $dbEndTime');

      // Add creator as contributor
      print('👤 MEMORY CREATION: Adding creator as contributor...');
      await _supabase?.from('memory_contributors').insert({
        'memory_id': memoryId,
        'user_id': creatorId,
        'joined_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Group-based creation: do NOT auto-add group members as contributors.
      // Instead, create pending invites so they must accept before gaining member privileges.
      //
      // The DB trigger on `memory_invites` will:
      // - create the in-app notification row
      // - send the push (via send_push_for_notification -> edge function)
      if (invitedUserIds.isNotEmpty) {
        if (groupId != null && groupId.isNotEmpty) {
          print(
              '👥 MEMORY CREATION: Creating ${invitedUserIds.length} pending invite(s) for group members...');

          final nowIso = DateTime.now().toUtc().toIso8601String();
          final inviteRows = invitedUserIds
              .map((id) => id.trim())
              .where((id) => id.isNotEmpty && id != creatorId)
              .map((userId) => {
                    'memory_id': memoryId,
                    'user_id': userId,
                    'invited_by': creatorId,
                    'status': 'pending',
                    'created_at': nowIso,
                  })
              .toList();

          if (inviteRows.isNotEmpty) {
            await _supabase?.from('memory_invites').upsert(
                  inviteRows,
                  onConflict: 'memory_id,user_id',
                );
          }

          print('✅ MEMORY CREATION: Pending invites created successfully');
        } else {
          // Non-group invites keep existing behavior for now (direct membership).
          // If you want all invited users (not just group) to be "pending",
          // move this block to also insert into memory_invites.
          print(
              '👥 MEMORY CREATION: Adding ${invitedUserIds.length} member(s) as contributors...');
          final joinedAt = DateTime.now().toUtc().toIso8601String();
          final rows = invitedUserIds
              .where((id) => id.trim().isNotEmpty && id != creatorId)
              .map((userId) => {
                    'memory_id': memoryId,
                    'user_id': userId,
                    'joined_at': joinedAt,
                  })
              .toList();

          if (rows.isNotEmpty) {
            await _supabase?.from('memory_contributors').insert(rows);
          }
          print('✅ MEMORY CREATION: Contributors added successfully');
        }
      } else {
        print('ℹ️ MEMORY CREATION: No additional members to add');
      }

      print(
          '🎉 MEMORY CREATION COMPLETE: Memory "$title" created successfully');
      print('   Final memory ID: $memoryId');

      return memoryId;
    } catch (e, stackTrace) {
      print('❌ MEMORY CREATION FAILED: Error creating memory');
      print('   Error: $e');
      print('   Stack trace: $stackTrace');
      return null;
    }
  }

  Future<DateTime> _getCategoryDuration(
      String categoryId, String duration) async {
    // TODO: implement real duration mapping; placeholder retained
    return DateTime.now().add(const Duration(hours: 12));
  }

  Future<Map<String, dynamic>?> updateMemoryLocation(String memoryId) async {
    try {
      print('📍 UPDATE LOCATION: Fetching location for memory: $memoryId');

      final locationData = await LocationService.getLocationData();
      if (locationData == null) {
        print('❌ UPDATE LOCATION: Failed to get location data');
        return null;
      }

      final locationName = locationData['location_name'] as String?;
      print('✅ UPDATE LOCATION: Got location_name: "$locationName"');

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
