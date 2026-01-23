import 'dart:async';
import 'dart:math' as math;

import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';

import '../memory_feed_dashboard_screen/widgets/native_camera_recording_screen.dart';
import '../../core/app_export.dart';
import '../../services/friends_service.dart';
import '../../services/groups_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_image_view.dart';

class MemoryConfirmationScreen extends ConsumerStatefulWidget {
  const MemoryConfirmationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MemoryConfirmationScreen> createState() =>
      _MemoryConfirmationScreenState();
}

class _MemoryConfirmationScreenState
    extends ConsumerState<MemoryConfirmationScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  final List<ConfettiParticle> _particles = [];

  // Memory data
  String memoryId = '';
  String memoryName = '';
  String? qrCodeUrl;
  String? inviteCode;
  String? categoryIcon;
  DateTime? createdAt;
  String visibility = 'private';
  int memberCount = 1;
  DateTime? expiresAt;

  // ✅ NEW: group header data
  String? groupId;
  String? groupName;
  List<Map<String, dynamic>> _groupMembers = [];
  Set<String> _existingMemberUserIds = {};

  // Loading and error states
  bool _isLoadingDetails = false;
  String? _fetchError;

  // Timer for countdown
  Timer? _countdownTimer;
  Duration? _remainingTime;

  // Friends search and selection
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allFriends = [];
  List<Map<String, dynamic>> _filteredFriends = [];
  Set<String> _selectedFriendIds = {};
  bool _isLoadingFriends = true;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _generateConfetti();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _confettiController.forward();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMemoryData();
      _loadFriends();
    });
  }

  void _initializeMemoryData() async {
    final args =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      setState(() {
        memoryId = args['memory_id'] as String? ?? '';
        memoryName = args['memory_name'] as String? ?? '';
        categoryIcon = args['category_icon'] as String?;
        createdAt = DateTime.now();
        _isLoadingDetails = true;

        // ✅ optional if you pass these through route args
        groupId = args['group_id'] as String?;
        groupName = args['group_name'] as String?;
      });

      if (memoryId.isNotEmpty) {
        await _fetchMemoryDetails();
      } else {
        setState(() {
          _isLoadingDetails = false;
          _fetchError = 'Memory ID not provided';
        });
      }
    }
  }

  Future<void> _fetchMemoryDetails() async {
    try {
      final supabase = SupabaseService.instance.client;
      if (supabase == null) {
        setState(() {
          _isLoadingDetails = false;
          _fetchError = 'Database connection unavailable';
        });
        return;
      }

      final response = await supabase
          .from('memories')
          .select(
          'qr_code_url, invite_code, created_at, visibility, expires_at, contributor_count, creator_id, group_id')
          .eq('id', memoryId)
          .maybeSingle()
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );

      if (response == null) {
        setState(() {
          _isLoadingDetails = false;
          _fetchError = 'Memory details not yet available';
        });
        return;
      }

      DateTime parsedCreatedAt;
      DateTime parsedExpiresAt;

      if (response['created_at'] != null) {
        try {
          parsedCreatedAt = DateTime.parse(response['created_at'] as String);
        } catch (_) {
          parsedCreatedAt = DateTime.now();
        }
      } else {
        parsedCreatedAt = DateTime.now();
      }

      if (response['expires_at'] != null) {
        try {
          parsedExpiresAt = DateTime.parse(response['expires_at'] as String);
        } catch (_) {
          parsedExpiresAt = parsedCreatedAt.add(const Duration(hours: 12));
        }
      } else {
        parsedExpiresAt = parsedCreatedAt.add(const Duration(hours: 12));
      }

      final dbGroupId = response['group_id'] as String?;

      setState(() {
        qrCodeUrl = response['qr_code_url'] as String?;
        inviteCode = response['invite_code'] as String?;
        createdAt = parsedCreatedAt;
        visibility = response['visibility'] as String? ?? 'private';
        memberCount = (response['contributor_count'] as int?) ?? 1;
        expiresAt = parsedExpiresAt;
        _isLoadingDetails = false;
        _fetchError = null;

        // ✅ save groupId from DB if present
        if (dbGroupId != null && dbGroupId.trim().isNotEmpty) {
          groupId = dbGroupId.trim();
        }
      });

      if (expiresAt != null) _startCountdownTimer();

      // ✅ Load group header + members (avatars) and exclude them from invite list
      if (groupId != null && groupId!.isNotEmpty) {
        await _loadGroupHeaderAndMembers(groupId!);
      }
    } catch (_) {
      setState(() {
        _isLoadingDetails = false;
        _fetchError = 'Could not load all details';
      });
    }
  }

  Future<void> _loadGroupHeaderAndMembers(String gid) async {
    try {
      final supabase = SupabaseService.instance.client;
      if (supabase == null) return;

      // Fetch group name if needed
      if (groupName == null || groupName!.trim().isEmpty) {
        final g = await supabase
            .from('groups')
            .select('name')
            .eq('id', gid)
            .maybeSingle();
        if (g != null) {
          setState(() => groupName = (g['name'] as String?)?.trim());
        }
      }

      final members = await GroupsService.fetchGroupMembers(gid);

      final ids = <String>{};
      for (final m in members) {
        // GroupsService.fetchGroupMembers returns: { id, name, username, avatar, joined_at }
        final uid = (m['id'] ?? m['user_id'] ?? '').toString().trim();
        if (uid.isNotEmpty) ids.add(uid);
      }

      if (!mounted) return;

      setState(() {
        _groupMembers = members;
        _existingMemberUserIds = ids;
      });

      // Re-filter the friends list after we know member ids
      _filterFriends(_searchController.text);
    } catch (_) {
      // non-fatal
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _updateRemainingTime();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateRemainingTime();
      } else {
        timer.cancel();
      }
    });
  }

  void _updateRemainingTime() {
    if (expiresAt != null) {
      final now = DateTime.now();
      final remaining = expiresAt!.difference(now);
      setState(() {
        _remainingTime = remaining.isNegative ? Duration.zero : remaining;
      });
    }
  }

  String _formatCountdown(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoadingFriends = true);

    try {
      final friends = await FriendsService().getUserFriends();
      setState(() {
        _allFriends = friends;
        _filteredFriends = friends;
        _isLoadingFriends = false;
      });

      // Apply filter to exclude existing members (if already loaded)
      _filterFriends(_searchController.text);
    } catch (e) {
      setState(() => _isLoadingFriends = false);
    }
  }

  void _filterFriends(String query) {
    final memberIds = _existingMemberUserIds;

    setState(() {
      if (query.isEmpty) {
        _filteredFriends = _allFriends.where((f) {
          final fid = (f['id'] ?? '').toString().trim();
          return fid.isNotEmpty && !memberIds.contains(fid);
        }).toList();
      } else {
        final q = query.toLowerCase();
        _filteredFriends = _allFriends.where((friend) {
          final fid = (friend['id'] ?? '').toString().trim();
          if (fid.isEmpty || memberIds.contains(fid)) return false;

          final name = (friend['display_name'] as String? ?? '').toLowerCase();
          final username = (friend['username'] as String? ?? '').toLowerCase();
          return name.contains(q) || username.contains(q);
        }).toList();
      }

      // If someone is now a member, ensure they cannot remain selected
      _selectedFriendIds.removeWhere((id) => memberIds.contains(id));
    });
  }

  void _toggleFriendSelection(String friendId) {
    // safety: never allow selecting an existing group member
    if (_existingMemberUserIds.contains(friendId)) return;

    setState(() {
      if (_selectedFriendIds.contains(friendId)) {
        _selectedFriendIds.remove(friendId);
      } else {
        _selectedFriendIds.add(friendId);
      }
    });
  }

  Future<void> _sendInvites() async {
    if (_selectedFriendIds.isEmpty) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(color: appTheme.deep_purple_A100),
        ),
      );

      final currentUserId = SupabaseService.instance.client?.auth.currentUser?.id;

      for (final friendId in _selectedFriendIds) {
        await SupabaseService.instance.client?.from('memory_invites').insert({
          'memory_id': memoryId,
          'user_id': friendId,
          'invited_by': currentUserId,
        });
      }

      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invites sent successfully!'),
          backgroundColor: appTheme.deep_purple_A100,
        ),
      );

      setState(() => _selectedFriendIds.clear());
    } catch (_) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send invites'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _generateConfetti() {
    final random = math.Random();
    final colors = [
      appTheme.deep_purple_A100,
      appTheme.deep_purple_A200,
      Colors.amber,
      Colors.pink,
      Colors.cyan,
      Colors.orange,
    ];

    for (int i = 0; i < 50; i++) {
      _particles.add(
        ConfettiParticle(
          color: colors[random.nextInt(colors.length)],
          startX: random.nextDouble(),
          startY: -0.1,
          endY: 1.2 + random.nextDouble() * 0.3,
          rotation: random.nextDouble() * 4 * math.pi,
          size: 8.0 + random.nextDouble() * 8.0,
          drift: (random.nextDouble() - 0.5) * 0.3,
        ),
      );
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _countdownTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.gray_900_02,
      appBar: AppBar(
        backgroundColor: appTheme.gray_900_02,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: appTheme.gray_50),
            onPressed: () => NavigatorService.goBack(),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20.h),
                  child: ConstrainedBox(
                    constraints:
                    BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                appTheme.deep_purple_A100,
                                appTheme.deep_purple_A200,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12.h),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.check_circle,
                                  color: appTheme.gray_50, size: 48.h),
                              SizedBox(height: 16.h),
                              Text(
                                'Memory Created!',
                                style: TextStyleHelper
                                    .instance.title18BoldPlusJakartaSans
                                    .copyWith(color: appTheme.gray_50),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 20.h),

                        if (_isLoadingDetails)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16.h),
                            decoration: BoxDecoration(
                              color: appTheme.gray_900_01,
                              borderRadius: BorderRadius.circular(12.h),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20.h,
                                  height: 20.h,
                                  child: CircularProgressIndicator(
                                    color: appTheme.deep_purple_A100,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12.h),
                                Text(
                                  'Loading details...',
                                  style: TextStyleHelper
                                      .instance.body14RegularPlusJakartaSans
                                      .copyWith(color: appTheme.blue_gray_300),
                                ),
                              ],
                            ),
                          ),

                        if (_fetchError != null && !_isLoadingDetails)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12.h),
                            margin: EdgeInsets.only(bottom: 16.h),
                            decoration: BoxDecoration(
                              color: appTheme.colorFFD81E.withAlpha(51),
                              borderRadius: BorderRadius.circular(8.h),
                              border: Border.all(
                                color: appTheme.colorFFD81E.withAlpha(128),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: appTheme.colorFFD81E, size: 20.h),
                                SizedBox(width: 8.h),
                                Expanded(
                                  child: Text(
                                    _fetchError!,
                                    style: TextStyleHelper
                                        .instance.body12MediumPlusJakartaSans
                                        .copyWith(color: appTheme.gray_50),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Memory Details
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20.h),
                          decoration: BoxDecoration(
                            color: appTheme.gray_900_01,
                            borderRadius: BorderRadius.circular(12.h),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (categoryIcon != null &&
                                      categoryIcon!.trim().isNotEmpty &&
                                      categoryIcon != 'null' &&
                                      categoryIcon != 'undefined') ...[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8.h),
                                      child: CustomImageView(
                                        imagePath: categoryIcon!.trim(),
                                        height: 22.h,
                                        width: 22.h,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    SizedBox(width: 10.h),
                                  ],
                                  Expanded(
                                    child: Text(
                                      memoryName.isNotEmpty
                                          ? memoryName
                                          : 'New Memory',
                                      style: TextStyleHelper
                                          .instance.title18BoldPlusJakartaSans
                                          .copyWith(color: appTheme.gray_50),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.h),
                              Row(
                                children: [
                                  Icon(Icons.access_time,
                                      color: appTheme.blue_gray_300,
                                      size: 16.h),
                                  SizedBox(width: 8.h),
                                  Text(
                                    'Created ${createdAt != null ? _formatTimestamp(createdAt!) : 'just now'}',
                                    style: TextStyleHelper
                                        .instance.body14RegularPlusJakartaSans
                                        .copyWith(color: appTheme.blue_gray_300),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              Row(
                                children: [
                                  Icon(
                                    visibility == 'public'
                                        ? Icons.public
                                        : Icons.lock,
                                    color: visibility == 'public'
                                        ? Colors.green
                                        : appTheme.deep_purple_A100,
                                    size: 16.h,
                                  ),
                                  SizedBox(width: 8.h),
                                  Text(
                                    visibility == 'public'
                                        ? 'Public'
                                        : 'Private',
                                    style: TextStyleHelper
                                        .instance.body14RegularPlusJakartaSans
                                        .copyWith(color: appTheme.blue_gray_300),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),

                              // ✅ Replace memberCount row with group name + member avatars when group exists
                              if (groupId != null &&
                                  (groupName?.trim().isNotEmpty ?? false)) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(Icons.groups,
                                        color: appTheme.blue_gray_300,
                                        size: 16.h),
                                    SizedBox(width: 8.h),
                                    Expanded(
                                      child: Text(
                                        groupName!.trim(),
                                        style: TextStyleHelper.instance
                                            .body14RegularPlusJakartaSans
                                            .copyWith(
                                            color: appTheme.blue_gray_300),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10.h),
                                _buildMemberAvatarRow(
                                  members: _groupMembers,
                                  maxVisible: 6,
                                ),
                              ] else ...[
                                Row(
                                  children: [
                                    Icon(Icons.people,
                                        color: appTheme.blue_gray_300,
                                        size: 16.h),
                                    SizedBox(width: 8.h),
                                    Text(
                                      '$memberCount ${memberCount == 1 ? 'member' : 'members'}',
                                      style: TextStyleHelper.instance
                                          .body14RegularPlusJakartaSans
                                          .copyWith(
                                          color: appTheme.blue_gray_300),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        SizedBox(height: 20.h),

                        if (_remainingTime != null)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16.h),
                            decoration: BoxDecoration(
                              color: appTheme.gray_900_01,
                              borderRadius: BorderRadius.circular(12.h),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Posting Window Closes In',
                                  style: TextStyleHelper
                                      .instance.body14RegularPlusJakartaSans
                                      .copyWith(color: appTheme.blue_gray_300),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  _formatCountdown(_remainingTime!),
                                  style: TextStyleHelper
                                      .instance.headline24ExtraBoldPlusJakartaSans
                                      .copyWith(
                                      color: appTheme.deep_purple_A100),
                                ),
                              ],
                            ),
                          ),

                        SizedBox(height: 20.h),

                        // QR
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20.h),
                          decoration: BoxDecoration(
                            color: appTheme.gray_900_01,
                            borderRadius: BorderRadius.circular(12.h),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Scan to Join Memory',
                                style: TextStyleHelper
                                    .instance.title16MediumPlusJakartaSans
                                    .copyWith(color: appTheme.gray_50),
                              ),
                              SizedBox(height: 16.h),
                              if (qrCodeUrl != null && qrCodeUrl!.isNotEmpty)
                                Container(
                                  padding: EdgeInsets.all(16.h),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12.h),
                                  ),
                                  child: Image.network(
                                    qrCodeUrl!,
                                    width: 200.h,
                                    height: 200.h,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      return _buildLocalQRCode();
                                    },
                                  ),
                                )
                              else
                                _buildLocalQRCode(),
                              SizedBox(height: 16.h),
                              if (inviteCode != null)
                                Text(
                                  'Code: $inviteCode',
                                  style: TextStyleHelper
                                      .instance.body14RegularPlusJakartaSans
                                      .copyWith(
                                    color: appTheme.blue_gray_300,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              SizedBox(height: 16.h),
                              CustomButton(
                                text: 'Share QR Code',
                                buttonStyle: CustomButtonStyle.outlinePrimary,
                                buttonTextStyle:
                                CustomButtonTextStyle.bodyMedium,
                                onPressed: _shareQRCode,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 30.h, vertical: 12.h),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 20.h),

                        // Invite Friends
                        Text(
                          'Invite Friends',
                          style: TextStyleHelper
                              .instance.title16MediumPlusJakartaSans
                              .copyWith(color: appTheme.gray_50),
                        ),
                        SizedBox(height: 12.h),

                        // Search
                        Container(
                          decoration: BoxDecoration(
                            color: appTheme.gray_900_01,
                            borderRadius: BorderRadius.circular(12.h),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _filterFriends,
                            style: TextStyleHelper
                                .instance.body14MediumPlusJakartaSans
                                .copyWith(color: appTheme.gray_50),
                            decoration: InputDecoration(
                              hintText: 'Search friends by name...',
                              hintStyle: TextStyleHelper
                                  .instance.body14MediumPlusJakartaSans
                                  .copyWith(color: appTheme.blue_gray_300),
                              prefixIcon: Icon(Icons.search,
                                  color: appTheme.blue_gray_300, size: 20.h),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.h,
                                vertical: 14.h,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 12.h),

                        // Friends list + buttons (SINGLE INSTANCE ONLY)
                        Builder(
                          builder: (context) {
                            final double friendsListMaxHeight =
                            _selectedFriendIds.isNotEmpty
                                ? 160.h
                                : 220.h;

                            return Column(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOut,
                                  constraints: BoxConstraints(
                                      maxHeight: friendsListMaxHeight),
                                  decoration: BoxDecoration(
                                    color: appTheme.gray_900_01,
                                    borderRadius: BorderRadius.circular(12.h),
                                  ),
                                  child: _isLoadingFriends
                                      ? Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20.h),
                                      child: CircularProgressIndicator(
                                        color: appTheme.deep_purple_A100,
                                      ),
                                    ),
                                  )
                                      : _filteredFriends.isEmpty
                                      ? Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20.h),
                                      child: Text(
                                        _searchController.text.isEmpty
                                            ? 'No friends to invite'
                                            : 'No friends found',
                                        style: TextStyleHelper
                                            .instance
                                            .body14RegularPlusJakartaSans
                                            .copyWith(
                                            color: appTheme
                                                .blue_gray_300),
                                      ),
                                    ),
                                  )
                                      : ListView.separated(
                                    padding: EdgeInsets.all(12.h),
                                    itemCount: _filteredFriends.length,
                                    separatorBuilder:
                                        (context, index) => Divider(
                                      color: appTheme.blue_gray_300
                                          .withAlpha(51),
                                      height: 1,
                                    ),
                                    itemBuilder: (context, index) {
                                      final friend =
                                      _filteredFriends[index];
                                      final friendId = (friend['id'] ??
                                          '')
                                          .toString()
                                          .trim();

                                      final isSelected =
                                      _selectedFriendIds
                                          .contains(friendId);

                                      return ListTile(
                                        contentPadding:
                                        EdgeInsets.symmetric(
                                          horizontal: 12.h,
                                          vertical: 8.h,
                                        ),
                                        leading: ClipOval(
                                          child: CustomImageView(
                                            imagePath:
                                            friend['avatar_url'] ??
                                                '',
                                            height: 40.h,
                                            width: 40.h,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        title: Text(
                                          friend['display_name'] ??
                                              'Unknown',
                                          style: TextStyleHelper
                                              .instance
                                              .body14MediumPlusJakartaSans
                                              .copyWith(
                                            color: appTheme.gray_50,
                                            fontWeight:
                                            FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '@${friend['username'] ?? 'username'}',
                                          style: TextStyleHelper
                                              .instance
                                              .body12MediumPlusJakartaSans
                                              .copyWith(
                                              color: appTheme
                                                  .blue_gray_300),
                                        ),
                                        trailing: InkWell(
                                          onTap: () =>
                                              _toggleFriendSelection(
                                                  friendId),
                                          borderRadius:
                                          BorderRadius.circular(
                                              24.h),
                                          child: Padding(
                                            padding:
                                            EdgeInsets.all(8.h),
                                            child: Icon(
                                              isSelected
                                                  ? Icons.check_box
                                                  : Icons
                                                  .check_box_outline_blank,
                                              size: 24.h,
                                              color: isSelected
                                                  ? appTheme
                                                  .deep_purple_A100
                                                  : appTheme
                                                  .blue_gray_300,
                                            ),
                                          ),
                                        ),
                                        onTap: () =>
                                            _toggleFriendSelection(
                                                friendId),
                                      );
                                    },
                                  ),
                                ),

                                SizedBox(
                                    height: _selectedFriendIds.isNotEmpty
                                        ? 10.h
                                        : 16.h),

                                if (_selectedFriendIds.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CustomButton(
                                          text: 'Send Invites',
                                          buttonStyle:
                                          CustomButtonStyle.outlinePrimary,
                                          buttonTextStyle:
                                          CustomButtonTextStyle.bodyMedium,
                                          onPressed: _sendInvites,
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 30.h, vertical: 12.h),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12.h),
                                ],

                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomButton(
                                        text: 'Create Story',
                                        buttonStyle: CustomButtonStyle.fillPrimary,
                                        buttonTextStyle:
                                        CustomButtonTextStyle.bodyMedium,
                                        onPressed: () {
                                          if (memoryId.isEmpty) return;
                                          print(
                                              '✅ CONFIRM: categoryIcon="$categoryIcon"');
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  NativeCameraRecordingScreen(
                                                    memoryId: memoryId,
                                                    memoryTitle: memoryName.isNotEmpty
                                                        ? memoryName
                                                        : 'Memory',
                                                    categoryIcon: categoryIcon,
                                                  ),
                                            ),
                                          );
                                        },
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 30.h, vertical: 12.h),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 12.h),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Confetti overlay
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ConfettiPainter(
                      particles: _particles,
                      progress: _confettiController.value,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberAvatarRow({
    required List<Map<String, dynamic>> members,
    int maxVisible = 6,
  }) {
    if (members.isEmpty) {
      return Row(
        children: [
          Icon(Icons.people, color: appTheme.blue_gray_300, size: 16.h),
          SizedBox(width: 8.h),
          Text(
            '$memberCount ${memberCount == 1 ? 'member' : 'members'}',
            style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                .copyWith(color: appTheme.blue_gray_300),
          ),
        ],
      );
    }

    final visible = members.take(maxVisible).toList();
    final extraCount = members.length - visible.length;

    return Row(
      children: [
        ...visible.map((m) {
          final avatar =
          (m['avatar'] ?? m['avatar_url'] ?? '').toString().trim();
          final name =
          (m['name'] ?? m['display_name'] ?? 'User').toString().trim();

          return Padding(
            padding: EdgeInsets.only(right: 6.h),
            child: Tooltip(
              message: name.isEmpty ? 'User' : name,
              child: ClipOval(
                child: CustomImageView(
                  imagePath: avatar,
                  height: 28.h,
                  width: 28.h,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        }),
        if (extraCount > 0)
          Container(
            height: 28.h,
            padding: EdgeInsets.symmetric(horizontal: 10.h),
            decoration: BoxDecoration(
              color: appTheme.gray_900,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: appTheme.gray_700),
            ),
            alignment: Alignment.center,
            child: Text(
              '+$extraCount',
              style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                  .copyWith(color: appTheme.gray_50),
            ),
          ),
      ],
    );
  }

  Widget _buildLocalQRCode() {
    if (inviteCode == null) {
      return SizedBox(
        width: 200.h,
        height: 200.h,
        child: Center(
          child: Text(
            'QR code unavailable',
            style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                .copyWith(color: appTheme.blue_gray_300),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.h),
      ),
      child: SizedBox(
        width: 200.h,
        height: 200.h,
        child: PrettyQrView.data(
          data: 'https://capapp.co/join/memory/$inviteCode',
          decoration: PrettyQrDecoration(
            shape: PrettyQrSmoothSymbol(
              color: appTheme.gray_900_02,
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  void _shareQRCode() {
    if (inviteCode != null) {
      Share.share(
        'Join my Capsule memory: $memoryName\n\nhttps://capapp.co/join/memory/$inviteCode',
        subject: 'Join $memoryName on Capsule',
      );
    }
  }
}

// Confetti particle model
class ConfettiParticle {
  final Color color;
  final double startX;
  final double startY;
  final double endY;
  final double rotation;
  final double size;
  final double drift;

  ConfettiParticle({
    required this.color,
    required this.startX,
    required this.startY,
    required this.endY,
    required this.rotation,
    required this.size,
    required this.drift,
  });
}

// Custom painter for confetti animation
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(1.0 - progress * 0.5)
        ..style = PaintingStyle.fill;

      final x = (particle.startX + particle.drift * progress) * size.width;
      final y =
          (particle.startY + (particle.endY - particle.startY) * progress) *
              size.height;

      final rotation = particle.rotation * progress;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      final isCircle = particle.size % 2 == 0;
      if (isCircle) {
        canvas.drawCircle(Offset.zero, particle.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 0.6,
          ),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}