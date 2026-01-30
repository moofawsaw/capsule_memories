import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/app_export.dart';
import '../../../services/avatar_helper_service.dart';
import '../../../services/friends_service.dart';
import '../../../services/memory_service.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/custom_button.dart';
import '../models/memory_details_model.dart';

part 'memory_details_state.dart';

final memoryDetailsNotifier = StateNotifierProvider.autoDispose<
    MemoryDetailsNotifier, MemoryDetailsState>(
      (ref) => MemoryDetailsNotifier(
    MemoryDetailsState(
      memoryDetailsModel: MemoryDetailsModel(),
    ),
    ref: ref,
  ),
);

class MemoryDetailsNotifier extends StateNotifier<MemoryDetailsState> {
  final Ref ref;
  final FriendsService _friendsService = FriendsService();
  final MemoryService _memoryService = MemoryService();

  MemoryDetailsNotifier(MemoryDetailsState state, {required this.ref})
      : super(state);

  bool _isValidUuid(String? value) {
    if (value == null) return false;
    final v = value.trim();
    if (v.isEmpty) return false;
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(v);
  }

  Future<void> loadMemoryData(String memoryId) async {
    if (!_isValidUuid(memoryId)) {
      print('❌ loadMemoryData blocked: invalid memoryId="$memoryId"');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load memory data: invalid memory id',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final client = SupabaseService.instance.client;
      if (client == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Database connection not available',
        );
        return;
      }

      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'User not authenticated',
        );
        return;
      }

      final memoryResponse = await client
          .from('memories')
          .select(
          'id, title, invite_code, visibility, creator_id, state, location_name, location_lat, location_lng, category_id, duration, start_time, end_time')
          .eq('id', memoryId)
          .single();

      final creatorId = memoryResponse['creator_id'] as String;
      final isCreator = creatorId == currentUserId;

      final rawState = (memoryResponse['state'] as String?) ?? 'open';
      final memoryState = rawState.toLowerCase().trim(); // 'open' / 'sealed'

      final contributorsResponse = await client
          .from('memory_contributors')
          .select(
          'id, user_id, joined_at, user_profiles(id, display_name, username, avatar_url)')
          .eq('memory_id', memoryId);

      final members = (contributorsResponse as List).map((contributor) {
        final userProfile = contributor['user_profiles'] as Map<String, dynamic>;
        final userId = userProfile['id'] as String;

        return MemberModel(
          name: userProfile['display_name'] as String? ??
              userProfile['username'] as String? ??
              'Unknown',
          profileImagePath: AvatarHelperService.getAvatarUrl(
            userProfile['avatar_url'] as String?,
          ),
          role: userId == creatorId ? 'Creator' : 'Member',
          isCreator: userId == creatorId,
          userId: userId,
        );
      }).toList();

      final memberUserIds = (contributorsResponse)
          .map((c) =>
      (c['user_profiles'] as Map<String, dynamic>)['id'] as String)
          .toSet();

      final titleController = TextEditingController();
      final inviteLinkController = TextEditingController();
      final searchController = TextEditingController();
      final locationController = TextEditingController();

      titleController.text = memoryResponse['title'] as String? ?? '';
      inviteLinkController.text = memoryResponse['invite_code'] as String? ?? '';
      locationController.text = memoryResponse['location_name'] as String? ?? '';

      final currentCategoryId = memoryResponse['category_id'] as String?;
      String? currentCategoryName;

      if (currentCategoryId != null) {
        try {
          final categoryResponse = await client
              .from('memory_categories')
              .select('name')
              .eq('id', currentCategoryId)
              .single();
          currentCategoryName = categoryResponse['name'] as String?;
        } catch (e) {
          print('⚠️ Could not fetch category name: $e');
        }
      }

      final duration = memoryResponse['duration'] as String?;
      final startTimeStr = memoryResponse['start_time'] as String?;
      final endTimeStr = memoryResponse['end_time'] as String?;

      DateTime? parsedStartTime;
      DateTime? parsedEndTime;

      if (startTimeStr != null) parsedStartTime = DateTime.parse(startTimeStr);
      if (endTimeStr != null) parsedEndTime = DateTime.parse(endTimeStr);

      state = state.copyWith(
        titleController: titleController,
        inviteLinkController: inviteLinkController,
        searchController: searchController,
        locationController: locationController,
        isPublic: (memoryResponse['visibility'] as String?) == 'public',
        isCreator: isCreator,
        memoryId: memoryId,
        isLoading: false,
        memoryState: memoryState,
        locationName: memoryResponse['location_name'] as String?,
        locationLat: memoryResponse['location_lat'] as double?,
        locationLng: memoryResponse['location_lng'] as double?,
        selectedCategoryId: currentCategoryId,
        selectedCategoryName: currentCategoryName,
        selectedDuration: duration,
        startTime: parsedStartTime,
        endTime: parsedEndTime,
        memberUserIds: memberUserIds,
        memoryDetailsModel: state.memoryDetailsModel?.copyWith(
          title: memoryResponse['title'] as String? ?? '',
          inviteLink: memoryResponse['invite_code'] as String? ?? '',
          isPublic: (memoryResponse['visibility'] as String?) == 'public',
          members: members,
        ),
      );

      // Only load friends/invite data if NOT sealed (sealed = view-only members)
      if (!state.isSealed) {
        await _loadFriendsList();
      }

      await _loadCategories();
    } catch (e) {
      print('❌ Error loading memory data: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load memory data: ${e.toString()}',
      );
    }
  }

  Future<void> _loadCategories() async {
    state = state.copyWith(isLoadingCategories: true);

    try {
      final client = SupabaseService.instance.client;
      if (client == null) throw Exception('Database connection not available');

      final categoriesResponse = await client
          .from('memory_categories')
          .select('id, name, icon_name, icon_url, tagline')
          .eq('is_active', true)
          .order('display_order', ascending: true);

      state = state.copyWith(
        categories: List<Map<String, dynamic>>.from(categoriesResponse),
        isLoadingCategories: false,
      );
    } catch (e) {
      print('❌ Error loading categories: $e');
      state = state.copyWith(isLoadingCategories: false);
    }
  }

  Future<void> _loadFriendsList() async {
    state = state.copyWith(isLoadingFriends: true);

    try {
      final friends = await _friendsService.getUserFriends();
      state = state.copyWith(
        friendsList: friends,
        filteredFriendsList: friends,
        isLoadingFriends: false,
      );
    } catch (e) {
      print('❌ Error loading friends: $e');
      state = state.copyWith(isLoadingFriends: false);
    }
  }

  void filterFriends(String query) {
    // Sealed = no invites
    if (state.isSealed) return;

    if (query.isEmpty) {
      state = state.copyWith(filteredFriendsList: state.friendsList);
      return;
    }

    final filtered = state.friendsList.where((friend) {
      final name =
      (friend['display_name'] ?? friend['username'] ?? '').toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    state = state.copyWith(filteredFriendsList: filtered);
  }

  Future<void> inviteFriendToMemory(String friendUserId) async {
    if (state.isSealed) return;
    if (state.memoryId == null) return;
    if (!state.isCreator) return;

    state = state.copyWith(isInviting: true);

    try {
      final client = SupabaseService.instance.client;
      if (client == null) throw Exception('Database connection not available');

      await client.from('memory_contributors').insert({
        'memory_id': state.memoryId,
        'user_id': friendUserId,
      });

      final updatedMemberIds = Set<String>.from(state.memberUserIds)
        ..add(friendUserId);

      state = state.copyWith(
        isInviting: false,
        memberUserIds: updatedMemberIds,
        showSuccessMessage: true,
        successMessage: 'Friend invited successfully',
      );

      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          state =
              state.copyWith(showSuccessMessage: false, successMessage: null);
        }
      });

      if (state.memoryId != null) {
        await loadMemoryData(state.memoryId!);
      }
    } catch (e) {
      print('❌ Error inviting friend: $e');
      state = state.copyWith(
        isInviting: false,
        showSuccessMessage: true,
        successMessage: 'Failed to invite friend',
      );
    }
  }

  Future<void> removeMember(String memberUserId) async {
    // Sealed = no member changes
    if (state.isSealed) return;
    if (!state.isCreator || state.memoryId == null) return;

    final client = SupabaseService.instance.client;
    if (client == null) return;

    try {
      final creatorId = (await client
          .from('memories')
          .select('creator_id')
          .eq('id', state.memoryId!)
          .single())['creator_id'] as String;

      if (memberUserId == creatorId) {
        state = state.copyWith(
          showSuccessMessage: true,
          successMessage: 'Cannot remove the creator',
        );
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            state =
                state.copyWith(showSuccessMessage: false, successMessage: null);
          }
        });
        return;
      }
    } catch (e) {
      print('❌ Error checking creator: $e');
    }

    try {
      await client
          .from('memory_contributors')
          .delete()
          .eq('memory_id', state.memoryId!)
          .eq('user_id', memberUserId);

      final updatedMemberIds = Set<String>.from(state.memberUserIds)
        ..remove(memberUserId);

      state = state.copyWith(
        memberUserIds: updatedMemberIds,
        showSuccessMessage: true,
        successMessage: 'Member removed successfully',
      );

      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          state =
              state.copyWith(showSuccessMessage: false, successMessage: null);
        }
      });

      if (state.memoryId != null) {
        await loadMemoryData(state.memoryId!);
      }
    } catch (e) {
      print('❌ Error removing member: $e');
      state = state.copyWith(
        showSuccessMessage: true,
        successMessage: 'Failed to remove member',
      );

      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          state =
              state.copyWith(showSuccessMessage: false, successMessage: null);
        }
      });
    }
  }

  void updateMemoryDuration(String newDuration) {
    if (!state.isCreator) return;
    if (state.isSealed) return;

    final now = DateTime.now();
    DateTime newEndTime;

    switch (newDuration) {
      case '12_hours':
        newEndTime = now.add(const Duration(hours: 12));
        break;
      case '24_hours':
        newEndTime = now.add(const Duration(hours: 24));
        break;
      case '3_days':
        newEndTime = now.add(const Duration(days: 3));
        break;
      default:
        newEndTime = now.add(const Duration(hours: 12));
    }

    state = state.copyWith(
      selectedDuration: newDuration,
      endTime: newEndTime,
    );
  }

  void updateCategory(String categoryId, String categoryName) {
    if (!state.isCreator) return;
    // Category allowed even when sealed
    state = state.copyWith(
      selectedCategoryId: categoryId,
      selectedCategoryName: categoryName,
    );
  }

  void updateVisibility(bool isPublic) {
    if (!state.isCreator) return;
    if (state.isSealed) return;

    state = state.copyWith(
      isPublic: isPublic,
      memoryDetailsModel: state.memoryDetailsModel?.copyWith(isPublic: isPublic),
    );
  }

  void copyInviteLink() {
    // Invite link UI is removed when sealed, but keep guard anyway.
    if (state.isSealed) return;

    final inviteLink = state.inviteLinkController?.text ?? '';
    if (inviteLink.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: inviteLink));
      state = state.copyWith(
        showSuccessMessage: true,
        successMessage: 'Invite link copied to clipboard',
      );

      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          state =
              state.copyWith(showSuccessMessage: false, successMessage: null);
        }
      });
    }
  }

  void updateTitle(String title) {
    if (!state.isCreator) return;
    state = state.copyWith(
      memoryDetailsModel: state.memoryDetailsModel?.copyWith(title: title),
    );
  }

  Future<void> fetchCurrentLocation() async {
    // Location allowed even when sealed
    if (!state.isCreator) return;

    state = state.copyWith(isFetchingLocation: true);

    try {
      final locationData = await Future.any([
        _memoryService.updateMemoryLocation(state.memoryId ?? ''),
        Future.delayed(const Duration(seconds: 15), () => null),
      ]);

      if (locationData != null) {
        final newLocationName = locationData['location_name'] as String?;
        state.locationController?.text = newLocationName ?? '';

        state = state.copyWith(
          isFetchingLocation: false,
          locationName: newLocationName,
          locationLat: locationData['latitude'] as double?,
          locationLng: locationData['longitude'] as double?,
          showSuccessMessage: true,
          successMessage: 'Location updated',
        );
      } else {
        state = state.copyWith(
          isFetchingLocation: false,
          showSuccessMessage: true,
          successMessage: 'Could not get location. Check permissions or try again.',
        );
      }

      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          state =
              state.copyWith(showSuccessMessage: false, successMessage: null);
        }
      });
    } catch (e) {
      print('❌ Error fetching location: $e');
      state = state.copyWith(
        isFetchingLocation: false,
        showSuccessMessage: true,
        successMessage: 'Failed to get location',
      );

      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          state =
              state.copyWith(showSuccessMessage: false, successMessage: null);
        }
      });
    }
  }

  void updateLocationManually(String locationText) {
    if (!state.isCreator) return;
    state = state.copyWith(locationName: locationText);
  }

  Future<bool> saveMemory() async {
    if (!state.isCreator) return false;

    state = state.copyWith(isSaving: true);

    try {
      final client = SupabaseService.instance.client;
      if (client == null || state.memoryId == null) {
        throw Exception('Database connection not available');
      }

      // ✅ Sealed: ONLY allow title, location, category
      if (state.isSealed) {
        await client.from('memories').update({
          'title': state.titleController?.text ?? '',
          'location_name': state.locationController?.text ?? state.locationName,
          'location_lat': state.locationLat,
          'location_lng': state.locationLng,
          'category_id': state.selectedCategoryId,
        }).eq('id', state.memoryId!);
      } else {
        // Open: existing behavior
        await client.from('memories').update({
          'title': state.titleController?.text ?? '',
          'visibility': state.isPublic ? 'public' : 'private',
          'location_name': state.locationController?.text ?? state.locationName,
          'location_lat': state.locationLat,
          'location_lng': state.locationLng,
          'category_id': state.selectedCategoryId,
          'duration': state.selectedDuration,
          'end_time': state.endTime?.toIso8601String(),
        }).eq('id', state.memoryId!);
      }

      state = state.copyWith(
        isSaving: false,
        showSuccessMessage: true,
        successMessage: 'Memory saved successfully',
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          state =
              state.copyWith(showSuccessMessage: false, successMessage: null);
        }
      });

      return true;
    } catch (e) {
      print('❌ Error saving memory: $e');
      state = state.copyWith(
        isSaving: false,
        showSuccessMessage: true,
        successMessage: 'Failed to save memory',
      );
      return false;
    }
  }

  Future<void> shareMemory() async {
    state = state.copyWith(isSharing: true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      state = state.copyWith(
        isSharing: false,
        showSuccessMessage: true,
        successMessage: 'Memory shared successfully',
      );

      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          state =
              state.copyWith(showSuccessMessage: false, successMessage: null);
        }
      });
    } catch (e) {
      state = state.copyWith(
        isSharing: false,
        showSuccessMessage: true,
        successMessage: 'Failed to share memory',
      );
    }
  }

  Future<void> showQRCodeBottomSheet(BuildContext context) async {
    if (!_isValidUuid(state.memoryId)) return;

    try {
      final client = SupabaseService.instance.client;
      if (client == null) return;

      final memoryResponse = await client
          .from('memories')
          .select(
          'id, title, invite_code, qr_code_url, created_at, location_name, contributor_count, category_id, memory_categories(name)')
          .eq('id', state.memoryId!)
          .single();

      final inviteCode = memoryResponse['invite_code'] as String?;
      final memoryTitle = memoryResponse['title'] as String?;
      final qrCodeUrl = memoryResponse['qr_code_url'] as String?;
      final createdAt = memoryResponse['created_at'] as String?;
      final locationName = memoryResponse['location_name'] as String?;
      final contributorCount = memoryResponse['contributor_count'] as int? ?? 0;
      final categoryData =
      memoryResponse['memory_categories'] as Map<String, dynamic>?;
      final categoryName = categoryData?['name'] as String? ?? 'Uncategorized';

      if (inviteCode == null || memoryTitle == null) return;

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (dialogContext) => Dialog(
            backgroundColor: appTheme.gray_900_02,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.h),
            ),
            child: Container(
              constraints: BoxConstraints(maxWidth: 90.w.fSize),
              padding: EdgeInsets.all(20.h),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(dialogContext),
                        child: Icon(
                          Icons.close,
                          color: appTheme.gray_50,
                          size: 24.h,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      memoryTitle,
                      style: TextStyleHelper.instance.title20BoldPlusJakartaSans
                          .copyWith(
                        color: appTheme.gray_50,
                        fontSize: 18.fSize,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 20.h),
                    Container(
                      padding: EdgeInsets.all(16.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.h),
                      ),
                      child: (qrCodeUrl != null && qrCodeUrl.isNotEmpty)
                          ? Image.network(
                        qrCodeUrl,
                        width: 200.fSize,
                        height: 200.fSize,
                        fit: BoxFit.contain,
                        loadingBuilder:
                            (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            width: 200.fSize,
                            height: 200.fSize,
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  appTheme.deep_purple_A100,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return SizedBox(
                            width: 200.fSize,
                            height: 200.fSize,
                            child: Center(
                              child: Icon(
                                Icons.error_outline,
                                size: 48.h,
                                color: Colors.red.shade400,
                              ),
                            ),
                          );
                        },
                      )
                          : SizedBox(
                        width: 200.fSize,
                        height: 200.fSize,
                        child: Center(
                          child: Icon(
                            Icons.qr_code,
                            size: 80.h,
                            color: appTheme.gray_900.withAlpha(128),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.h,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: appTheme.gray_900,
                        borderRadius: BorderRadius.circular(8.h),
                        border: Border.all(
                          color: appTheme.blue_gray_300.withAlpha(77),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Code: $inviteCode',
                        style: TextStyleHelper
                            .instance.body14MediumPlusJakartaSans
                            .copyWith(
                          color: appTheme.gray_50,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.h),
                      decoration: BoxDecoration(
                        color: appTheme.gray_900,
                        borderRadius: BorderRadius.circular(8.h),
                        border: Border.all(
                          color: appTheme.blue_gray_300.withAlpha(77),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            icon: Icons.category_outlined,
                            label: 'Category',
                            value: categoryName,
                          ),
                          SizedBox(height: 12.h),
                          _buildDetailRow(
                            icon: Icons.location_on_outlined,
                            label: 'Location',
                            value: locationName ?? 'No location set',
                          ),
                          SizedBox(height: 12.h),
                          _buildDetailRow(
                            icon: Icons.group_outlined,
                            label: 'Members',
                            value:
                            '$contributorCount ${contributorCount == 1 ? 'member' : 'members'}',
                          ),
                          SizedBox(height: 12.h),
                          _buildDetailRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Created',
                            value: createdAt != null
                                ? _formatDate(DateTime.parse(createdAt))
                                : 'Unknown',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'Share Memory',
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          shareMemoryNative();
                        },
                        buttonStyle: CustomButtonStyle.fillDark,
                        buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error showing QR code: $e');
      state = state.copyWith(
        showSuccessMessage: true,
        successMessage: 'Failed to load QR code',
      );

      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          state =
              state.copyWith(showSuccessMessage: false, successMessage: null);
        }
      });
    }
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: appTheme.blue_gray_300, size: 18.h),
        SizedBox(width: 8.h),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyleHelper.instance.body14MediumPlusJakartaSans
                    .copyWith(
                  color: appTheme.gray_50,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> shareMemoryNative() async {
    if (!_isValidUuid(state.memoryId) || state.isSharing) return;

    state = state.copyWith(isSharing: true);

    try {
      final client = SupabaseService.instance.client;
      if (client == null) {
        state = state.copyWith(isSharing: false);
        return;
      }

      final memoryResponse = await client
          .from('memories')
          .select('id, title, invite_code')
          .eq('id', state.memoryId!)
          .single();

      final inviteCode = memoryResponse['invite_code'] as String?;
      final memoryTitle = memoryResponse['title'] as String?;

      if (inviteCode == null || memoryTitle == null) {
        state = state.copyWith(isSharing: false);
        return;
      }

      final joinUrl = 'https://share.capapp.co/join/memory/$inviteCode';

      await Share.share(
        'Join my Capsule memory: $memoryTitle\n\n$joinUrl',
        subject: 'Join $memoryTitle on Capsule',
      );

      state = state.copyWith(
        isSharing: false,
        showSuccessMessage: true,
        successMessage: 'Share dialog opened',
      );

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          state =
              state.copyWith(showSuccessMessage: false, successMessage: null);
        }
      });
    } catch (e) {
      print('❌ Error sharing memory: $e');
      state = state.copyWith(
        isSharing: false,
        showSuccessMessage: true,
        successMessage: 'Failed to share memory',
      );

      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          state =
              state.copyWith(showSuccessMessage: false, successMessage: null);
        }
      });
    }
  }

  @override
  void dispose() {
    state.titleController?.dispose();
    state.inviteLinkController?.dispose();
    state.searchController?.dispose();
    state.locationController?.dispose();
    super.dispose();
  }
}
