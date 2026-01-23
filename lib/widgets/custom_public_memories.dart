// lib/widgets/custom_public_memories.dart
import 'dart:async';

import '../core/app_export.dart';
import '../services/avatar_helper_service.dart';
import '../services/memory_members_service.dart';
import '../services/story_service.dart';
import '../utils/storage_utils.dart';
import '../services/supabase_service.dart';
import './custom_button.dart';
import './custom_image_view.dart';
import './custom_memory_skeleton.dart';
import './timeline_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../presentation/memory_feed_dashboard_screen/widgets/native_camera_recording_screen.dart';
import '../presentation/event_timeline_view_screen/widgets/timeline_story_widget.dart';

/// Controls card sizing + badge behavior per screen.
enum MemoryCardVariant {
  dashboard, // My memories screen (shows state + visibility badges)
  feed, // Feed cards (usually no badges, tighter height)
}

/// CustomPublicMemories - A horizontal scrolling component that displays public memory cards.
class CustomPublicMemories extends StatelessWidget {
  const CustomPublicMemories({
    Key? key,
    this.sectionTitle,
    this.sectionIcon,
    this.memories,
    this.onMemoryTap,
    this.margin,
    this.isLoading = false,
    this.variant = MemoryCardVariant.dashboard,
  }) : super(key: key);

  final String? sectionTitle;
  final String? sectionIcon;
  final List<CustomMemoryItem>? memories;
  final Function(CustomMemoryItem)? onMemoryTap;
  final EdgeInsetsGeometry? margin;
  final bool isLoading;

  /// controls layout + height + badge visibility rules
  final MemoryCardVariant variant;

  Future<bool> _memoryHasAnyStories(String memoryId) async {
    final client = SupabaseService.instance.client;
    if (client == null) return false;

    try {
      // ✅ Lightweight existence check (NO profile joins, no heavy selects)
      final res = await client
          .from('stories')
          .select('id')
          .eq('memory_id', memoryId)
          .limit(1);
      return (res as List).isNotEmpty;
    } catch (e) {
      // ignore: avoid_print
      print('❌ FEED EXISTS CHECK failed for memory $memoryId: $e');
      return false;
    }
  }

  Future<List<CustomMemoryItem>> _filterFeedMemoriesWithStories(
      List<CustomMemoryItem> input) async {
    final List<CustomMemoryItem> filtered = [];

    for (final memory in input) {
      final id = memory.id;
      if (id == null || id.isEmpty) continue;

      final hasStories = await _memoryHasAnyStories(id);
      if (hasStories) filtered.add(memory);
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.only(top: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sectionTitle != null || sectionIcon != null) _buildSectionHeader(),
          if (sectionTitle != null || sectionIcon != null) SizedBox(height: 24.h),
          _buildMemoriesScroll(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.h),
      child: Row(
        children: [
          CustomImageView(
            imagePath: sectionIcon ?? ImageConstant.imgIcon22x22,
            height: 22.h,
            width: 22.h,
            color: appTheme.deep_purple_A100,
          ),
          SizedBox(width: 8.h),
          Text(
            sectionTitle ?? 'Public Memories',
            style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                .copyWith(color: appTheme.gray_50),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoriesScroll(BuildContext context) {
    if (isLoading) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          children: List.generate(3, (index) {
            return Container(
              width: 300.h,
              margin: EdgeInsets.only(
                left: index == 0 ? 24.h : 0,
                right: 12.h,
              ),
              child: CustomMemorySkeleton(),
            );
          }),
        ),
      );
    }

    final List<CustomMemoryItem> memoryListRaw = memories ?? <CustomMemoryItem>[];

    // If nothing came down at all, show empty state immediately.
    if (memoryListRaw.isEmpty) {
      return _buildEmptyState();
    }

    // ✅ FEED variant: pre-filter memories so we can show empty state if none have stories.
    if (variant == MemoryCardVariant.feed) {
      return FutureBuilder<List<CustomMemoryItem>>(
        future: _filterFeedMemoriesWithStories(memoryListRaw),
        builder: (context, snapshot) {
          // While filtering, show skeletons (same layout).
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                children: List.generate(3, (index) {
                  return Container(
                    width: 300.h,
                    margin: EdgeInsets.only(
                      left: index == 0 ? 24.h : 0,
                      right: 12.h,
                    ),
                    child: CustomMemorySkeleton(),
                  );
                }),
              ),
            );
          }

          final List<CustomMemoryItem> filtered =
              snapshot.data ?? <CustomMemoryItem>[];

          if (filtered.isEmpty) {
            return _buildEmptyState();
          }

          return _buildMemoryRow(context, filtered);
        },
      );
    }

