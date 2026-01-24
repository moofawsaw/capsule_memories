import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_export.dart';
import '../../services/supabase_service.dart';

class MemoryActionsSheet {
  static Future<void> show({
    required BuildContext context,
    required String memoryId,
    required String ownerUserId,
    required String title,
    required String visibility,
    Future<void> Function()? onDeleted,
    Future<void> Function(bool isPublic)? onVisibilityChanged,
  }) async {
    final SupabaseClient? client = SupabaseService.instance.client;
    if (client == null) return;

    final String? currentUserId = client.auth.currentUser?.id;
    final bool canEdit =
        currentUserId != null && currentUserId == ownerUserId.trim();

    bool isPublic = (visibility.trim().toLowerCase() != 'private');

    HapticFeedback.selectionClick();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (ctx, setState) {
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
                          final invite = await _fetchInviteCode(
                            client: client,
                            memoryId: memoryId,
                          );
                          if (invite == null || invite.isEmpty) {
                            _toast(context, 'Unable to share memory');
                            return;
                          }

                          final shareUrl =
                              'https://capapp.co/join/memory/$invite';
                          await Share.share(
                            'Join my Capsule memory: $title\n\n$shareUrl',
                            subject: 'Join $title on Capsule',
                          );
                        } catch (_) {
                          if (!context.mounted) return;
                          _toast(context, 'Failed to share memory');
                        }
                      },
                    ),
                    if (canEdit) ...[
                      const SizedBox(height: 6),
                      _ToggleTile(
                        icon: isPublic
                            ? Icons.public
                            : Icons.lock_outline,
                        label: isPublic ? 'Public' : 'Private',
                        value: isPublic,
                        onChanged: (next) async {
                          setState(() => isPublic = next);
                          try {
                            await client.from('memories').update({
                              'visibility': next ? 'public' : 'private',
                            }).eq('id', memoryId);

                            await onVisibilityChanged?.call(next);
                          } catch (_) {
                            // revert UI if update failed
                            setState(() => isPublic = !next);
                            _toast(context, 'Failed to update visibility');
                          }
                        },
                      ),
                      const SizedBox(height: 6),
                      _ActionTile(
                        icon: Icons.delete_outline,
                        label: 'Delete',
                        isDestructive: true,
                        onTap: () async {
                          Navigator.pop(ctx);

                          final bool? confirm = await _confirmDelete(context);
                          if (confirm != true) return;

                          try {
                            await _deleteMemory(
                              client: client,
                              memoryId: memoryId,
                            );
                            _toast(context, 'Deleted');
                            await onDeleted?.call();
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
                      onTap: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  static Future<String?> _fetchInviteCode({
    required SupabaseClient client,
    required String memoryId,
  }) async {
    final row = await client
        .from('memories')
        .select('invite_code')
        .eq('id', memoryId)
        .maybeSingle();
    return row?['invite_code'] as String?;
  }

  /// HARD DELETE
  /// Deletes: reactions (via story ids) -> stories -> memory_contributors -> memories
  static Future<void> _deleteMemory({
    required SupabaseClient client,
    required String memoryId,
  }) async {
    final safeId = memoryId.trim();
    if (safeId.isEmpty) throw Exception('Invalid memory id');

    // 1) Get story ids for this memory
    List<String> storyIds = [];
    try {
      final storiesResp =
          await client.from('stories').select('id').eq('memory_id', safeId);

      storyIds = (storiesResp as List)
          .map((r) => r['id'] as String?)
          .whereType<String>()
          .toList();
    } catch (_) {
      // continue
    }

    // 2) Delete reactions for those stories (if reactions.story_id exists)
    if (storyIds.isNotEmpty) {
      try {
        await client.from('reactions').delete().inFilter('story_id', storyIds);
      } catch (_) {
        // continue
      }
    }

    // 3) Delete stories
    await client.from('stories').delete().eq('memory_id', safeId);

    // 4) Delete contributors
    await client.from('memory_contributors').delete().eq('memory_id', safeId);

    // 5) Delete memory row
    await client.from('memories').delete().eq('id', safeId);
  }

  static Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete memory?'),
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
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final Color color =
        isDestructive ? Colors.redAccent : appTheme.white_A700;

    return ListTile(
      dense: true,
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: appTheme.gray_900_02.withAlpha(40),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: appTheme.white_A700),
        title: Text(label, style: TextStyle(color: appTheme.white_A700)),
        trailing: Switch.adaptive(
          value: value,
          activeColor: appTheme.deep_purple_A100,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

