import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_export.dart';
import '../../core/utils/memory_nav_args.dart';
import '../../services/notification_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/storage_utils.dart';
import '../../widgets/custom_button.dart';

class MemoryInvitationScreen extends ConsumerStatefulWidget {
  final String? memoryId;
  final String? inviteCode;

  MemoryInvitationScreen({Key? key, this.memoryId, this.inviteCode})
      : super(key: key);

  @override
  MemoryInvitationScreenState createState() => MemoryInvitationScreenState();
}

class MemoryInvitationScreenState
    extends ConsumerState<MemoryInvitationScreen> {
  Map<String, dynamic>? _memoryData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // CRITICAL FIX: Fetch memory details after widget is built to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMemoryDetails();
    });
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
      try {
        final contributorsResponse = await SupabaseService.instance.client
            ?.from('memory_contributors')
            .select('user_profiles(avatar_url)')
            .eq('memory_id', resolvedMemoryId)
            .limit(12);

        final raw = (contributorsResponse as List?) ?? const [];
        final urls = <String>[];
        for (final row in raw) {
          if (row is! Map) continue;
          final profile = row['user_profiles'];
          if (profile is! Map) continue;
          final avatarRaw = profile['avatar_url'] as String?;
          final resolved = StorageUtils.resolveAvatarUrl(avatarRaw);
          if (resolved != null && resolved.trim().isNotEmpty) {
            urls.add(resolved.trim());
          }
        }
        contributorAvatars = urls;
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
          'is_already_member': isAlreadyMember,
        };
        _isLoading = false;
      });
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

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: titleColor,
            size: 18.h,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Memory Invitation',
          style: TextStyleHelper.instance.title16BoldPlusJakartaSans.copyWith(
            color: titleColor,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 16.h),
          child: _buildContent(context),
        ),
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
    final creator = _memoryData!['user_profiles'] as Map<String, dynamic>?;
    final memoryTitle = _memoryData!['title'] as String? ?? 'Untitled Memory';
    final inviteCode = _memoryData!['invite_code'] as String? ?? '';
    final membersCount = _memoryData!['contributor_count'] as int? ?? 0;
    final storiesCount = _memoryData!['stories_count'] as int? ?? 0;
    final status = _memoryData!['state'] as String? ?? 'open';
    final creatorName = creator?['display_name'] as String? ??
        creator?['username'] as String? ??
        'Unknown';
    final creatorAvatar = creator?['avatar_url'] as String?;
    final contributorAvatars =
        (_memoryData!['contributor_avatars'] as List?)?.whereType<String>().toList() ??
            const <String>[];
    final isAlreadyMember = _memoryData!['is_already_member'] == true;

    // Invite URL (used for share). Prefer share domain for iOS Universal Links.
    final inviteUrl = 'https://share.capapp.co/join/memory/$inviteCode';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildMemoryTitle(memoryTitle),
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
        _buildCreatorProfile(
          creatorName,
          creatorAvatar,
        ),
        SizedBox(height: 22.h),
        _buildMembersAvatarsRow(contributorAvatars, membersCount),
        SizedBox(height: 18.h),
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
  Widget _buildMemoryTitle(String title) {
    final titleColor = appTheme.gray_50;
    return Text(
      title,
      style:
          TextStyleHelper.instance.headline24ExtraBoldPlusJakartaSans.copyWith(
        color: titleColor,
      ),
      textAlign: TextAlign.center,
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
  Widget _buildCreatorProfile(String name, String? imageUrl) {
    final titleColor = appTheme.gray_50;
    final secondary = appTheme.blue_gray_300;

    final resolvedAvatar = StorageUtils.resolveAvatarUrl(imageUrl);

    return Column(
      children: [
        CircleAvatar(
          radius: 32.h,
          backgroundImage: resolvedAvatar != null && resolvedAvatar.isNotEmpty
              ? CachedNetworkImageProvider(resolvedAvatar)
              : null,
          backgroundColor: appTheme.blue_gray_900_02,
          child: resolvedAvatar == null || resolvedAvatar.isEmpty
              ? Icon(
                  Icons.person,
                  size: 32.h,
                  color: titleColor,
                )
              : null,
        ),
        SizedBox(height: 12.h),
        Text(
          name,
          style: TextStyleHelper.instance.title18BoldPlusJakartaSans.copyWith(
            color: titleColor,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'Creator',
          style: TextStyleHelper.instance.body14RegularPlusJakartaSans.copyWith(
            color: secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMembersAvatarsRow(List<String> avatars, int membersCount) {
    final titleColor = appTheme.gray_50;
    final secondary = appTheme.blue_gray_300;

    final visible = avatars.take(6).toList();
    final remaining = (membersCount - visible.length).clamp(0, 9999);

    return Column(
      children: [
        if (visible.isNotEmpty)
          SizedBox(
            height: 34.h,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: List.generate(visible.length, (i) {
                  final left = i * 18.h;
                  final url = visible[i];
                  return Positioned(
                    left: left,
                    child: Container(
                      width: 34.h,
                      height: 34.h,
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
                            child: Icon(Icons.person, color: titleColor, size: 18.h),
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
