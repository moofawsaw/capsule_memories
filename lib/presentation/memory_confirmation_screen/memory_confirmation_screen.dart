import 'dart:async';
import 'dart:math' as math;

import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_export.dart';
import '../../services/friends_service.dart';
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
  DateTime? createdAt;
  String visibility = 'private';
  int memberCount = 1;
  DateTime? expiresAt;

  // NEW: Loading and error states
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

    // Generate confetti particles
    _generateConfetti();

    // Start confetti animation after a brief delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _confettiController.forward();
      }
    });

    // Initialize memory data and load friends
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
        // NEW: Set createdAt to now if not provided
        createdAt = DateTime.now();
        _isLoadingDetails = true;
      });

      print(
          '📍 CONFIRMATION SCREEN: Initialized with memoryId=$memoryId, memoryName=$memoryName');

      // Fetch complete memory details from database (with error handling)
      if (memoryId.isNotEmpty) {
        await _fetchMemoryDetails();
      } else {
        print('⚠️ CONFIRMATION SCREEN: No memory ID provided');
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
        print('⚠️ CONFIRMATION SCREEN: Supabase client not available');
        setState(() {
          _isLoadingDetails = false;
          _fetchError = 'Database connection unavailable';
        });
        return;
      }

      print('🔍 CONFIRMATION SCREEN: Fetching details for memory $memoryId');

      // FIXED: Add timeout and error handling
      final response = await supabase
          .from('memories')
          .select(
              'qr_code_url, invite_code, created_at, visibility, expires_at, contributor_count')
          .eq('id', memoryId)
          .maybeSingle() // Use maybeSingle() instead of single() to handle 0 rows gracefully
          .timeout(
        Duration(seconds: 10),
        onTimeout: () {
          print('⏱️ CONFIRMATION SCREEN: Query timeout after 10 seconds');
          return null;
        },
      );

      // FIXED: Handle null response (0 rows or timeout)
      if (response == null) {
        print('⚠️ CONFIRMATION SCREEN: No data returned from query');
        setState(() {
          _isLoadingDetails = false;
          _fetchError = 'Memory details not yet available';
          // Keep displaying with data we have from arguments
        });
        return;
      }

      print('✅ CONFIRMATION SCREEN: Successfully fetched memory details');

      // CRITICAL FIX: Add robust date parsing with try-catch
      DateTime? parsedCreatedAt;
      DateTime? parsedExpiresAt;

      // Parse created_at with error handling
      if (response['created_at'] != null) {
        try {
          parsedCreatedAt = DateTime.parse(response['created_at'] as String);
          print('✅ Successfully parsed created_at: $parsedCreatedAt');
        } catch (e) {
          print(
              '⚠️ WARNING: Failed to parse created_at: ${response['created_at']}');
          print('   Error: $e');
          parsedCreatedAt = DateTime.now(); // Fallback to now
        }
      } else {
        print('⚠️ WARNING: created_at is null, using current time');
        parsedCreatedAt = DateTime.now();
      }

      // Parse expires_at with error handling
      if (response['expires_at'] != null) {
        try {
          parsedExpiresAt = DateTime.parse(response['expires_at'] as String);
          print('✅ Successfully parsed expires_at: $parsedExpiresAt');
        } catch (e) {
          print(
              '⚠️ WARNING: Failed to parse expires_at: ${response['expires_at']}');
          print('   Error: $e');
          // Calculate default 12-hour expiration from created_at as fallback
          parsedExpiresAt = parsedCreatedAt.add(Duration(hours: 12));
          print(
              '   Using fallback expires_at: $parsedExpiresAt (created_at + 12 hours)');
        }
      } else {
        print(
            '⚠️ WARNING: expires_at is null, calculating default 12-hour window');
        parsedExpiresAt = parsedCreatedAt.add(Duration(hours: 12));
      }

      setState(() {
        qrCodeUrl = response['qr_code_url'] as String?;
        inviteCode = response['invite_code'] as String?;
        createdAt = parsedCreatedAt;
        visibility = response['visibility'] as String? ?? 'private';
        memberCount = (response['contributor_count'] as int?) ?? 1;
        expiresAt = parsedExpiresAt;
        _isLoadingDetails = false;
        _fetchError = null;
      });

      // Start countdown timer
      if (expiresAt != null) {
        _startCountdownTimer();
      }

      print(
          '📊 CONFIRMATION SCREEN: Updated state - visibility=$visibility, memberCount=$memberCount');
    } catch (e, stackTrace) {
      print('❌ CONFIRMATION SCREEN: Error fetching memory details: $e');
      print('📚 Stack trace: $stackTrace');

      setState(() {
        _isLoadingDetails = false;
        _fetchError = 'Could not load all details';
        // Keep displaying with data we have from arguments
      });
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

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
    } catch (e) {
      print('Error loading friends: $e');
      setState(() => _isLoadingFriends = false);
    }
  }

  void _filterFriends(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFriends = _allFriends;
      } else {
        _filteredFriends = _allFriends.where((friend) {
          final name = (friend['display_name'] as String? ?? '').toLowerCase();
          final username = (friend['username'] as String? ?? '').toLowerCase();
          final searchQuery = query.toLowerCase();
          return name.contains(searchQuery) || username.contains(searchQuery);
        }).toList();
      }
    });
  }

  void _toggleFriendSelection(String friendId) {
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
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(color: appTheme.deep_purple_A100),
        ),
      );

      // Send invites to selected friends
      for (final friendId in _selectedFriendIds) {
        // Add friend as memory contributor
        await SupabaseService.instance.client
            ?.from('memory_contributors')
            .insert({
          'memory_id': memoryId,
          'user_id': friendId,
        });
      }

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invites sent successfully!'),
          backgroundColor: appTheme.deep_purple_A100,
        ),
      );

      // Clear selections
      setState(() => _selectedFriendIds.clear());
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
            onPressed: () {
              print('🚪 CONFIRMATION SCREEN: Closing and navigating back');
              NavigatorService.goBack();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Congratulations Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        appTheme.deep_purple_A100,
                        appTheme.deep_purple_A200
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

                // NEW: Show loading indicator if fetching details
                if (_isLoadingDetails)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.h),
                    decoration: BoxDecoration(
                      color: appTheme.gray_900_01,
                      borderRadius: BorderRadius.circular(12.h),
                      border: Border.all(
                        color: appTheme.blue_gray_300.withAlpha(77),
                      ),
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

                // NEW: Show error message if fetch failed (but don't block UI)
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

                // Memory Details Card - ALWAYS SHOW with whatever data we have
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.h),
                  decoration: BoxDecoration(
                    color: appTheme.gray_900_01,
                    borderRadius: BorderRadius.circular(12.h),
                    border: Border.all(
                      color: appTheme.blue_gray_300.withAlpha(77),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Memory name - use data from arguments
                      Text(
                        memoryName.isNotEmpty ? memoryName : 'New Memory',
                        style: TextStyleHelper
                            .instance.title18BoldPlusJakartaSans
                            .copyWith(color: appTheme.gray_50),
                      ),
                      SizedBox(height: 12.h),

                      // Creation timestamp
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              color: appTheme.blue_gray_300, size: 16.h),
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

                      // Privacy status
                      Row(
                        children: [
                          Icon(
                            visibility == 'public' ? Icons.public : Icons.lock,
                            color: visibility == 'public'
                                ? Colors.green
                                : appTheme.deep_purple_A100,
                            size: 16.h,
                          ),
                          SizedBox(width: 8.h),
                          Text(
                            visibility == 'public' ? 'Public' : 'Private',
                            style: TextStyleHelper
                                .instance.body14RegularPlusJakartaSans
                                .copyWith(color: appTheme.blue_gray_300),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),

                      // Current member count
                      Row(
                        children: [
                          Icon(Icons.people,
                              color: appTheme.blue_gray_300, size: 16.h),
                          SizedBox(width: 8.h),
                          Text(
                            '$memberCount ${memberCount == 1 ? 'member' : 'members'}',
                            style: TextStyleHelper
                                .instance.body14RegularPlusJakartaSans
                                .copyWith(color: appTheme.blue_gray_300),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20.h),

                // 12-hour countdown timer
                if (_remainingTime != null)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.h),
                    decoration: BoxDecoration(
                      color: appTheme.gray_900_01,
                      borderRadius: BorderRadius.circular(12.h),
                      border: Border.all(
                        color: appTheme.deep_purple_A100.withAlpha(128),
                      ),
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
                              .copyWith(color: appTheme.deep_purple_A100),
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: 20.h),

                // QR Code Section
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

                      // Display QR code
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
                            errorBuilder: (context, error, stackTrace) {
                              return _buildLocalQRCode();
                            },
                          ),
                        )
                      else
                        _buildLocalQRCode(),

                      SizedBox(height: 16.h),

                      // Invite code
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

                      // Share QR Code button
                      CustomButton(
                        text: 'Share QR Code',
                        buttonStyle: CustomButtonStyle.outlinePrimary,
                        buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                        onPressed: _shareQRCode,
                        padding: EdgeInsets.symmetric(
                            horizontal: 30.h, vertical: 12.h),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20.h),

                // Invite Friends Section
                Text(
                  'Invite Friends',
                  style: TextStyleHelper.instance.title16MediumPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                ),
                SizedBox(height: 12.h),

                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: appTheme.gray_900_01,
                    borderRadius: BorderRadius.circular(12.h),
                    border: Border.all(
                      color: appTheme.blue_gray_300.withAlpha(77),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterFriends,
                    style: TextStyleHelper.instance.body14MediumPlusJakartaSans
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

                // Friends list
                Container(
                  constraints: BoxConstraints(maxHeight: 250.h),
                  decoration: BoxDecoration(
                    color: appTheme.gray_900_01,
                    borderRadius: BorderRadius.circular(12.h),
                    border: Border.all(
                      color: appTheme.blue_gray_300.withAlpha(77),
                    ),
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
                                      .instance.body14RegularPlusJakartaSans
                                      .copyWith(color: appTheme.blue_gray_300),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: EdgeInsets.all(12.h),
                              itemCount: _filteredFriends.length,
                              separatorBuilder: (context, index) => Divider(
                                color: appTheme.blue_gray_300.withAlpha(51),
                                height: 1,
                              ),
                              itemBuilder: (context, index) {
                                final friend = _filteredFriends[index];
                                final isSelected =
                                    _selectedFriendIds.contains(friend['id']);

                                return ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12.h,
                                    vertical: 8.h,
                                  ),
                                  leading: ClipOval(
                                    child: CustomImageView(
                                      imagePath: friend['avatar_url'] ?? '',
                                      height: 40.h,
                                      width: 40.h,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  title: Text(
                                    friend['display_name'] ?? 'Unknown',
                                    style: TextStyleHelper
                                        .instance.body14MediumPlusJakartaSans
                                        .copyWith(
                                      color: appTheme.gray_50,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '@${friend['username'] ?? 'username'}',
                                    style: TextStyleHelper
                                        .instance.body12MediumPlusJakartaSans
                                        .copyWith(
                                      color: appTheme.blue_gray_300,
                                    ),
                                  ),
                                  trailing: Checkbox(
                                    value: isSelected,
                                    onChanged: (value) =>
                                        _toggleFriendSelection(friend['id']),
                                    activeColor: appTheme.deep_purple_A100,
                                    checkColor: appTheme.gray_50,
                                  ),
                                  onTap: () =>
                                      _toggleFriendSelection(friend['id']),
                                );
                              },
                            ),
                ),

                SizedBox(height: 20.h),

                // Action Buttons
                Row(
                  children: [
                    if (_selectedFriendIds.isNotEmpty)
                      Expanded(
                        child: CustomButton(
                          text: 'Send Invites',
                          buttonStyle: CustomButtonStyle.fillPrimary,
                          buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                          onPressed: _sendInvites,
                          padding: EdgeInsets.symmetric(
                              horizontal: 30.h, vertical: 12.h),
                        ),
                      ),
                    if (_selectedFriendIds.isNotEmpty) SizedBox(width: 12.h),
                    Expanded(
                      child: CustomButton(
                        text: 'Start Adding Stories',
                        buttonStyle: _selectedFriendIds.isEmpty
                            ? CustomButtonStyle.fillPrimary
                            : CustomButtonStyle.outlinePrimary,
                        buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                        onPressed: () {
                          NavigatorService.pushNamed(AppRoutes.appStoryRecord);
                        },
                        padding: EdgeInsets.symmetric(
                            horizontal: 30.h, vertical: 12.h),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 40.h),
              ],
            ),
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

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
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
        canvas.drawCircle(
          Offset.zero,
          particle.size / 2,
          paint,
        );
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
