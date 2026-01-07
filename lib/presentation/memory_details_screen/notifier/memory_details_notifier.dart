import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/app_export.dart';
import '../../../services/avatar_helper_service.dart';
import '../../../services/friends_service.dart';
import '../../../services/location_service.dart';
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

  MemoryDetailsNotifier(MemoryDetailsState state, {required this.ref})
      : super(state);

  /// Load memory data from Supabase
  Future<void> loadMemoryData(String memoryId) async {
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

      // Get current user ID
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'User not authenticated',
        );
        return;
      }

      // Fetch memory data with creator info, location, AND category
      final memoryResponse = await client
          .from('memories')
          .select(
              'id, title, invite_code, visibility, creator_id, state, location_name, location_lat, location_lng, category_id')
          .eq('id', memoryId)
          .single();

      // Check if current user is the creator
      final creatorId = memoryResponse['creator_id'] as String;
      final isCreator = creatorId == currentUserId;

      // Fetch memory contributors with user profiles
      final contributorsResponse = await client
          .from('memory_contributors')
          .select(
              'id, user_id, joined_at, user_profiles(id, display_name, username, avatar_url)')
          .eq('memory_id', memoryId);

      // Convert contributors to MemberModel list
      final members = (contributorsResponse as List).map((contributor) {
        final userProfile =
            contributor['user_profiles'] as Map<String, dynamic>;
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

      // Get member user IDs
      final memberUserIds = (contributorsResponse)
          .map((c) =>
              (c['user_profiles'] as Map<String, dynamic>)['id'] as String)
          .toSet();

      // Initialize controllers
      final titleController = TextEditingController();
      final inviteLinkController = TextEditingController();
      final searchController = TextEditingController();
      final locationController = TextEditingController();

      titleController.text = memoryResponse['title'] as String? ?? '';
      inviteLinkController.text =
          memoryResponse['invite_code'] as String? ?? '';
      locationController.text =
          memoryResponse['location_name'] as String? ?? '';

      // NEW: Get current category info
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

      state = state.copyWith(
        titleController: titleController,
        inviteLinkController: inviteLinkController,
        searchController: searchController,
        locationController: locationController,
        isPublic: (memoryResponse['visibility'] as String?) == 'public',
        isCreator: isCreator,
        memoryId: memoryId,
        isLoading: false,
        locationName: memoryResponse['location_name'] as String?,
        locationLat: memoryResponse['location_lat'] as double?,
        locationLng: memoryResponse['location_lng'] as double?,
        // NEW: Set current category
        selectedCategoryId: currentCategoryId,
        selectedCategoryName: currentCategoryName,
        memberUserIds: memberUserIds,
        memoryDetailsModel: state.memoryDetailsModel?.copyWith(
          title: memoryResponse['title'] as String? ?? '',
          inviteLink: memoryResponse['invite_code'] as String? ?? '',
          isPublic: (memoryResponse['visibility'] as String?) == 'public',
          members: members,
        ),
      );

      // Load friends list for inviting
      await _loadFriendsList();

      // NEW: Load categories for selection
      await _loadCategories();
    } catch (e) {
      print('❌ Error loading memory data: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load memory data: ${e.toString()}',
      );
    }
  }

  /// NEW: Load available memory categories
  Future<void> _loadCategories() async {
    state = state.copyWith(isLoadingCategories: true);

    try {
      final client = SupabaseService.instance.client;
      if (client == null) throw Exception('Database connection not available');

      // Fetch all active categories ordered by display_order
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

  /// Load current user's friends list
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

  /// Filter friends based on search query
  void filterFriends(String query) {
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

  /// Invite a friend to the memory
  Future<void> inviteFriendToMemory(String friendUserId) async {
    if (state.memoryId == null) return;

    state = state.copyWith(isInviting: true);

    try {
      final client = SupabaseService.instance.client;
      if (client == null) throw Exception('Database connection not available');

      // Add friend as memory contributor
      await client.from('memory_contributors').insert({
        'memory_id': state.memoryId,
        'user_id': friendUserId,
      });

      // Update member user IDs
      final updatedMemberIds = Set<String>.from(state.memberUserIds)
        ..add(friendUserId);

      state = state.copyWith(
        isInviting: false,
        memberUserIds: updatedMemberIds,
        showSuccessMessage: true,
        successMessage: 'Friend invited successfully',
      );

      // Reset success message
      Future.delayed(Duration(milliseconds: 2000), () {
        if (mounted) {
          state = state.copyWith(
            showSuccessMessage: false,
            successMessage: null,
          );
        }
      });

      // Reload memory data to refresh members list
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

  /// NEW: Remove a member from the memory
  Future<void> removeMember(String memberUserId) async {
    if (!state.isCreator || state.memoryId == null) return;

    // Prevent removing the creator
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
        Future.delayed(Duration(milliseconds: 2000), () {
          if (mounted) {
            state = state.copyWith(
              showSuccessMessage: false,
              successMessage: null,
            );
          }
        });
        return;
      }
    } catch (e) {
      print('❌ Error checking creator: $e');
    }

    try {
      // Delete from memory_contributors table
      await client
          .from('memory_contributors')
          .delete()
          .eq('memory_id', state.memoryId!)
          .eq('user_id', memberUserId);

      // Update member user IDs
      final updatedMemberIds = Set<String>.from(state.memberUserIds)
        ..remove(memberUserId);

      state = state.copyWith(
        memberUserIds: updatedMemberIds,
        showSuccessMessage: true,
        successMessage: 'Member removed successfully',
      );

      // Reset success message
      Future.delayed(Duration(milliseconds: 2000), () {
        if (mounted) {
          state = state.copyWith(
            showSuccessMessage: false,
            successMessage: null,
          );
        }
      });

      // Reload memory data to refresh members list
      if (state.memoryId != null) {
        await loadMemoryData(state.memoryId!);
      }
    } catch (e) {
      print('❌ Error removing member: $e');
      state = state.copyWith(
        showSuccessMessage: true,
        successMessage: 'Failed to remove member',
      );

      Future.delayed(Duration(milliseconds: 2000), () {
        if (mounted) {
          state = state.copyWith(
            showSuccessMessage: false,
            successMessage: null,
          );
        }
      });
    }
  }

  /// NEW: Update selected category
  void updateCategory(String categoryId, String categoryName) {
    if (!state.isCreator) return;

    state = state.copyWith(
      selectedCategoryId: categoryId,
      selectedCategoryName: categoryName,
    );
  }

  void updateVisibility(bool isPublic) {
    if (!state.isCreator) return;

    state = state.copyWith(
      isPublic: isPublic,
      memoryDetailsModel: state.memoryDetailsModel?.copyWith(
        isPublic: isPublic,
      ),
    );
  }

  void copyInviteLink() {
    final inviteLink = state.inviteLinkController?.text ?? '';
    if (inviteLink.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: inviteLink));
      state = state.copyWith(
        showSuccessMessage: true,
        successMessage: 'Invite link copied to clipboard',
      );

      // Reset success message after showing
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          state = state.copyWith(
            showSuccessMessage: false,
            successMessage: null,
          );
        }
      });
    }
  }

  void updateTitle(String title) {
    if (!state.isCreator) return;

    state = state.copyWith(
      memoryDetailsModel: state.memoryDetailsModel?.copyWith(
        title: title,
      ),
    );
  }

  /// NEW: Fetch current location
  Future<void> fetchCurrentLocation() async {
    if (!state.isCreator) return;

    state = state.copyWith(isFetchingLocation: true);

    try {
      // Add timeout wrapper to prevent infinite loading
      final locationData = await Future.any([
        LocationService.getLocationData(),
        Future.delayed(
          const Duration(seconds: 15),
          () => null,
        ),
      ]);

      if (locationData != null) {
        // CRITICAL: LocationService.getLocationData() already returns properly formatted location_name
        // Format: "City, State" (e.g., "Toronto, ON" or "Dallas, TX")
        // This matches the exact same process used during story creation
        final newLocationName = locationData['location_name'] as String?;

        // Update both state and controller
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
        // Handle null response (timeout or permission denied)
        state = state.copyWith(
          isFetchingLocation: false,
          showSuccessMessage: true,
          successMessage:
              'Could not get location. Check permissions or try again.',
        );
      }

      // Reset success message after showing
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          state = state.copyWith(
            showSuccessMessage: false,
            successMessage: null,
          );
        }
      });
    } catch (e) {
      print('❌ Error fetching location: $e');
      // CRITICAL: Always clear loading state on error
      state = state.copyWith(
        isFetchingLocation: false,
        showSuccessMessage: true,
        successMessage: 'Failed to get location',
      );

      // Reset success message
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          state = state.copyWith(
            showSuccessMessage: false,
            successMessage: null,
          );
        }
      });
    }
  }

  /// NEW: Update location manually
  void updateLocationManually(String locationText) {
    if (!state.isCreator) return;

    state = state.copyWith(
      locationName: locationText,
    );
  }

  Future<bool> saveMemory() async {
    if (!state.isCreator) return false;

    state = state.copyWith(isSaving: true);

    try {
      final client = SupabaseService.instance.client;
      if (client == null || state.memoryId == null) {
        throw Exception('Database connection not available');
      }

      // Update memory in database including location and category
      await client.from('memories').update({
        'title': state.titleController?.text ?? '',
        'visibility': state.isPublic ? 'public' : 'private',
        'location_name': state.locationController?.text ?? state.locationName,
        'location_lat': state.locationLat,
        'location_lng': state.locationLng,
        // NEW: Update category
        'category_id': state.selectedCategoryId,
      }).eq('id', state.memoryId!);

      state = state.copyWith(
        isSaving: false,
        showSuccessMessage: true,
        successMessage: 'Memory saved successfully',
      );

      // Reset success message after showing
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          state = state.copyWith(
            showSuccessMessage: false,
            successMessage: null,
          );
        }
      });

      // Return success to trigger bottom sheet close and dashboard refresh
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
      // Simulate share operation
      await Future.delayed(Duration(seconds: 1));

      state = state.copyWith(
        isSharing: false,
        showSuccessMessage: true,
        successMessage: 'Memory shared successfully',
      );

      // Reset success message after showing
      Future.delayed(Duration(milliseconds: 2000), () {
        if (mounted) {
          state = state.copyWith(
            showSuccessMessage: false,
            successMessage: null,
          );
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

  /// NEW: Show QR Code bottom sheet for memory sharing
  Future<void> showQRCodeBottomSheet(BuildContext context) async {
    if (state.memoryId == null) return;

    try {
      final client = SupabaseService.instance.client;
      if (client == null) return;

      // CRITICAL FIX: Fetch memory with explicit qr_code_url field to match timeline approach
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

      // CRITICAL FIX: Enhanced debug logging matching timeline approach
      print('🔍 QR MODAL DEBUG: Memory details fetched');
      print('   - Memory ID: ${state.memoryId}');
      print('   - Title: $memoryTitle');
      print('   - Invite Code: $inviteCode');
      print('   - QR Code URL: $qrCodeUrl');
      print('   - QR Code URL Type: ${qrCodeUrl.runtimeType}');
      print('   - Is QR URL null: ${qrCodeUrl == null}');
      print('   - Is QR URL empty: ${qrCodeUrl == ""}');

      if (inviteCode == null || memoryTitle == null) {
        print('❌ Missing invite code or title');
        return;
      }

      // Show QR code modal with memory details
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
                    // Close button
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

                    // Memory Title
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

                    // CRITICAL FIX: QR Code with proper null handling matching timeline approach
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
                                if (loadingProgress == null) {
                                  print(
                                      '✅ QR Code image loaded successfully in modal');
                                  return child;
                                }
                                print(
                                    '⏳ QR Code loading in modal: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
                                return SizedBox(
                                  width: 200.fSize,
                                  height: 200.fSize,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          appTheme.deep_purple_A100),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                print(
                                    '❌ QR Code image failed to load in modal: $error');
                                print('❌ Stack trace: $stackTrace');
                                return Container(
                                  width: 200.fSize,
                                  height: 200.fSize,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 48.h,
                                        color: Colors.red.shade400,
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        'QR Code\nUnavailable',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: appTheme.gray_900,
                                          fontSize: 12.fSize,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          : Container(
                              width: 200.fSize,
                              height: 200.fSize,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.qr_code,
                                    size: 80.h,
                                    color: appTheme.gray_900.withAlpha(128),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'QR Code\nNot Generated',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: appTheme.gray_900,
                                      fontSize: 12.fSize,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    SizedBox(height: 16.h),

                    // Invite Code
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

                    // Memory Details Section
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
                          // Category
                          _buildDetailRow(
                            icon: Icons.category_outlined,
                            label: 'Category',
                            value: categoryName,
                          ),
                          SizedBox(height: 12.h),

                          // Location
                          _buildDetailRow(
                            icon: Icons.location_on_outlined,
                            label: 'Location',
                            value: locationName ?? 'No location set',
                          ),
                          SizedBox(height: 12.h),

                          // Members Count
                          _buildDetailRow(
                            icon: Icons.group_outlined,
                            label: 'Members',
                            value:
                                '$contributorCount ${contributorCount == 1 ? 'member' : 'members'}',
                          ),
                          SizedBox(height: 12.h),

                          // Date Created
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

                    // Share Button
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

      Future.delayed(Duration(milliseconds: 2000), () {
        if (mounted) {
          state = state.copyWith(
            showSuccessMessage: false,
            successMessage: null,
          );
        }
      });
    }
  }

  /// Helper method to build detail rows
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: appTheme.blue_gray_300,
          size: 18.h,
        ),
        SizedBox(width: 8.h),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                    .copyWith(
                  color: appTheme.blue_gray_300,
                ),
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

  /// Helper method to format date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  /// NEW: Share memory using native share dialog
  Future<void> shareMemoryNative() async {
    if (state.memoryId == null) return;

    try {
      final client = SupabaseService.instance.client;
      if (client == null) return;

      // Fetch memory details for sharing
      final memoryResponse = await client
          .from('memories')
          .select('id, title, invite_code')
          .eq('id', state.memoryId!)
          .single();

      final inviteCode = memoryResponse['invite_code'] as String?;
      final memoryTitle = memoryResponse['title'] as String?;

      if (inviteCode == null || memoryTitle == null) return;

      // Build join URL
      final joinUrl = 'https://capapp.co/join/memory/$inviteCode';

      // Share using native share dialog
      await Share.share(
        'Join my Capsule memory: $memoryTitle\n\n$joinUrl',
        subject: 'Join $memoryTitle on Capsule',
      );

      state = state.copyWith(
        showSuccessMessage: true,
        successMessage: 'Share dialog opened',
      );

      Future.delayed(Duration(milliseconds: 1500), () {
        if (mounted) {
          state = state.copyWith(
            showSuccessMessage: false,
            successMessage: null,
          );
        }
      });
    } catch (e) {
      print('❌ Error sharing memory: $e');
      state = state.copyWith(
        showSuccessMessage: true,
        successMessage: 'Failed to share memory',
      );

      Future.delayed(Duration(milliseconds: 2000), () {
        if (mounted) {
          state = state.copyWith(
            showSuccessMessage: false,
            successMessage: null,
          );
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