    // Dashboard (or non-feed) behavior: show what we received.
    return _buildMemoryRow(context, memoryListRaw);
  }

  Widget _buildMemoryRow(BuildContext context, List<CustomMemoryItem> list) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(list.length, (index) {
          final CustomMemoryItem memory = list[index];
          return Container(
            margin: EdgeInsets.only(
              left: index == 0 ? 24.h : 0,
              right: 12.h,
            ),
            child: _PublicMemoryCard(
              memory: memory,
              onTap: () => onMemoryTap?.call(memory),
              variant: variant,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.h),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomImageView(
                imagePath: sectionIcon ?? ImageConstant.imgIcon22x22,
                height: 48.h,
                width: 48.h,
                color: appTheme.blue_gray_300,
              ),
              SizedBox(height: 12.h),
              Text(
                'No memories yet',
                style: TextStyleHelper.instance.title16MediumPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
              SizedBox(height: 4.h),
              Text(
                'Check back soon to view open memories',
                style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Data model for memory items
class CustomMemoryItem {
  CustomMemoryItem({
    this.id,
    this.userId, // owner id
    this.title,
    this.date,
    String? iconPath,
    this.iconName,
    this.profileImages,
    this.mediaItems,
    this.startDate,
    this.startTime,
    this.endDate,
    this.endTime,
    this.location,
    this.distance,
    this.isLiked,
    this.state, // open / sealed
    this.visibility, // public / private
  }) : _iconPath = iconPath;

  final String? id;
  final String? userId;
  final String? title;
  final String? date;

  // ✅ stable identifier from DB (memory_categories.icon_name)
  final String? iconName;

  // Backing field for whatever the caller passed.
  final String? _iconPath;

  final List<String>? profileImages;
  final List<CustomMediaItem>? mediaItems;
  final String? startDate;
  final String? startTime;
  final String? endDate;
  final String? endTime;
  final String? location;
  final String? distance;
  final bool? isLiked;

  final String? state;
  final String? visibility;

  String? get iconPath {
    final String raw = (_iconPath ?? '').trim();
    final String name = (iconName ?? '').trim();

    // 1) iconName wins every time (stable path)
    if (name.isNotEmpty) {
      return StorageUtils.resolveMemoryCategoryIconUrl(
        name.endsWith('.svg') ? name : '$name.svg',
      );
    }

    if (raw.isEmpty) return null;

    // 2) If it's already a stable bucket icon url, keep it:
    final bool isCategoryIconsUrl =
        raw.contains('/storage/v1/object/public/category-icons/') &&
            raw.toLowerCase().endsWith('.svg');

    // A dead "uploaded" icon_url pattern
    final bool looksLikeUploadedTemp =
    RegExp(r'/category-icons/\d{10,}-[a-z0-9]+\.svg$', caseSensitive: false)
        .hasMatch(raw);

    if (isCategoryIconsUrl && !looksLikeUploadedTemp) {
      return raw;
    }

    // 3) If raw is just an icon file/name, build stable URL
    final bool rawLooksLikeNameOnly =
        !raw.startsWith('http://') && !raw.startsWith('https://');

    if (rawLooksLikeNameOnly) {
      final String file = raw.toLowerCase().endsWith('.svg') ? raw : '$raw.svg';
      return StorageUtils.resolveMemoryCategoryIconUrl(file);
    }

    return raw;
  }
}

/// Data model for media items in the timeline (kept for compatibility)
class CustomMediaItem {
  CustomMediaItem({
    this.imagePath,
    this.hasPlayButton = false,
  });

  final String? imagePath;
  final bool hasPlayButton;
}

/// Stateful widget for individual public memory card that fetches stories
class _PublicMemoryCard extends StatefulWidget {
  final CustomMemoryItem memory;
  final VoidCallback? onTap;
  final MemoryCardVariant variant;

  const _PublicMemoryCard({
    Key? key,
    required this.memory,
    this.onTap,
    this.variant = MemoryCardVariant.dashboard,
  }) : super(key: key);

  @override
  State<_PublicMemoryCard> createState() => _PublicMemoryCardState();
}

class _PublicMemoryCardState extends State<_PublicMemoryCard> {
  final StoryService _storyService = StoryService();
  final MemoryMembersService _membersService = MemoryMembersService();

  // ✅ Realtime: contributors + stories (story post doesn't change contributors)
  StreamSubscription<List<Map<String, dynamic>>>? _contributorsStreamSub;
  StreamSubscription<List<Map<String, dynamic>>>? _storiesStreamSub;
  String? _rtForMemoryId;

// ============================
// REALTIME: MEMBERS (contributors)
// ============================

  RealtimeChannel? _membersChannel;
  String? _membersSubForMemoryId;
  Timer? _membersRtDebounce;
  DateTime? _lastMembersRtAt;

  void _startMembersRealtime() {
    final client = SupabaseService.instance.client;
    final memoryId = widget.memory.id;

    if (client == null) return;
    if (memoryId == null || memoryId.isEmpty) return;

    // Avoid double-subscribing
    if (_membersChannel != null && _membersSubForMemoryId == memoryId) {
      _rtLog('🔁 realtime already subscribed');
      return;
    }

    _stopMembersRealtime();
    _membersSubForMemoryId = memoryId;

    _rtLog('🛰️ realtime subscribe -> table=memory_contributors filter=memory_id=eq.$memoryId');

    final ch = client.channel('memory_contributors:$memoryId');

    // ✅ This is the API that exists in supabase_flutter versions where
    // RealtimeListenTypes / ChannelFilter are NOT available.
    ch.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'memory_contributors',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'memory_id',
        value: memoryId,
      ),
      callback: (payload) {
        _lastMembersRtAt = DateTime.now();
        _rtLog('📡 RT payload event=${payload.eventType} table=${payload.table}');

        if (!mounted) return;

        // Debounce in case multiple rows/events fire back-to-back
        _membersRtDebounce?.cancel();
        _membersRtDebounce = Timer(const Duration(milliseconds: 250), () async {
          if (!mounted) return;
          _rtLog('🔄 RT -> refetch memberCount + memberAvatars');
          await _fetchMemberCount();
          await _fetchMemberAvatars();
          if (!mounted) return;
          setState(() {}); // force paint even if list contents are same
        });
      },
    );

    _membersChannel = ch;

    ch.subscribe((status, [ref]) {
      _rtLog('✅ subscribe status=$status ref=$ref');
    });
  }

  void _stopMembersRealtime() {
    final client = SupabaseService.instance.client;
    if (client == null) return;

    _membersRtDebounce?.cancel();
    _membersRtDebounce = null;

    final ch = _membersChannel;
    _membersChannel = null;
    _membersSubForMemoryId = null;

    if (ch != null) {
      _rtLog('🛑 realtime removeChannel');
      client.removeChannel(ch);
    }
  }

// Small log helper
  void _rtLog(String msg) {
    final mem = widget.memory.id ?? '';
    // ignore: avoid_print
    print('🟣 [PublicMemoryCard] ${DateTime.now().toIso8601String()} mem=$mem | $msg');
  }

  List<TimelineStoryItem> _timelineStories = <TimelineStoryItem>[];
  DateTime? _memoryStartTime;
  DateTime? _memoryEndTime;
  bool _isLoadingTimeline = true;
  bool _isUserCreatedMemory = false;
  int _memberCount = 0;
  int _rtEventCount = 0;
  int _avatarsFetchCount = 0;
  int _countFetchCount = 0;
  DateTime? _lastRtAt;

  String _dbgNow() => DateTime.now().toIso8601String();

  void _dbg(String msg) {
    // ignore: avoid_print
    print('🟣 [PublicMemoryCard] ${_dbgNow()} mem=${widget.memory.id} | $msg');
  }

  // ✅ feed-safe member avatars for header (first 3)
  List<String> _memberAvatars = <String>[];
  bool _isLoadingMemberAvatars = false;

  static const double _timelineSidePadding = 14.0;

  @override
  void initState() {
    super.initState();
    _deriveOwnershipFast();
    _loadTimelineData();
    _fetchMemberCount();
    _fetchMemberAvatars();

    // ✅ keep avatars/count correct when members are added after creation
    _startMembersRealtime();
  }

  bool _canCreateStoryForThisMemory() {
    final raw = (widget.memory.state ?? '').toLowerCase().trim();

    if (raw == 'sealed') return false;
    if (raw == 'open') return true;

    // If state is missing/unknown, default to allow.
    return true;
  }

  void _deriveOwnershipFast() {
    final currentUser = SupabaseService.instance.client?.auth.currentUser;
    final ownerId = widget.memory.userId;

    if (currentUser == null || ownerId == null || ownerId.isEmpty) {
      _isUserCreatedMemory = false;
      _checkMemoryOwnershipFallback();
      return;
    }

    _isUserCreatedMemory = currentUser.id == ownerId;
  }

  Future<void> _checkMemoryOwnershipFallback() async {
    try {
      final currentUser = SupabaseService.instance.client?.auth.currentUser;
      final memoryId = widget.memory.id;

      if (currentUser == null || memoryId == null || memoryId.isEmpty) {
        if (mounted) setState(() => _isUserCreatedMemory = false);
        return;
      }

      final dynamic memoryResponse = await SupabaseService.instance.client
          ?.from('memories')
          .select('creator_id')
          .eq('id', memoryId)
          .maybeSingle();

      if (!mounted) return;

      final String? creatorId = memoryResponse?['creator_id'] as String?;
      setState(() {
        _isUserCreatedMemory = creatorId != null && creatorId == currentUser.id;
      });
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error checking memory ownership (fallback): $e');
      if (mounted) setState(() => _isUserCreatedMemory = false);
    }
  }

  Future<void> _fetchMemberCount({String debugFrom = 'manual'}) async {
    _countFetchCount += 1;
    final memoryId = widget.memory.id;

    _dbg('👥 fetchMemberCount(#$_countFetchCount) from=$debugFrom memoryId=$memoryId');

    if (memoryId == null || memoryId.isEmpty) {
      if (mounted) setState(() => _memberCount = 0);
      _dbg('👥 fetchMemberCount: memoryId missing -> memberCount=0');
      return;
    }

    try {
      final members = await _membersService.fetchMemoryMembers(memoryId);
      _dbg('👥 fetchMemberCount: service returned ${members.length} members');

      if (!mounted) return;
      setState(() => _memberCount = members.length);
    } catch (e) {
      _dbg('❌ fetchMemberCount error: $e');
      if (mounted) setState(() => _memberCount = 0);
    }
  }


  // ✅ fetch top 3 member avatars when profileImages isn't provided (feed)
  Future<void> _fetchMemberAvatars({String debugFrom = 'manual'}) async {
    _avatarsFetchCount += 1;
    final memoryId = widget.memory.id;

    _dbg('🧑 fetchMemberAvatars(#$_avatarsFetchCount) from=$debugFrom memoryId=$memoryId');

    if (memoryId == null || memoryId.isEmpty) {
      _dbg('🧑 fetchMemberAvatars: memoryId missing (return)');
      return;
    }

    // If caller already provided profileImages (dashboard), prefer that.
    final provided = widget.memory.profileImages ?? <String>[];
    _dbg('🧑 provided profileImages=${provided.length}');

    if (provided.isNotEmpty) {
      final take = provided.take(3).toList();
      _dbg('🧑 using PROVIDED avatars -> ${take.length}');
      if (mounted) setState(() => _memberAvatars = take);
      return;
    }

    try {
      if (mounted) setState(() => _isLoadingMemberAvatars = true);

      final List<dynamic> members = await _membersService.fetchMemoryMembers(memoryId);
      _dbg('🧑 service.fetchMemoryMembers returned ${members.length} rows');

      final List<String> avatars = [];

      for (final dynamic m in members) {
        if (m is! Map<String, dynamic>) continue;

        final String? rawAvatar =
            m['avatar_url'] as String? ??
                m['user_profiles']?['avatar_url'] as String? ??
                m['user_profiles_public']?['avatar_url'] as String?;

        final String resolved = AvatarHelperService.getAvatarUrl(rawAvatar);

        _dbg('🧑 row user_id=${m['user_id']} rawAvatar=$rawAvatar resolved=$resolved');

        if (resolved.isNotEmpty) {
          avatars.add(resolved);
        }

        if (avatars.length >= 3) break;
      }

      if (!mounted) return;
      setState(() {
        _memberAvatars = avatars;
        _isLoadingMemberAvatars = false;
      });

      _dbg('🧑 fetchMemberAvatars DONE -> stored=${_memberAvatars.length}');
    } catch (e) {
      _dbg('❌ fetchMemberAvatars error: $e');
      if (!mounted) return;
      setState(() => _isLoadingMemberAvatars = false);
    }
  }


  @override
  void didUpdateWidget(covariant _PublicMemoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldId = oldWidget.memory.id;
    final newId = widget.memory.id;

    if (oldId != newId) {
      setState(() {
        _isLoadingTimeline = true;
        _timelineStories = <TimelineStoryItem>[];
        _memoryStartTime = null;
        _memoryEndTime = null;
        _memberCount = 0;

        _memberAvatars = <String>[];
        _isLoadingMemberAvatars = false;
      });

      _deriveOwnershipFast();
      _fetchMemberCount();
      _fetchMemberAvatars();
      _loadTimelineData();

      // ✅ re-bind stream to the new memory id
      _startMembersRealtime();
      return;
    }

    // Same memory id, but data may have updated.
    final newProvided = widget.memory.profileImages ?? <String>[];
    final oldProvided = oldWidget.memory.profileImages ?? <String>[];

    final bool providedChanged =
        oldProvided.length != newProvided.length || !_listEquals(oldProvided, newProvided);

    if (providedChanged) {
      if (newProvided.isNotEmpty && mounted) {
        setState(() => _memberAvatars = newProvided.take(3).toList());
      } else {
        _fetchMemberAvatars();
      }
    } else {
      if (_memberAvatars.isEmpty && !_isLoadingMemberAvatars) {
        _fetchMemberAvatars();
      }
    }

    if (oldWidget.memory.userId != widget.memory.userId) {
      _deriveOwnershipFast();
      if (mounted) setState(() {});
    }
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _stopMembersRealtime();
    super.dispose();
  }

  Future<void> _loadTimelineData() async {
    if (widget.memory.id == null || widget.memory.id!.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoadingTimeline = false;
        _timelineStories = <TimelineStoryItem>[];
        _memoryStartTime = _parseMemoryStartTime();
        _memoryEndTime = _parseMemoryEndTime();
      });
      return;
    }

    try {
      final String memoryId = widget.memory.id!;

      final dynamic memoryResponse = await SupabaseService.instance.client
          ?.from('memories')
          .select('start_time, end_time')
          .eq('id', memoryId)
          .single();

      DateTime memoryStart;
      DateTime memoryEnd;

      if (memoryResponse != null &&
          memoryResponse['start_time'] != null &&
          memoryResponse['end_time'] != null) {
        memoryStart = DateTime.parse(memoryResponse['start_time'] as String);
        memoryEnd = DateTime.parse(memoryResponse['end_time'] as String);
      } else {
        memoryStart = _parseMemoryStartTime();
        memoryEnd = _parseMemoryEndTime();
      }

      final List<dynamic> storiesData = await _storyService.fetchMemoryStories(memoryId);

      if (!mounted) return;

      if (storiesData.isEmpty) {
        setState(() {
          _isLoadingTimeline = false;
          _timelineStories = <TimelineStoryItem>[];
          _memoryStartTime = memoryStart;
          _memoryEndTime = memoryEnd;
        });
        return;
      }

      final List<TimelineStoryItem> timelineStories =
      storiesData.map<TimelineStoryItem>((dynamic storyData) {
        final Map<String, dynamic>? contributor =
            (storyData['user_profiles_public'] as Map<String, dynamic>?) ??
                (storyData['user_profiles'] as Map<String, dynamic>?);

        final DateTime createdAt = DateTime.parse(storyData['created_at'] as String);
        final String storyId = storyData['id'] as String;

        final String backgroundImage = _storyService.getStoryMediaUrl(storyData);

        final String? avatarUrl = contributor != null ? contributor['avatar_url'] as String? : null;
        final String profileImage = AvatarHelperService.getAvatarUrl(avatarUrl);

        return TimelineStoryItem(
          backgroundImage: backgroundImage,
          userAvatar: profileImage,
          postedAt: createdAt,
          timeLabel: _storyService.getTimeAgo(createdAt),
          storyId: storyId,
        );
      }).toList();

      if (!mounted) return;

      setState(() {
        _timelineStories = timelineStories;
        _memoryStartTime = memoryStart;
        _memoryEndTime = memoryEnd;
        _isLoadingTimeline = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('❌ PUBLIC MEMORY CARD: Error loading timeline: $e');
      if (!mounted) return;

      setState(() {
        _isLoadingTimeline = false;
        _timelineStories = <TimelineStoryItem>[];
        _memoryStartTime ??= _parseMemoryStartTime();
        _memoryEndTime ??= _parseMemoryEndTime();
      });
    }
  }

  DateTime _parseMemoryStartTime() {
    try {
      final String dateStr = widget.memory.startDate ?? 'Dec 4';
      final String timeStr = widget.memory.startTime ?? '3:18pm';

      final DateTime now = DateTime.now();
      final List<String> parts = dateStr.split(' ');
      final int month = _monthToNumber(parts[0]);
      final int day = int.tryParse(parts.length > 1 ? parts[1] : '') ?? now.day;

      final List<String> timeParts = timeStr
          .toLowerCase()
          .replaceAll(RegExp(r'[ap]m'), '')
          .trim()
          .split(':');

      int hour = int.tryParse(timeParts[0]) ?? 0;
      final int minute =
      timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;

      if (timeStr.toLowerCase().contains('pm') && hour != 12) hour += 12;
      if (timeStr.toLowerCase().contains('am') && hour == 12) hour = 0;

      return DateTime(now.year, month, day, hour, minute);
    } catch (_) {
      return DateTime.now().subtract(const Duration(hours: 2));
    }
  }

  DateTime _parseMemoryEndTime() {
    try {
      final String dateStr = widget.memory.endDate ?? 'Dec 4';
      final String timeStr = widget.memory.endTime ?? '3:18am';

      final DateTime now = DateTime.now();
      final List<String> parts = dateStr.split(' ');
      final int month = _monthToNumber(parts[0]);
      final int day = int.tryParse(parts.length > 1 ? parts[1] : '') ?? now.day;

      final List<String> timeParts = timeStr
          .toLowerCase()
          .replaceAll(RegExp(r'[ap]m'), '')
          .trim()
          .split(':');

      int hour = int.tryParse(timeParts[0]) ?? 0;
      final int minute =
      timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;

      if (timeStr.toLowerCase().contains('pm') && hour != 12) hour += 12;
      if (timeStr.toLowerCase().contains('am') && hour == 12) hour = 0;

      return DateTime(now.year, month, day, hour, minute);
    } catch (_) {
      return DateTime.now();
    }
  }

  int _monthToNumber(String month) {
    const Map<String, int> months = <String, int>{
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };

    final String key =
    month.toLowerCase().substring(0, month.length >= 3 ? 3 : month.length);
    return months[key] ?? DateTime.now().month;
  }

  // ======= TIMELINE (fixed height + centered content) =======

  Widget _buildTimelineSkeletonCompact() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.h, vertical: 10.h),
      child: Column(
        children: [
          Container(
            height: 4.h,
            decoration: BoxDecoration(
              color: appTheme.blue_gray_300.withAlpha(51),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDateMarkerSkeletonCompact(),
              _buildDateMarkerSkeletonCompact(),
              _buildDateMarkerSkeletonCompact(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateMarkerSkeletonCompact() {
    return Column(
      children: [
        Container(
          width: 2,
          height: 8.h,
          color: appTheme.blue_gray_300.withAlpha(51),
        ),
        SizedBox(height: 6.h),
        Container(
          width: 46.h,
          height: 12.h,
          decoration: BoxDecoration(
            color: appTheme.blue_gray_300.withAlpha(51),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(height: 5.h),
        Container(
          width: 38.h,
          height: 10.h,
          decoration: BoxDecoration(
            color: appTheme.blue_gray_300.withAlpha(51),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerEmptyContentCompact({required bool hasNoMembers}) {
    return Column(
      children: [
        Text(
          'No stories yet',
          style: TextStyleHelper.instance.title16BoldPlusJakartaSans
              .copyWith(color: appTheme.gray_50),
        ),
        SizedBox(height: 6.h),
        Text(
          'Create your first story',
          style: TextStyleHelper.instance.body12MediumPlusJakartaSans
              .copyWith(color: appTheme.blue_gray_300),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12.h),
        CustomButton(
          text: 'Create Story',
          leftIcon: ImageConstant.imgPlayCircle,
          onPressed: _onCreateStoryTap,
          buttonStyle: CustomButtonStyle.fillPrimary,
          buttonTextStyle: CustomButtonTextStyle.bodySmall,
          height: 38.h,
          padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 10.h),
        ),
      ],
    );
  }

  Widget _buildJoinedEmptyContentCompact() {
    final bool canCreate = _canCreateStoryForThisMemory();

    return Column(
      children: [
        Text(
          'No stories yet',
          style: TextStyleHelper.instance.title16BoldPlusJakartaSans.copyWith(
            color: appTheme.gray_50,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          canCreate ? 'Be the first to add one' : 'This memory is sealed',
          style: TextStyleHelper.instance.body12MediumPlusJakartaSans.copyWith(
            color: appTheme.blue_gray_300,
          ),
          textAlign: TextAlign.center,
        ),
        if (canCreate) ...[
          SizedBox(height: 12.h),
          CustomButton(
            text: 'Create Story',
            leftIcon: ImageConstant.imgPlayCircle,
            onPressed: _onCreateStoryTap,
            buttonStyle: CustomButtonStyle.fillPrimary,
            buttonTextStyle: CustomButtonTextStyle.bodySmall,
            height: 38.h,
            padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 10.h),
          ),
        ],
      ],
    );
  }

  Widget _buildMemoryTimeline() {
    return SizedBox(
      height: 220.h,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: _timelineSidePadding.h),
        child: Container(
          decoration: BoxDecoration(
            color: _timelineStories.isEmpty
                ? appTheme.gray_900_02.withAlpha(128)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16.h),
          ),
          child: _buildMemoryTimelineInner(),
        ),
      ),
    );
  }

  Widget _buildMemoryTimelineInner() {
    if (_isLoadingTimeline) {
      return Center(child: _buildTimelineSkeletonCompact());
    }

    if (_timelineStories.isEmpty) {
      final bool hasNoMembers = _memberCount == 0;

      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTimelineSkeletonCompact(),
              SizedBox(height: 10.h),
              if (_isUserCreatedMemory)
                _buildOwnerEmptyContentCompact(hasNoMembers: hasNoMembers)
              else
                _buildJoinedEmptyContentCompact(),
            ],
          ),
        ),
      );
    }

    final DateTime start = _memoryStartTime ?? _parseMemoryStartTime();
    final DateTime end = _memoryEndTime ?? _parseMemoryEndTime();

    return Center(
      child: TimelineWidget(
        stories: _timelineStories,
        memoryStartTime: start,
        memoryEndTime: end,
        layoutVariant: TimelineLayoutVariant.compact,
        onStoryTap: (String storyId) {
          if (widget.onTap != null) widget.onTap!();
        },
      ),
    );
  }

  Future<void> _onCreateStoryTap() async {
    final id = widget.memory.id;
    if (id == null || id.isEmpty) return;

    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => NativeCameraRecordingScreen(
          memoryId: id,
          memoryTitle: widget.memory.title ?? '',
          categoryIcon: widget.memory.iconPath,
        ),
      ),
    );
  }

  // ======= LAYOUT RULES =======

  bool _shouldShowBadges(CustomMemoryItem memory) {
    if (widget.variant != MemoryCardVariant.dashboard) return false;

    final hasState = (memory.state ?? '').trim().isNotEmpty;
    final hasVisibility = (memory.visibility ?? '').trim().isNotEmpty;
    return hasState || hasVisibility;
  }

  // ======= CARD =======

  @override
  Widget build(BuildContext context) {
    _dbg('BUILD: memberCount=$_memberCount memberAvatars=${_memberAvatars.length} isLoadingAvatars=$_isLoadingMemberAvatars lastRtAt=$_lastRtAt');
    final bool isFeed = widget.variant == MemoryCardVariant.feed;
    final double cardHeight = isFeed ? 300.h : 330.h;

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 300.h,
        height: cardHeight,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.h),
          ),
          child: Column(
            children: [
              _buildMemoryHeader(context),
              _buildMemoryTimeline(),
              _buildMemoryFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgesRowNoWrap(CustomMemoryItem memory) {
    final hasState = (memory.state ?? '').trim().isNotEmpty;
    final hasVisibility = (memory.visibility ?? '').trim().isNotEmpty;

    if (!hasState && !hasVisibility) return const SizedBox.shrink();

    return ClipRect(
      child: Row(
        children: [
          if (hasState) _buildStateBadge(memory),
          if (hasState && hasVisibility) SizedBox(width: 8.h),
          if (hasVisibility) _buildVisibilityBadge(memory),
        ],
      ),
    );
  }

  Widget _buildVisibilityBadge(CustomMemoryItem memory) {
    final raw = (memory.visibility ?? '').toLowerCase().trim();
    if (raw.isEmpty) return const SizedBox.shrink();

    final bool isPublic = raw == 'public';
    final String label = isPublic ? 'Public' : 'Private';

    final Color fg = isPublic ? appTheme.deep_purple_A100 : appTheme.blue_gray_300;
    final Color bg = fg.withAlpha(38);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 6.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyleHelper.instance.body12MediumPlusJakartaSans.copyWith(
          color: fg,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildStateBadge(CustomMemoryItem memory) {
    final raw = (memory.state ?? '').toLowerCase().trim();
    if (raw.isEmpty) return const SizedBox.shrink();

    final bool isSealed = raw == 'sealed';
    final String label = isSealed ? 'Sealed' : (raw == 'open' ? 'Open' : raw);

    final Color bg = isSealed
        ? appTheme.blue_gray_300.withAlpha(38)
        : appTheme.deep_purple_A100.withAlpha(38);

    final Color fg = isSealed ? appTheme.blue_gray_300 : appTheme.deep_purple_A100;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 6.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyleHelper.instance.body12MediumPlusJakartaSans.copyWith(
          color: fg,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildMemoryHeader(BuildContext context) {
    final CustomMemoryItem memory = widget.memory;
    // ignore: avoid_print
    print('🧩 CARD ICON RAW: ${memory.iconPath}');

    final bool showBadges = _shouldShowBadges(memory);
    final double headerHeight = showBadges ? 110.h : 74.h;

    // ✅ Use fetched member avatars (feed-safe) if available, else fall back to provided profileImages.
    final List<String> headerAvatars =
    _memberAvatars.isNotEmpty ? _memberAvatars : (memory.profileImages ?? <String>[]);

    return SizedBox(
      height: headerHeight,
      child: Container(
        padding: EdgeInsets.fromLTRB(18.h, 16.h, 18.h, 14.h),
        decoration: BoxDecoration(
          color: appTheme.background_transparent,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.h),
            topRight: Radius.circular(20.h),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(6.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222D3E),
                    borderRadius: BorderRadius.circular(18.h),
                  ),
                  width: 42.h,
                  height: 42.h,
                  child: CustomImageView(
                    imagePath: memory.iconPath ?? ImageConstant.imgFrame13Red600,
                    height: 29.h,
                    width: 29.h,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(width: 12.h),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        memory.title ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                            .copyWith(color: appTheme.gray_50),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        memory.location ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyleHelper.instance.body12MediumPlusJakartaSans,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10.h),
                _buildProfileStack(context, headerAvatars),
              ],
            ),
            if (showBadges) ...[
              SizedBox(height: 10.h),
              SizedBox(
                height: 26.h,
                child: _buildBadgesRowNoWrap(memory),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStack(BuildContext context, List<String> profileImages) {
    if (profileImages.isEmpty) return const SizedBox.shrink();

    final int count = profileImages.length > 3 ? 3 : profileImages.length;

    return SizedBox(
      width: 84.h,
      height: 36.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(count, (index) {
          final String src = profileImages[index];

          return Positioned(
            right: (index * 24).h,
            top: 0,
            bottom: 0,
            child: SizedBox(
              width: 36.h,
              height: 36.h,
              child: ClipOval(
                child: _AvatarImage(
                  imagePath: src,
                  size: 36.h,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMemoryFooter(BuildContext context) {
    return const SizedBox();
  }
}

/// Forces true cover behavior, no stretching.
class _AvatarImage extends StatelessWidget {
  final String imagePath;
  final double size;

  const _AvatarImage({
    Key? key,
    required this.imagePath,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isNetwork = imagePath.startsWith('http');

    if (isNetwork) {
      return Image.network(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: appTheme.gray_900_02,
          child: Icon(
            Icons.person,
            size: (size * 0.55),
            color: appTheme.blue_gray_300,
          ),
        ),
      );
    }

    return Image.asset(
      imagePath,
      width: size,
      height: size,
      fit: BoxFit.cover,
      alignment: Alignment.center,
    );
  }
}