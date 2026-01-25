import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_export.dart';
import '../../services/supabase_service.dart';
import '../../services/feed_service.dart';

class StoryActionsSheet {
  static Future<void> show({
    required BuildContext context,
    required String storyId,
    required String memoryId,
    required String ownerUserId,
    required String mediaUrl,
    required String caption,
    required bool isVideo,
    String? deepLink,
  }) async {
    // ✅ Your SupabaseService.client is nullable in this codebase
    final SupabaseClient? client = SupabaseService.instance.client;
    if (client == null) return; // safety: app not initialized yet

    final String? currentUserId = client.auth.currentUser?.id;
    final bool canDelete =
        currentUserId != null && currentUserId == ownerUserId;

    HapticFeedback.selectionClick();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            color: appTheme.gray_900_01,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: appTheme.gray_900_02),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionTile(
                icon: Icons.ios_share,
                label: 'Share',
                onTap: () async {
                  Navigator.pop(ctx);

                  try {
                    final feedService = FeedService();
                    final storyData =
                    await feedService.fetchStoryDetails(storyId);

                    final shareCode =
                    storyData?['share_code'] as String?;
                    final shareIdentifier =
                        shareCode ?? storyId;

                    if (shareIdentifier.isEmpty) {
                      _toast(context, 'Unable to share story');
                      return;
                    }

                    final shareUrl =
                        'https://share.capapp.co/$shareIdentifier';
                    await Share.share(shareUrl);
                  } catch (_) {
                    if (!context.mounted) return;
                    _toast(context, 'Failed to share story');
                  }
                },
              ),
              if (canDelete) ...[
                const SizedBox(height: 6),
                _ActionTile(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  isDestructive: true,
                  onTap: () async {
                    Navigator.pop(ctx);

                    final bool? confirm =
                    await _confirmDelete(context);
                    if (confirm != true) return;

                    try {
                      await _deleteStory(
                        client: client,
                        storyId: storyId,
                      );
                      _toast(context, 'Deleted');
                    } catch (_) {
                      _toast(context, 'Delete failed');
                    }
                  },
                ),
              ],
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.close,
                label: 'Cancel',
                color: appTheme.blue_gray_300,
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _deleteStory({
    required SupabaseClient client,
    required String storyId,
  }) async {
    // 1) fetch paths (if they exist)
    final story = await client
        .from('stories')
        .select('media_path, thumb_path')
        .eq('id', storyId)
        .single();

    final String? mediaPath = story['media_path'] as String?;
    final String? thumbPath = story['thumb_path'] as String?;

    // 2) delete row
    await client.from('stories').delete().eq('id', storyId);

    // 3) delete objects (bucket name may differ in your project)
    final storage = client.storage.from('stories');

    if (mediaPath != null && mediaPath.isNotEmpty) {
      await storage.remove([mediaPath]);
    }
    if (thumbPath != null && thumbPath.isNotEmpty) {
      await storage.remove([thumbPath]);
    }
  }

  static Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete story?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color resolvedColor = color ??
        (isDestructive ? appTheme.red_500 : appTheme.gray_50);

    return ListTile(
      dense: true,
      leading: Icon(icon, color: resolvedColor),
      title: Text(
        label,
        style: TextStyleHelper.instance.title16BoldPlusJakartaSans
            .copyWith(color: resolvedColor),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}