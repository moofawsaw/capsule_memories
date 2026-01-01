import 'package:flutter/services.dart';
import '../../../core/app_export.dart';
import '../models/memory_share_options_model.dart';
import '../../../services/friends_service.dart';
import '../../../services/groups_service.dart';
import '../../../services/supabase_service.dart';

final memoryShareOptionsNotifierProvider =
    StateNotifierProvider<MemoryShareOptionsNotifier, MemoryShareOptionsModel>(
  (ref) => MemoryShareOptionsNotifier(),
);

class MemoryShareOptionsNotifier
    extends StateNotifier<MemoryShareOptionsModel> {
  MemoryShareOptionsNotifier() : super(const MemoryShareOptionsModel());

  final _friendsService = FriendsService();
  final _supabase = SupabaseService.instance.client;

  Future<void> initialize(String memoryId, String memoryName) async {
    state = state.copyWith(
      memoryId: memoryId,
      memoryName: memoryName,
      isLoading: true,
    );

    try {
      // Fetch memory details to get invite code and QR code URL
      final memoryResponse = await _supabase
          ?.from('memories')
          .select('invite_code, qr_code_url')
          .eq('id', memoryId)
          .single();

      final inviteCode = memoryResponse?['invite_code'] as String?;
      final qrCodeUrl = memoryResponse?['qr_code_url'] as String?;

      // Fetch friends and groups concurrently
      final results = await Future.wait([
        _friendsService.getUserFriends(),
        GroupsService.fetchUserGroups(),
      ]);

      state = state.copyWith(
        inviteCode: inviteCode,
        qrCodeUrl: qrCodeUrl,
        friends: results[0],
        groups: results[1],
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error initializing share options: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  void toggleFriendSelection(String friendId) {
    final selected = Set<String>.from(state.selectedFriends);
    if (selected.contains(friendId)) {
      selected.remove(friendId);
    } else {
      selected.add(friendId);
    }
    state = state.copyWith(selectedFriends: selected);
  }

  void toggleGroupSelection(String groupId) {
    final selected = Set<String>.from(state.selectedGroups);
    if (selected.contains(groupId)) {
      selected.remove(groupId);
    } else {
      selected.add(groupId);
    }
    state = state.copyWith(selectedGroups: selected);
  }

  void updateFriendSearchQuery(String query) {
    state = state.copyWith(friendSearchQuery: query);
  }

  Future<void> copyLinkToClipboard(BuildContext context) async {
    if (state.inviteCode == null) return;

    final link = 'https://capapp.co/join/memory/${state.inviteCode}';
    await Clipboard.setData(ClipboardData(text: link));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invite link copied to clipboard!'),
          backgroundColor: Color(0xFF9C27B0),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> sendInvites(BuildContext context) async {
    if (state.selectedFriends.isEmpty && state.selectedGroups.isEmpty) {
      return;
    }

    state = state.copyWith(isSendingInvites: true);

    try {
      final currentUserId = _supabase?.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get all user IDs from selected friends and groups
      final Set<String> allUserIds = Set.from(state.selectedFriends);

      // Get members from selected groups
      for (final groupId in state.selectedGroups) {
        final members = await GroupsService.fetchGroupMembers(groupId);
        allUserIds.addAll(
          members
              .map((m) => m['id'] as String)
              .where((id) => id != currentUserId),
        );
      }

      // Remove current user if somehow included
      allUserIds.remove(currentUserId);

      if (allUserIds.isEmpty) {
        throw Exception('No valid users to invite');
      }

      // Add users as memory contributors
      final contributorInserts = allUserIds
          .map((userId) => {
                'memory_id': state.memoryId,
                'user_id': userId,
              })
          .toList();

      await _supabase?.from('memory_contributors').insert(contributorInserts);

      state = state.copyWith(isSendingInvites: false);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invites sent to ${allUserIds.length} ${allUserIds.length == 1 ? 'person' : 'people'}!',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate back after successful invite
        Future.delayed(Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      debugPrint('Error sending invites: $e');
      state = state.copyWith(isSendingInvites: false);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send invites. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
