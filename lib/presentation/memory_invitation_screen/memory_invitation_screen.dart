import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../core/app_export.dart';
import '../../core/utils/memory_nav_args.dart';
import '../../services/notification_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/storage_utils.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_image_view.dart';

class MemoryInvitationScreen extends ConsumerStatefulWidget {
  final String? memoryId;
  final String? inviteCode;

  MemoryInvitationScreen({Key? key, this.memoryId, this.inviteCode})
      : super(key: key);

  @override
  MemoryInvitationScreenState createState() => MemoryInvitationScreenState();
}

class MemoryMemberPreview {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final bool isCreator;

  const MemoryMemberPreview({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.isCreator,
  });
}

class MemoryInvitationScreenState
    extends ConsumerState<MemoryInvitationScreen> {
  Map<String, dynamic>? _memoryData;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _countdownTimer;
  final ValueNotifier<DateTime> _now = ValueNotifier<DateTime>(DateTime.now());

  @override
  void initState() {
    super.initState();
    // CRITICAL FIX: Fetch memory details after widget is built to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMemoryDetails();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _now.dispose();
    super.dispose();
  }

  void _startCountdownTimerIfNeeded(DateTime? expiresAt) {
    _countdownTimer?.cancel();
    if (expiresAt == null) return;

    // Update "now" frequently so the countdown feels alive.
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final n = DateTime.now();
      _now.value = n;
      if (!n.isBefore(expiresAt)) {
        // Stop ticking once expired.
        _countdownTimer?.cancel();
      }
    });
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  String _formatDate(DateTime? dt, {bool withTime = true}) {
    if (dt == null) return '—';
    try {
      final local = dt.toLocal();
      return withTime
          ? DateFormat('MMM d, yyyy • h:mm a').format(local)
          : DateFormat.yMMMd().format(local);
    } catch (_) {
      return '—';
    }
  }

  String _formatCountdown(Duration d) {
    if (d.inSeconds <= 0) return '0s';

    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    }
    if (d.inHours > 0) {
      return '${d.inHours}h ${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    }
    if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${d.inSeconds}s';
  }

  /// Fetch memory details from Supabase
  Future<void> _fetchMemoryDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Accept either:
      // - a memory UUID (memoryId) OR
      // - an invite code (inviteCode) from /join/memory/<code>
      String? memoryId = widget.memoryId;
      String? inviteCode = widget.inviteCode;

      // Only try ModalRoute if constructor parameter is null
      final routeArgs = ModalRoute.of(context)?.settings.arguments;
      if ((memoryId == null || memoryId.isEmpty) &&
          (inviteCode == null || inviteCode.isEmpty)) {
        if (routeArgs is String) {
          memoryId = routeArgs;
        } else if (routeArgs is Map) {
          final m = Map<String, dynamic>.from(routeArgs);
          memoryId = (m['memoryId'] as String?)?.trim();
          inviteCode = (m['inviteCode'] as String?)?.trim();
        }
      }

      final memoryIdValue = (memoryId ?? '').trim();
      final inviteCodeValue = (inviteCode ?? '').trim();
      final hasMemoryId = memoryIdValue.isNotEmpty;
      final hasInviteCode = inviteCodeValue.isNotEmpty;

      if (!hasMemoryId && !hasInviteCode) {
        setState(() {
          _errorMessage = 'No invite code provided';
          _isLoading = false;
        });
        return;
      }

      print('🔍 MEMORY INVITATION: Fetching details');
      if (hasMemoryId) {
        print('   - memoryId: $memoryId');
      }
      if (hasInviteCode) {
        print('   - inviteCode: $inviteCode');
      }

      // Fetch memory with creator details
      final query = SupabaseService.instance.client?.from('memories').select('''
            id,
            title,
            invite_code,
            contributor_count,
            state,
            creator_id,
            category_id,
            created_at,
            expires_at,
            sealed_at,
            memory_categories(icon_name, icon_url),
            user_profiles!memories_creator_id_fkey(
              id,
              username,
              display_name,
              avatar_url
            )
          ''');

      final response = hasMemoryId
          ? await query?.eq('id', memoryIdValue).maybeSingle()
          : await query?.eq('invite_code', inviteCodeValue).maybeSingle();

      if (response == null) {
        setState(() {
          _errorMessage = 'Invitation not found';
          _isLoading = false;
        });
        return;
      }

      final resolvedMemoryId = response['id'] as String?;
      if (resolvedMemoryId == null || resolvedMemoryId.isEmpty) {
        setState(() {
          _errorMessage = 'Invitation not found';
          _isLoading = false;
        });
        return;
      }

      // Fetch stories count separately
      final storiesResponse = await SupabaseService.instance.client
          ?.from('stories')
          .select('id')
          .eq('memory_id', resolvedMemoryId);

      final storiesCount = storiesResponse?.length ?? 0;

      // Fetch contributor avatars (for preview row)
      List<String> contributorAvatars = const [];
      List<MemoryMemberPreview> memberPreviews = const [];
      try {
        final contributorsResponse = await SupabaseService.instance.client
            ?.from('memory_contributors')
            .select('user_id, user_profiles(id,display_name,username,avatar_url)')
            .eq('memory_id', resolvedMemoryId)
            .limit(50);

        final raw = (contributorsResponse as List?) ?? const [];
        final urls = <String>[];
        final members = <MemoryMemberPreview>[];
        final seenUserIds = <String>{};

        final creatorId = (response['creator_id'] as String?)?.trim() ?? '';
        final creatorProfile = response['user_profiles'] as Map<String, dynamic>?;
        final creatorName = (creatorProfile?['display_name'] as String?)?.trim().isNotEmpty == true
            ? (creatorProfile?['display_name'] as String).trim()
            : ((creatorProfile?['username'] as String?)?.trim().isNotEmpty == true
                ? (creatorProfile?['username'] as String).trim()
                : 'Creator');
        final creatorAvatarRaw = creatorProfile?['avatar_url'] as String?;
        final creatorAvatarResolved = StorageUtils.resolveAvatarUrl(creatorAvatarRaw) ?? creatorAvatarRaw;
        if (creatorId.isNotEmpty) {
          seenUserIds.add(creatorId);
          members.add(
            MemoryMemberPreview(
              userId: creatorId,
              displayName: creatorName,
              avatarUrl: creatorAvatarResolved,
              isCreator: true,
            ),
          );
        }

        for (final row in raw) {
          if (row is! Map) continue;
          final userId = (row['user_id'] as String?)?.trim();
          if (userId == null || userId.isEmpty) continue;
          if (seenUserIds.contains(userId)) continue;
          seenUserIds.add(userId);

          final profile = row['user_profiles'];
          String? name;
          String? avatarRaw;
          if (profile is Map) {
            name = (profile['display_name'] as String?)?.trim();
            name ??= (profile['username'] as String?)?.trim();
            avatarRaw = profile['avatar_url'] as String?;
          }

          final avatarResolved = StorageUtils.resolveAvatarUrl(avatarRaw) ?? avatarRaw;
          if (avatarResolved != null && avatarResolved.trim().isNotEmpty) {
            urls.add(avatarResolved.trim());
          }

          members.add(
            MemoryMemberPreview(
              userId: userId,
              displayName: (name == null || name.isEmpty) ? 'Member' : name,
              avatarUrl: avatarResolved,
              isCreator: false,
            ),
          );
        }
        contributorAvatars = urls;
        memberPreviews = members;
      } catch (_) {}

      // Check if current user is already in the memory (creator or contributor)
      var isAlreadyMember = false;
      try {
        final userId = SupabaseService.instance.client?.auth.currentUser?.id;
        final creatorId = (response['creator_id'] as String?)?.trim();

        if (userId != null && userId.isNotEmpty) {
          if (creatorId != null && creatorId.isNotEmpty && creatorId == userId) {
            isAlreadyMember = true;
          } else {
            final memberRow = await SupabaseService.instance.client
                ?.from('memory_contributors')
                .select('id')
                .eq('memory_id', resolvedMemoryId)
                .eq('user_id', userId)
                .maybeSingle();
            isAlreadyMember = memberRow != null;
          }
        }
      } catch (_) {}

      print('✅ MEMORY INVITATION: Successfully loaded memory data');
      print('   - Title: ${response['title']}');
      print('   - Invite Code: ${response['invite_code']}');
      print('   - Stories Count: $storiesCount');

      setState(() {
        _memoryData = {
          ...response,
          'stories_count': storiesCount,
          'contributor_avatars': contributorAvatars,
          'member_previews': memberPreviews,
          'is_already_member': isAlreadyMember,
        };
        _isLoading = false;
      });

      // Start countdown ticking after data loads.
      final sealedAt = _parseDate(response['sealed_at']);
      if (sealedAt == null) {
        _startCountdownTimerIfNeeded(_parseDate(response['expires_at']));
      }
    } catch (e) {
      print('❌ ERROR fetching memory details: $e');
      setState(() {
        _errorMessage = 'Failed to load memory details';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = appTheme.gray_900_02;
    final titleColor = appTheme.gray_50;
    final topInset = MediaQuery.of(context).padding.top;
    // Add extra breathing room above the modal header (especially on notched devices).
    final headerTop = topInset + 22.h;

    return Scaffold(
      backgroundColor: bg,
      // Modal-style overlay: full-screen content + close (X) in top-right.
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.h, headerTop + 62.h, 20.h, 16.h),
              child: _buildContent(context),
            ),
          ),
          Positioned(
            top: headerTop,
            left: 26.h,
            right: 26.h,
            child: Row(
              children: [
                SizedBox(width: 40.h, height: 40.h),
                Expanded(
                  child: Center(
                    child: Text(
                      'Memory Invitation',
                      style: TextStyleHelper.instance.headline24ExtraBoldPlusJakartaSans
                          .copyWith(color: titleColor),
                    ),
                  ),
                ),
                SizedBox(
                  width: 40.h,
                  height: 40.h,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20.h),
                      onTap: () =>
                          Navigator.of(context, rootNavigator: true).maybePop(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: appTheme.gray_900_01.withAlpha(200),
                          borderRadius: BorderRadius.circular(20.h),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: titleColor,
                          size: 20.h,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final titleColor = appTheme.gray_50;

    // Show loading state
    if (_isLoading) {
      return SizedBox(
        height: 320.h,
        child: Center(
          child: CircularProgressIndicator(color: appTheme.deep_purple_A100),
        ),
      );
    }

    // Show error state
    if (_errorMessage != null || _memoryData == null) {
      return SizedBox(
        height: 320.h,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48.h, color: appTheme.colorFF3A3A),
              SizedBox(height: 16.h),
              Text(
                _errorMessage ?? 'Failed to load memory',
                style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                    .copyWith(color: titleColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Extract data
    final memoryTitle = _memoryData!['title'] as String? ?? 'Untitled Memory';
    final inviteCode = _memoryData!['invite_code'] as String? ?? '';
    final membersCount = _memoryData!['contributor_count'] as int? ?? 0;
    final storiesCount = _memoryData!['stories_count'] as int? ?? 0;
    final status = _memoryData!['state'] as String? ?? 'open';
    final createdAt = _parseDate(_memoryData!['created_at']);
    final expiresAt = _parseDate(_memoryData!['expires_at']);
    final sealedAt = _parseDate(_memoryData!['sealed_at']);
    final contributorAvatars =
        (_memoryData!['contributor_avatars'] as List?)?.whereType<String>().toList() ??
            const <String>[];
    final memberPreviews =
        (_memoryData!['member_previews'] as List?)?.whereType<MemoryMemberPreview>().toList() ??
            const <MemoryMemberPreview>[];
    final isAlreadyMember = _memoryData!['is_already_member'] == true;

    // Category icon (best-effort)
    String? categoryIcon;
    try {
      final rawCategory = _memoryData!['memory_categories'];
      Map<String, dynamic>? category;
      if (rawCategory is Map) {
        category = Map<String, dynamic>.from(rawCategory);
      } else if (rawCategory is List && rawCategory.isNotEmpty && rawCategory.first is Map) {
        category = Map<String, dynamic>.from(rawCategory.first as Map);
      }

      final iconName = (category?['icon_name'] as String?)?.trim();
      final iconUrl = (category?['icon_url'] as String?)?.trim();

      if (iconName != null && iconName.isNotEmpty) {
        categoryIcon = StorageUtils.resolveMemoryCategoryIconUrl(iconName).trim();
      } else if (iconUrl != null && iconUrl.isNotEmpty) {
        final resolved = StorageUtils.resolveMemoryCategoryIconUrl(iconUrl).trim();
        categoryIcon = resolved.isNotEmpty ? resolved : iconUrl;
      }
    } catch (_) {}

    // Invite URL (used for share). Prefer share domain for iOS Universal Links.
    final inviteUrl = 'https://share.capapp.co/join/memory/$inviteCode';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildMemoryTitle(memoryTitle, categoryIcon: categoryIcon),
        SizedBox(height: 12.h),
        _buildInvitationMessage(
          isAlreadyMember
              ? "You're already in this memory."
              : "You've been invited to join this memory",
        ),
        if (isAlreadyMember) ...[
          SizedBox(height: 10.h),
          Text(
            'Share this link to invite friends.',
            style: TextStyleHelper.instance.body14RegularPlusJakartaSans.copyWith(
              color: appTheme.blue_gray_300,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        SizedBox(height: 28.h),
        // _buildCreatorProfile(
        //   creatorName,
        //   creatorAvatar,
        // ),
        SizedBox(height: 18.h),
        _buildTimeAndMembersCard(
          createdAt: createdAt,
          expiresAt: expiresAt,
          sealedAt: sealedAt,
          membersCount: membersCount,
          members: memberPreviews,
          fallbackAvatars: contributorAvatars,
        ),
        SizedBox(height: 20.h),
        _buildStatsRow(
          membersCount,
          storiesCount,
          status == 'open' ? 'Open' : 'Sealed',
        ),
        SizedBox(height: 40.h),
        _buildPrimaryActionButton(
          context,
          isAlreadyMember: isAlreadyMember,
          shareUrl: inviteUrl,
          memoryTitle: memoryTitle,
        ),
        SizedBox(height: 16.h),
        _buildHelperText(isAlreadyMember: isAlreadyMember),
        SizedBox(height: 20.h),
      ],
    );
  }

  /// Memory title
  Widget _buildMemoryTitle(String title, {String? categoryIcon}) {
    final titleColor = appTheme.gray_50;
    final icon = (categoryIcon ?? '').trim();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon.isNotEmpty) ...[
          Container(
            width: 26.h,
            height: 26.h,
            padding: EdgeInsets.all(4.h),
            decoration: BoxDecoration(
              color: appTheme.deep_purple_A100.withAlpha(26),
              borderRadius: BorderRadius.circular(8.h),
              border: Border.all(
                color: appTheme.blue_gray_900_02.withAlpha(90),
                width: 1,
              ),
            ),
            child: CustomImageView(
              imagePath: icon,
              fit: BoxFit.contain,
              enableCategoryIconResolution: true,
              placeholderWidget: Icon(
                Icons.category_outlined,
                size: 16.h,
                color: titleColor.withAlpha(180),
              ),
            ),
          ),
          SizedBox(width: 10.h),
        ],
        Flexible(
          child: Text(
            title,
            style: TextStyleHelper.instance.headline24ExtraBoldPlusJakartaSans
                .copyWith(color: titleColor),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Invitation message
  Widget _buildInvitationMessage(String message) {
    final secondary = appTheme.blue_gray_300;
    return Text(
      message,
      style: TextStyleHelper.instance.title16RegularPlusJakartaSans.copyWith(
        color: secondary,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Creator profile section
  // Widget _buildCreatorProfile(String name, String? imageUrl) {
  //   final titleColor = appTheme.gray_50;
  //   final secondary = appTheme.blue_gray_300;
  //
  //   final resolvedAvatar = StorageUtils.resolveAvatarUrl(imageUrl);
  //
  //   return Column(
  //     children: [
  //       CircleAvatar(
  //         radius: 32.h,
  //         backgroundImage: resolvedAvatar != null && resolvedAvatar.isNotEmpty
  //             ? CachedNetworkImageProvider(resolvedAvatar)
  //             : null,
  //         backgroundColor: appTheme.blue_gray_900_02,
  //         child: resolvedAvatar == null || resolvedAvatar.isEmpty
  //             ? Icon(
  //                 Icons.person,
  //                 size: 32.h,
  //                 color: titleColor,
  //               )
  //             : null,
  //       ),
  //       SizedBox(height: 12.h),
  //       Text(
  //         name,
  //         style: TextStyleHelper.instance.title18BoldPlusJakartaSans.copyWith(
  //           color: titleColor,
  //         ),
  //       ),
  //       SizedBox(height: 4.h),
  //       Text(
  //         'Creator',
  //         style: TextStyleHelper.instance.body14RegularPlusJakartaSans.copyWith(
  //           color: secondary,
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildMembersAvatarsRow(List<String> avatars, int membersCount) {
    final titleColor = appTheme.gray_50;
    final secondary = appTheme.blue_gray_300;

    final visible = avatars.take(6).toList();
    final remaining = (membersCount - visible.length).clamp(0, 9999);
    final avatarSize = 44.h;
    final overlap = 28.h;

    return Column(
      children: [
        if (visible.isNotEmpty)
          SizedBox(
            height: avatarSize,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: List.generate(visible.length, (i) {
                  final left = i * overlap;
                  final url = visible[i];
                  return Positioned(
                    left: left,
                    child: Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: appTheme.gray_900_02,
                          width: 2.h,
                        ),
                      ),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: appTheme.blue_gray_900_02,
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: appTheme.blue_gray_900_02,
                            child: Icon(
                              Icons.person,
                              color: titleColor,
                              size: 22.h,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        SizedBox(height: 10.h),
        Text(
          remaining > 0
              ? '$membersCount members • +$remaining more'
              : '$membersCount members',
          style: TextStyleHelper.instance.body14RegularPlusJakartaSans.copyWith(
            color: secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeAndMembersCard({
    required DateTime? createdAt,
    required DateTime? expiresAt,
    required DateTime? sealedAt,
    required int membersCount,
    required List<MemoryMemberPreview> members,
    required List<String> fallbackAvatars,
  }) {
    final titleColor = appTheme.gray_50;
    final secondary = appTheme.blue_gray_300;

    final bool isSealed = sealedAt != null;
    final bool hasExpiry = expiresAt != null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: appTheme.gray_900_01,
        borderRadius: BorderRadius.circular(14.h),
        border: Border.all(
          color: appTheme.blue_gray_900_02.withAlpha(90),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: titleColor.withAlpha(230), size: 18.h),
              SizedBox(width: 8.h),
              Text(
                'Memory info',
                style: TextStyleHelper.instance.body16MediumPlusJakartaSans
                    .copyWith(color: titleColor),
              ),
              Spacer(),
              if (hasExpiry)
                ValueListenableBuilder<DateTime>(
                  valueListenable: _now,
                  builder: (context, now, _) {
                    final expires = expiresAt;
                    final left = expires.difference(now);
                    final expired = left.inSeconds <= 0;

                    final label = isSealed
                        ? 'Sealed'
                        : (expired ? 'Expired' : 'Time left');
                    final value = isSealed
                        ? _formatDate(sealedAt, withTime: false)
                        : (expired ? '0s' : _formatCountdown(left));

                    final Color pillBg = expired || isSealed
                        ? appTheme.colorFF3A3A.withAlpha(28)
                        : appTheme.deep_purple_A100.withAlpha(26);
                    final Color pillFg = expired || isSealed
                        ? appTheme.colorFF3A3A
                        : appTheme.deep_purple_A100;

                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: pillBg,
                        borderRadius: BorderRadius.circular(999.h),
                        border: Border.all(color: pillFg.withAlpha(120), width: 1),
                      ),
                      child: Text(
                        '$label • $value',
                        style: TextStyleHelper.instance.body12BoldPlusJakartaSans
                            .copyWith(color: pillFg),
                      ),
                    );
                  },
                ),
            ],
          ),
          SizedBox(height: 12.h),
          _metaRow(
            icon: Icons.calendar_today_rounded,
            label: 'Created',
            value: _formatDate(createdAt),
            secondary: secondary,
            titleColor: titleColor,
          ),
          SizedBox(height: 8.h),
          _metaRow(
            icon: Icons.schedule_rounded,
            label: 'Expires',
            value: _formatDate(expiresAt),
            secondary: secondary,
            titleColor: titleColor,
          ),
          SizedBox(height: 14.h),
          Divider(color: appTheme.blue_gray_900_02.withAlpha(90), height: 1),
          SizedBox(height: 14.h),
          Row(
            children: [
              Text(
                'Members',
                style: TextStyleHelper.instance.body16MediumPlusJakartaSans
                    .copyWith(color: titleColor),
              ),
              Spacer(),
              Text(
                '$membersCount',
                style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                    .copyWith(color: secondary),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          if (members.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              separatorBuilder: (_, __) => SizedBox(height: 6.h),
              itemBuilder: (context, index) {
                final m = members[index];
                return _memberRow(m);
              },
            )
          else
            // Fallback to old avatar row if we couldn't load member profiles.
            _buildMembersAvatarsRow(fallbackAvatars, membersCount),
        ],
      ),
    );
  }

  Widget _metaRow({
    required IconData icon,
    required String label,
    required String value,
    required Color secondary,
    required Color titleColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: secondary, size: 16.h),
        SizedBox(width: 8.h),
        Text(
          label,
          style: TextStyleHelper.instance.body14RegularPlusJakartaSans
              .copyWith(color: secondary),
        ),
        SizedBox(width: 10.h),
        Expanded(
          child: Text(
            value,
            style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                .copyWith(color: titleColor.withAlpha(230)),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _memberRow(MemoryMemberPreview m) {
    final titleColor = appTheme.gray_50;
    final secondary = appTheme.blue_gray_300;
    final avatarUrl = (StorageUtils.resolveAvatarUrl(m.avatarUrl) ?? (m.avatarUrl ?? '')).trim();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 10.h),
      decoration: BoxDecoration(
        color: appTheme.gray_900_02.withAlpha(140),
        borderRadius: BorderRadius.circular(12.h),
        border: Border.all(color: appTheme.blue_gray_900_02.withAlpha(80), width: 1),
      ),
      child: Row(
        children: [
          ClipOval(
            child: avatarUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: avatarUrl,
                    width: 36.h,
                    height: 36.h,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 36.h,
                      height: 36.h,
                      color: appTheme.blue_gray_900_02,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 36.h,
                      height: 36.h,
                      color: appTheme.blue_gray_900_02,
                      child: Icon(Icons.person, color: titleColor, size: 18.h),
                    ),
                  )
                : Container(
                    width: 36.h,
                    height: 36.h,
                    color: appTheme.blue_gray_900_02,
                    child: Icon(Icons.person, color: titleColor, size: 18.h),
                  ),
          ),
          SizedBox(width: 12.h),
          Expanded(
            child: Text(
              m.displayName,
              style: TextStyleHelper.instance.body16MediumPlusJakartaSans
                  .copyWith(color: titleColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (m.isCreator) ...[
            SizedBox(width: 10.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 4.h),
              decoration: BoxDecoration(
                color: appTheme.deep_purple_A100.withAlpha(28),
                borderRadius: BorderRadius.circular(999.h),
                border: Border.all(
                  color: appTheme.deep_purple_A100.withAlpha(120),
                  width: 1,
                ),
              ),
              child: Text(
                'Creator',
                style: TextStyleHelper.instance.body12BoldPlusJakartaSans
                    .copyWith(color: appTheme.deep_purple_A100),
              ),
            ),
          ] else ...[
            Text(
              'Member',
              style: TextStyleHelper.instance.body12RegularPlusJakartaSans
                  .copyWith(color: secondary),
            ),
          ],
        ],
      ),
    );
  }

  /// Stats row (Members, Stories, Status)
  Widget _buildStatsRow(int members, int stories, String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(members.toString(), 'Members'),
        Container(
          width: 1.h,
          height: 40.h,
          color: appTheme.blue_gray_300.withAlpha(77),
        ),
        _buildStatItem(stories.toString(), 'Stories'),
        Container(
          width: 1.h,
          height: 40.h,
          color: appTheme.blue_gray_300.withAlpha(77),
        ),
        _buildStatItem(status, 'Status'),
      ],
    );
  }

  /// Individual stat item
  Widget _buildStatItem(String value, String label) {
    final titleColor = appTheme.gray_50;
    final secondary = appTheme.blue_gray_300;
    return Column(
      children: [
        Text(
          value,
          style: TextStyleHelper.instance.headline24ExtraBoldPlusJakartaSans
              .copyWith(
            color: titleColor,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyleHelper.instance.body14RegularPlusJakartaSans.copyWith(
            color: secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryActionButton(
    BuildContext context, {
    required bool isAlreadyMember,
    required String shareUrl,
    required String memoryTitle,
  }) {
    return CustomButton(
      text: isAlreadyMember ? 'Share' : 'Join Memory',
      onPressed: () => isAlreadyMember
          ? onTapShareMemory(context, shareUrl, memoryTitle)
          : onTapJoinMemory(context),
      // Match primary CTA width used elsewhere (Create Story / Cinema Mode, etc).
      width: double.maxFinite,
      buttonStyle: CustomButtonStyle.fillPrimary,
      buttonTextStyle: CustomButtonTextStyle.bodyMedium,
    );
  }

  /// Helper text at the bottom
  Widget _buildHelperText({required bool isAlreadyMember}) {
    final secondary = appTheme.blue_gray_300;
    return Text(
      isAlreadyMember
          ? 'You’re already a member — you can share this memory with others.'
          : "You'll be able to add your own stories",
      style: TextStyleHelper.instance.body14RegularPlusJakartaSans.copyWith(
        color: secondary,
      ),
      textAlign: TextAlign.center,
    );
  }

  void onTapShareMemory(
    BuildContext context,
    String shareUrl,
    String memoryTitle,
  ) {
    final url = shareUrl.trim();
    if (url.isEmpty) return;
    Share.share(
      url,
      subject: 'Join my memory: $memoryTitle',
    );
  }

  /// Navigates to user profile when the user card is tapped
  void onTapUserProfile(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appProfile);
  }

  /// Handles joining the memory invitation
  void onTapJoinMemory(BuildContext context) async {
    if (_memoryData == null) return;

    try {
      final memoryId = (_memoryData!['id'] as String?)?.trim();
      if (memoryId == null || memoryId.isEmpty) {
        throw Exception('Missing memory id');
      }

      final client = SupabaseService.instance.client;
      final userId = client?.auth.currentUser?.id;
      if (client == null || userId == null) {
        throw Exception('User not authenticated');
      }

      // ✅ IMPORTANT:
      // If the user has a pending invite row, accept it (this clears "pending mode"
      // and any DB trigger can add them to memory_contributors).
      // Otherwise, fall back to direct join by memory id.
      String? pendingInviteId;
      try {
        final inviteRow = await client
            .from('memory_invites')
            .select('id,status')
            .eq('memory_id', memoryId)
            .eq('user_id', userId)
            .eq('status', 'pending')
            .maybeSingle();

        pendingInviteId = (inviteRow?['id'] as String?)?.trim();
      } catch (_) {}

      if (pendingInviteId != null && pendingInviteId.isNotEmpty) {
        await NotificationService.instance.acceptMemoryInvite(pendingInviteId);
      } else {
        await NotificationService.instance.joinMemoryById(memoryId);
      }

      // Best-effort: ensure membership row exists before navigating, so the timeline
      // doesn't render "pending/non-member" due to eventual DB trigger timing.
      for (var attempt = 0; attempt < 4; attempt++) {
        try {
          final row = await client
              .from('memory_contributors')
              .select('id')
              .eq('memory_id', memoryId)
              .eq('user_id', userId)
              .maybeSingle();
          if (row != null) break;
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 200));
      }

      if (!context.mounted) return;

      // Close the invitation sheet and navigate to the timeline in member mode.
      Navigator.of(context).pop();
      NavigatorService.pushNamed(
        AppRoutes.appTimeline,
        arguments: MemoryNavArgs(memoryId: memoryId).toMap(),
      );
    } catch (e) {
      print('❌ ERROR joining memory: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join memory. Please try again.'),
          backgroundColor: appTheme.colorFF3A3A,
        ),
      );
    }
  }
}
