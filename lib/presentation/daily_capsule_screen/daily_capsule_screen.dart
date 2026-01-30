import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';
import '../../core/models/feed_story_context.dart';
import '../../services/avatar_helper_service.dart';
import '../../services/daily_capsule_service.dart';
import '../../services/feed_service.dart';
import '../../services/story_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/standard_title_bar.dart';
import '../memory_feed_dashboard_screen/widgets/native_camera_recording_screen.dart';
import 'notifier/daily_capsule_notifier.dart';
import 'notifier/daily_capsule_state.dart';

enum _HistoryViewMode { calendar, list }

class DailyCapsuleScreen extends ConsumerStatefulWidget {
  const DailyCapsuleScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DailyCapsuleScreen> createState() => _DailyCapsuleScreenState();
}

class _DailyCapsuleScreenState extends ConsumerState<DailyCapsuleScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  static const String _prefsHistoryViewModeKey =
      'daily_capsule.history_view_mode';

  final _svc = DailyCapsuleService.instance;
  final _feedSvc = FeedService();
  final Map<String, Future<_DailyCapsuleStoryThumbData?>> _storyThumbFutures = {};
  DateTime _historyMonth = DateTime(DateTime.now().year, DateTime.now().month);
  _HistoryViewMode _historyViewMode = _HistoryViewMode.calendar;
  DateTime? _historyListMonthFilter; // year+month only

  Future<List<Map<String, dynamic>>>? _tagsFuture;
  Map<String, Map<String, dynamic>> _tagsById = {};
  String? _selectedTagFilterId;

  late final ConfettiController _streakConfetti;
  ProviderSubscription<DailyCapsuleState>? _capsuleSub;
  bool _pendingCelebrateCompletion = false;
  bool _wasCompleted = false;
  String? _celebratedLocalDateYmd;
  Timer? _midnightTimer;

  Future<_DailyCapsuleStoryThumbData?> _getStoryThumb(String storyId) {
    return _storyThumbFutures.putIfAbsent(
      storyId,
      () => _fetchStoryThumbData(storyId),
    );
  }

  Future<_DailyCapsuleStoryThumbData?> _fetchStoryThumbData(String storyId) async {
    final client = SupabaseService.instance.client;
    if (client == null) return null;

    try {
      final response = await client.from('stories').select('''
          id,
          media_type,
          thumbnail_url,
          image_url,
          contributor_id,
          user_profiles_public!stories_contributor_id_fkey(
            id,
            display_name,
            avatar_url,
            username
          ),
          user_profiles!stories_contributor_id_fkey(
            id,
            display_name,
            avatar_url,
            username
          )
        ''').eq('id', storyId).maybeSingle();

      if (response == null) return null;
      final row = Map<String, dynamic>.from(response);

      final contributor = (row['user_profiles_public'] as Map?)?.cast<String, dynamic>() ??
          (row['user_profiles'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};

      final mediaType = (row['media_type'] as String?)?.trim().toLowerCase() ?? 'image';

      final rawThumb = (row['thumbnail_url'] as String?)?.trim();
      final rawImage = (row['image_url'] as String?)?.trim();

      // Prefer thumbnail if present (especially for videos), otherwise fall back to image_url.
      final rawForCard = (rawThumb != null && rawThumb.isNotEmpty)
          ? rawThumb
          : (rawImage != null && rawImage.isNotEmpty)
              ? rawImage
              : '';

      final thumbUrl = StoryService.resolveStoryMediaUrl(rawForCard)?.trim() ?? '';

      final displayName =
          (contributor['display_name'] ?? contributor['username'] ?? '').toString().trim();
      final avatarUrl = (contributor['avatar_url'] as String?)?.trim();

      return _DailyCapsuleStoryThumbData(
        storyId: storyId,
        mediaType: mediaType,
        thumbnailUrl: thumbUrl,
        contributorName: displayName.isNotEmpty ? displayName : 'You',
        contributorAvatarUrl: AvatarHelperService.getAvatarUrl(avatarUrl),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Restore History tab view mode (calendar/list)
    unawaited(_restoreHistoryViewMode());

    _refreshTags();
    _scheduleMidnightReset();

    _streakConfetti = ConfettiController(
      duration: const Duration(milliseconds: 900),
    );

    // Trigger confetti ONLY after a user-initiated completion flow succeeds.
    // This prevents confetti from playing just because the screen loaded with existing data.
    _capsuleSub = ref.listenManual<DailyCapsuleState>(
      dailyCapsuleProvider,
      (prev, next) {
        final completed = next.todayEntry != null;

        if (_pendingCelebrateCompletion && !_wasCompleted && completed) {
          final localDate = (next.todayEntry?['local_date'] ?? _svc.todayLocalDateYmd)
              .toString()
              .trim();

          // Celebrate at most once per local day.
          if (localDate.isNotEmpty && _celebratedLocalDateYmd != localDate) {
            _streakConfetti.play();
            _celebratedLocalDateYmd = localDate;
          }

          _pendingCelebrateCompletion = false;
        }
        _wasCompleted = completed;
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize completion baseline so we never confetti on first load.
      _wasCompleted = ref.read(dailyCapsuleProvider).todayEntry != null;
      ref.read(dailyCapsuleProvider.notifier).initialize();
    });
  }

  Future<void> _restoreHistoryViewMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = (prefs.getString(_prefsHistoryViewModeKey) ?? '').trim();
      final next =
          (raw == 'list') ? _HistoryViewMode.list : _HistoryViewMode.calendar;
      if (!mounted) return;
      if (_historyViewMode == next) return;
      setState(() => _historyViewMode = next);
    } catch (_) {
      // ignore - defaults to calendar
    }
  }

  Future<void> _persistHistoryViewMode(_HistoryViewMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsHistoryViewModeKey,
        mode == _HistoryViewMode.list ? 'list' : 'calendar',
      );
    } catch (_) {
      // ignore - persistence is best-effort
    }
  }

  void _setHistoryViewMode(_HistoryViewMode mode) {
    if (_historyViewMode == mode) return;
    setState(() => _historyViewMode = mode);
    unawaited(_persistHistoryViewMode(mode));
  }

  @override
  void dispose() {
    _capsuleSub?.close();
    _capsuleSub = null;
    _midnightTimer?.cancel();
    _midnightTimer = null;
    _streakConfetti.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _scheduleMidnightReset() {
    _midnightTimer?.cancel();

    final now = DateTime.now();
    // Next local midnight
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    var delay = nextMidnight.difference(now);
    if (delay.isNegative) {
      delay = const Duration(seconds: 1);
    } else {
      // tiny buffer to ensure we've crossed midnight
      delay += const Duration(seconds: 1);
    }

    _midnightTimer = Timer(delay, () async {
      if (!mounted) return;

      // New local day: reset per-day confetti baseline so celebration can happen again.
      _pendingCelebrateCompletion = false;
      _wasCompleted = false;

      await ref.read(dailyCapsuleProvider.notifier).refresh();
      if (!mounted) return;
      setState(() {});

      // Schedule the next midnight.
      _scheduleMidnightReset();
    });
  }

  void _refreshTags() {
    // fire-and-forget; UI uses FutureBuilder
    _tagsFuture = _svc.fetchUserTags(limit: 200).then((rows) {
      final map = <String, Map<String, dynamic>>{};
      for (final r in rows) {
        final id = (r['id'] ?? '').toString();
        if (id.isEmpty) continue;
        map[id] = Map<String, dynamic>.from(r);
      }
      _tagsById = map;
      return rows;
    });
  }

  Color _parseHexColor(String? hex, {required Color fallback}) {
    final h = (hex ?? '').trim();
    if (h.isEmpty) return fallback;
    var v = h.startsWith('#') ? h.substring(1) : h;
    if (v.length == 6) v = 'FF$v';
    if (v.length != 8) return fallback;
    final parsed = int.tryParse(v, radix: 16);
    if (parsed == null) return fallback;
    return Color(parsed);
  }

  Color _tagColorForId(String tagId) {
    final hex = _tagsById[tagId]?['color_hex']?.toString().trim();
    return _parseHexColor(hex, fallback: appTheme.deep_purple_A100);
  }

  DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  String? _formatCompletedAt(dynamic completedAtRaw) {
    final dt = _parseDateTime(completedAtRaw)?.toLocal();
    if (dt == null) return null;

    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;

    final time = TimeOfDay.fromDateTime(dt).format(context);
    if (isToday) return 'Completed at $time';

    final date = MaterialLocalizations.of(context).formatMediumDate(dt);
    return 'Completed $date · $time';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // If user just shared a story, we’ll land back here and refresh.
      ref.read(dailyCapsuleProvider.notifier).refresh();
      // Also re-schedule in case the device time/day changed while backgrounded.
      _scheduleMidnightReset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dailyCapsuleProvider);
    final completedToday = state.todayEntry != null;

    return Scaffold(
      backgroundColor: appTheme.gray_900_02,
      body: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.h),
                child: StandardTitleBar(
                  leadingIcon: Icons.auto_awesome_rounded,
                  title: 'Daily Capsule',
                  trailing: _buildStreakPill(state.streakCount),
                ),
              ),
              SizedBox(height: 10.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.h),
                child: _buildSubtitle(completedToday: completedToday),
              ),
              SizedBox(height: 14.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.h),
                child: _buildTabs(),
              ),
              SizedBox(height: 12.h),
              Expanded(
                child: RefreshIndicator(
                  color: appTheme.deep_purple_A100,
                  backgroundColor: appTheme.gray_900_01,
                  displacement: 30,
                  onRefresh: () => ref.read(dailyCapsuleProvider.notifier).refresh(),
                  child: TabBarView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildTodayTab(state),
                      _buildHistoryTab(state),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle({required bool completedToday}) {
    return Text(
      completedToday
          ? 'You’re done for today. Come back tomorrow.'
          : 'Complete one thing today to keep your streak.',
      style: TextStyleHelper.instance.body14RegularPlusJakartaSans
          .copyWith(color: appTheme.gray_50.withAlpha(153)),
    );
  }

  Widget _buildStreakPill(int streak) {
    final label = streak <= 0 ? '0 day streak' : '$streak day streak';
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 6.h),
          decoration: BoxDecoration(
            color: appTheme.deep_purple_A100.withAlpha(26),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: appTheme.deep_purple_A100.withAlpha(80)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_fire_department_rounded,
                  size: 16.h, color: appTheme.deep_purple_A100),
              SizedBox(width: 6.h),
              Text(
                label,
                style: TextStyleHelper.instance.body12BoldPlusJakartaSans
                    .copyWith(color: appTheme.gray_50),
              ),
            ],
          ),
        ),
        // Confetti burst anchored to the pill (non-interactive)
        Positioned(
          left: -60.h,
          right: -60.h,
          top: -70.h,
          bottom: -12.h,
          child: IgnorePointer(
            ignoring: true,
            child: ConfettiWidget(
              confettiController: _streakConfetti,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              emissionFrequency: 0.20,
              numberOfParticles: 18,
              minBlastForce: 6,
              maxBlastForce: 14,
              gravity: 0.35,
              colors: [
                appTheme.deep_purple_A100,
                appTheme.gray_50,
                appTheme.green_500,
                appTheme.blue_gray_300,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return SizedBox(
      width: double.infinity, // ✅ force full width
      child: Container(
        padding: EdgeInsets.all(3.h),
        decoration: BoxDecoration(
          color: appTheme.gray_900,
          borderRadius: BorderRadius.circular(22.h),
        ),
        child: TabBar(
          isScrollable: false, // ✅ equal width tabs
          indicatorSize: TabBarIndicatorSize.tab, // ✅ indicator fills the whole tab
          indicatorPadding: EdgeInsets.zero,

          indicator: BoxDecoration(
            color: appTheme.deep_purple_A100,
            borderRadius: BorderRadius.circular(18.h),
          ),
          dividerColor: Colors.transparent,

          labelColor: appTheme.gray_900_02,
          unselectedLabelColor: appTheme.gray_50,
          labelStyle: TextStyleHelper.instance.body14BoldPlusJakartaSans,
          unselectedLabelStyle:
          TextStyleHelper.instance.body14RegularPlusJakartaSans,

          // ✅ Do NOT wrap these Tabs in outer Padding if you want full-width
          tabs: [
            Tab(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: const Text('Today'),
              ),
            ),
            Tab(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: const Text('History'),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildTodayTab(DailyCapsuleState state) {
    if (state.isLoading) {
      return _buildLoadingScrollable();
    }

    final todayStoryId = (state.todayEntry?['story_id'] ?? '').toString().trim();
    final todayType = (state.todayEntry?['completion_type'] ?? '').toString();
    final bool previewInline =
        (todayType == 'instant_story' || todayType == 'memory_post') &&
            todayStoryId.isNotEmpty;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(16.h, 4.h, 16.h, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.todayEntry != null) ...[
            _sectionTitle('Today’s capsule (tap any option to change)'),
            SizedBox(height: 10.h),
            _buildCompletedTodayInline(state.todayEntry!),
            // Instant story preview is rendered inside the capsule container.
            if (todayStoryId.isNotEmpty && !previewInline) ...[
              SizedBox(height: 12.h),
              _buildStoryThumb(storyId: todayStoryId),
            ],
            SizedBox(height: 14.h),
          ],

          _sectionTitle('Pick your Daily Capsule'),
          SizedBox(height: 10.h),
          _actionCard(
            title: 'Mood',
            subtitle: 'Tap one emoji to capture today.',
            icon: Icons.emoji_emotions_outlined,
            child: _moodRow(state),
          ),
          SizedBox(height: 12.h),
          _actionCard(
            title: 'Instant story',
            subtitle: 'Private story — just for you.',
            icon: Icons.camera_alt_outlined,
            trailing: _actionButton(
              label: 'Create',
              disabled: state.isCompleting,
              onTap: _onInstantStory,
            ),
          ),
          SizedBox(height: 12.h),
          _actionCard(
            title: 'Post to a memory',
            subtitle: 'Counts as today’s capsule.',
            icon: Icons.photo_library_outlined,
            trailing: _actionButton(
              label: 'Select',
              disabled: state.isCompleting,
              onTap: _onPostToMemory,
            ),
          ),
          if (state.errorMessage != null) ...[
            SizedBox(height: 16.h),
            Text(
              state.errorMessage!,
              style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                  .copyWith(color: appTheme.red_500),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryTab(DailyCapsuleState state) {
    if (state.isLoading) {
      return _buildLoadingScrollable();
    }

    final now = DateTime.now();
    final todayKey = _ymd(now.year, now.month, now.day);

    // Map entries by local_date (YYYY-MM-DD) for fast calendar lookup
    final Map<String, Map<String, dynamic>> byDate = {};
    for (final raw in state.archiveEntries) {
      final e = Map<String, dynamic>.from(raw);
      final k = (e['local_date'] ?? '').toString().trim();
      if (k.isEmpty) continue;
      byDate[k] = e;
    }
    if (state.todayEntry != null) {
      final e = Map<String, dynamic>.from(state.todayEntry!);
      final k = (e['local_date'] ?? todayKey).toString().trim();
      if (k.isNotEmpty) byDate[k] = e;
    }

    if (_historyViewMode == _HistoryViewMode.list) {
      return _buildHistoryListView(byDate: byDate);
    }

    // Calendar view (existing)
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(16.h, 4.h, 16.h, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8.h),
          _buildHistoryViewToggleRow(isList: false),
          SizedBox(height: 10.h),
          _buildTagFilterRow(),
          SizedBox(height: 10.h),
          _buildHistoryHeader(),
          SizedBox(height: 10.h),
          _buildWeekdayHeader(),
          SizedBox(height: 8.h),
          _buildMonthGrid(
            month: _historyMonth,
            todayKey: todayKey,
            byDate: byDate,
          ),
          SizedBox(height: 14.h),
          _buildTaggedStoriesSection(byDate: byDate),
          if (byDate.isEmpty) ...[
            SizedBox(height: 18.h),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.h),
                child: Text(
                  'No Daily Capsules yet. Start today.',
                  style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                      .copyWith(color: appTheme.gray_50.withAlpha(153)),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  DateTime? _parseYmdToDate(String ymd) {
    final s = ymd.trim();
    if (s.isEmpty) return null;
    final parts = s.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  String _monthKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}';

  String _monthLabelFromKey(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return key;
    final y = int.tryParse(parts[0]) ?? DateTime.now().year;
    final m = int.tryParse(parts[1]) ?? DateTime.now().month;
    return _monthYearLabel(DateTime(y, m, 1));
  }

  String _dayLabel(DateTime d) {
    const w = <String>['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const m = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final wd = w[d.weekday % 7];
    final mm = m[(d.month - 1).clamp(0, 11)];
    return '$wd · $mm ${d.day}';
  }

  Widget _buildHistoryViewToggleRow({required bool isList, List<String>? monthKeys}) {
    final canPickMonth = isList;
    final filter = _historyListMonthFilter;
    final filterLabel =
        filter == null ? 'All months' : _monthYearLabel(DateTime(filter.year, filter.month, 1));

    return Row(
      children: [
        _historyViewToggleButton(
          icon: Icons.calendar_month_outlined,
          selected: !isList,
          onTap: () => _setHistoryViewMode(_HistoryViewMode.calendar),
        ),
        SizedBox(width: 8.h),
        _historyViewToggleButton(
          icon: Icons.view_agenda_outlined,
          selected: isList,
          onTap: () => _setHistoryViewMode(_HistoryViewMode.list),
        ),
        const Spacer(),
        if (canPickMonth)
          CustomButton(
            text: filterLabel,
            onPressed: () => _openHistoryMonthFilterPicker(
              monthKeys: monthKeys ?? const [],
            ),
            size: CustomButtonSize.mini,
            buttonStyle: CustomButtonStyle.outlinePrimary,
            buttonTextStyle: CustomButtonTextStyle.bodySmall,
          ),
      ],
    );
  }

  Widget _historyViewToggleButton({
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.h,
        height: 32.h,
        decoration: BoxDecoration(
          color: selected ? appTheme.deep_purple_A100.withAlpha(36) : appTheme.blue_gray_900_01,
          borderRadius: BorderRadius.circular(12.h),
          border: Border.all(
            color: selected ? appTheme.deep_purple_A100.withAlpha(160) : appTheme.gray_50.withAlpha(18),
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18.h,
          color: selected ? appTheme.gray_50 : appTheme.blue_gray_300,
        ),
      ),
    );
  }

  Future<void> _openHistoryMonthFilterPicker({required List<String> monthKeys}) async {
    if (!mounted) return;
    final keys = monthKeys.toList();
    keys.sort((a, b) => b.compareTo(a)); // newest first

    final selectedKey = _historyListMonthFilter == null
        ? null
        : _monthKey(DateTime(_historyListMonthFilter!.year, _historyListMonthFilter!.month, 1));

    final res = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: appTheme.gray_900_02,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.h)),
          ),
          padding: EdgeInsets.fromLTRB(16.h, 12.h, 16.h, 16.h),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.h,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: appTheme.blue_gray_300,
                      borderRadius: BorderRadius.circular(2.h),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Filter by month',
                  style: TextStyleHelper.instance.title20BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                ),
                SizedBox(height: 12.h),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.55),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: keys.length + 1,
                    separatorBuilder: (_, __) => SizedBox(height: 8.h),
                    itemBuilder: (context, idx) {
                      if (idx == 0) {
                        final selected = selectedKey == null;
                        return GestureDetector(
                          onTap: () => Navigator.pop(context, null),
                          child: Container(
                            padding: EdgeInsets.all(14.h),
                            decoration: BoxDecoration(
                              color: appTheme.blue_gray_900_01,
                              borderRadius: BorderRadius.circular(14.h),
                              border: Border.all(
                                color: selected
                                    ? appTheme.deep_purple_A100
                                    : appTheme.gray_50.withAlpha(18),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'All months',
                                    style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                                        .copyWith(color: appTheme.gray_50),
                                  ),
                                ),
                                if (selected)
                                  Icon(Icons.check,
                                      color: appTheme.deep_purple_A100, size: 18.h),
                              ],
                            ),
                          ),
                        );
                      }

                      final key = keys[idx - 1];
                      final selected = key == selectedKey;
                      return GestureDetector(
                        onTap: () => Navigator.pop(context, key),
                        child: Container(
                          padding: EdgeInsets.all(14.h),
                          decoration: BoxDecoration(
                            color: appTheme.blue_gray_900_01,
                            borderRadius: BorderRadius.circular(14.h),
                            border: Border.all(
                              color: selected
                                  ? appTheme.deep_purple_A100
                                  : appTheme.gray_50.withAlpha(18),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _monthLabelFromKey(key),
                                  style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                                      .copyWith(color: appTheme.gray_50),
                                ),
                              ),
                              if (selected)
                                Icon(Icons.check,
                                    color: appTheme.deep_purple_A100, size: 18.h),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    if (res == null && selectedKey == null) return;
    if (res == selectedKey) return;

    if (res == null) {
      setState(() => _historyListMonthFilter = null);
      return;
    }

    final parts = res.split('-');
    if (parts.length != 2) return;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (y == null || m == null) return;
    setState(() => _historyListMonthFilter = DateTime(y, m, 1));
  }

  Widget _buildHistoryListView({required Map<String, Map<String, dynamic>> byDate}) {
    // Flatten unique entries from byDate.
    final entries = byDate.values.map((e) => Map<String, dynamic>.from(e)).toList();

    entries.sort((a, b) {
      final ad = _parseYmdToDate((a['local_date'] ?? '').toString()) ?? DateTime(1970);
      final bd = _parseYmdToDate((b['local_date'] ?? '').toString()) ?? DateTime(1970);
      return bd.compareTo(ad);
    });

    // Tag filter (History tab filter chips)
    final tagFilterId = _selectedTagFilterId;
    final filteredByTag = tagFilterId == null
        ? entries
        : entries.where((e) => (e['tag_id'] ?? '').toString().trim() == tagFilterId).toList();

    // Month filter (list mode)
    final monthFilter = _historyListMonthFilter;
    final filtered = monthFilter == null
        ? filteredByTag
        : filteredByTag.where((e) {
            final d = _parseYmdToDate((e['local_date'] ?? '').toString());
            return d != null && d.year == monthFilter.year && d.month == monthFilter.month;
          }).toList();

    // Month keys available (for picker)
    final monthKeys = <String>{};
    for (final e in filteredByTag) {
      final d = _parseYmdToDate((e['local_date'] ?? '').toString());
      if (d == null) continue;
      monthKeys.add(_monthKey(DateTime(d.year, d.month, 1)));
    }

    // Group by month key, keeping order newest->oldest
    final Map<String, List<Map<String, dynamic>>> byMonth = {};
    for (final e in filtered) {
      final d = _parseYmdToDate((e['local_date'] ?? '').toString());
      if (d == null) continue;
      final key = _monthKey(DateTime(d.year, d.month, 1));
      (byMonth[key] ??= []).add(e);
    }

    final orderedMonthKeys = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16.h, 12.h, 16.h, 10.h),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHistoryViewToggleRow(
                  isList: true,
                  monthKeys: monthKeys.toList(),
                ),
                SizedBox(height: 10.h),
                _buildTagFilterRow(),
              ],
            ),
          ),
        ),
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.h),
                child: Text(
                  'No Daily Capsules yet.',
                  style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                      .copyWith(color: appTheme.gray_50.withAlpha(153)),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          ...orderedMonthKeys.expand((monthKey) {
            final monthEntries = byMonth[monthKey] ?? const [];
            final monthStoryEntries = monthEntries
                .where((e) => (e['story_id'] ?? '').toString().trim().isNotEmpty)
                .toList();
            monthStoryEntries.sort((a, b) {
              final ad = _parseYmdToDate((a['local_date'] ?? '').toString()) ?? DateTime(1970);
              final bd = _parseYmdToDate((b['local_date'] ?? '').toString()) ?? DateTime(1970);
              return ad.compareTo(bd); // earliest -> latest for the month
            });
            final monthStoryIds = <String>[];
            final seen = <String>{};
            for (final e in monthStoryEntries) {
              final id = (e['story_id'] ?? '').toString().trim();
              if (id.isEmpty || seen.contains(id)) continue;
              seen.add(id);
              monthStoryIds.add(id);
            }
            return <Widget>[
              SliverPersistentHeader(
                pinned: true,
                delegate: _MonthStickyHeaderDelegate(
                  title: _monthLabelFromKey(monthKey),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.h, 8.h, 16.h, 10.h),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, idx) {
                      final entryIdx = idx ~/ 2;
                      final isSeparator = idx.isOdd;
                      if (isSeparator) return SizedBox(height: 10.h);
                      return _buildHistoryListItem(
                        monthEntries[entryIdx],
                        monthStoryIds: monthStoryIds,
                      );
                    },
                    childCount: monthEntries.isEmpty ? 0 : (monthEntries.length * 2 - 1),
                  ),
                ),
              ),
            ];
          }),
        SliverToBoxAdapter(child: SizedBox(height: 24.h)),
      ],
    );
  }

  Widget _buildHistoryListItem(
    Map<String, dynamic> entry, {
    List<String>? monthStoryIds,
  }) {
    final ymd = (entry['local_date'] ?? '').toString().trim();
    final d = _parseYmdToDate(ymd) ?? DateTime.now();
    final type = (entry['completion_type'] ?? '').toString();
    final mood = (entry['mood_emoji'] ?? '').toString();
    final storyId = (entry['story_id'] ?? '').toString().trim();
    final hasStory = storyId.isNotEmpty;
    final title = type == 'mood'
        ? 'Mood'
        : (type == 'instant_story' ? 'Instant story' : 'Posted to memory');
    final detail = type == 'mood' && mood.isNotEmpty ? mood : '';

    Future<void> onTap() async {
      if (hasStory) {
        await _openStoryViewer(storyId, storyIds: monthStoryIds);
        return;
      }
      if (detail.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mood: $detail'),
          ),
        );
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.h),
        decoration: BoxDecoration(
          color: appTheme.blue_gray_900_01,
          borderRadius: BorderRadius.circular(16.h),
          border: Border.all(color: appTheme.gray_50.withAlpha(18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 76.h,
              padding: EdgeInsets.only(top: 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dayLabel(d),
                    style: TextStyleHelper.instance.body12BoldPlusJakartaSans
                        .copyWith(color: appTheme.gray_50),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    (_formatCompletedAt(entry['completed_at']) ?? '').replaceFirst('Completed ', ''),
                    style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                        .copyWith(color: appTheme.gray_50.withAlpha(153)),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.h),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                        .copyWith(color: appTheme.gray_50),
                  ),
                  if (detail.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Text(
                      detail,
                      style: TextStyle(fontSize: 20.h),
                    ),
                  ],
                ],
              ),
            ),
            if (hasStory) ...[
              SizedBox(width: 10.h),
              _buildStoryThumb(storyId: storyId, storyIds: monthStoryIds),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tagChip({
    required String label,
    required bool selected,
    Color? color,
    required VoidCallback onTap,
  }) {
    final c = color ?? appTheme.deep_purple_A100;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 7.h),
        decoration: BoxDecoration(
          color: selected ? c.withAlpha(36) : appTheme.gray_900_02.withAlpha(128),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? c.withAlpha(160) : appTheme.gray_50.withAlpha(18),
          ),
        ),
        child: Text(
          label,
          style: TextStyleHelper.instance.body12MediumPlusJakartaSans.copyWith(
            color: appTheme.gray_50,
          ),
        ),
      ),
    );
  }

  Widget _tagPlusButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34.h,
        height: 34.h,
        decoration: BoxDecoration(
          color: appTheme.blue_gray_900_01,
          borderRadius: BorderRadius.circular(12.h),
          border: Border.all(color: appTheme.gray_50.withAlpha(18)),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.add, color: appTheme.gray_50, size: 18.h),
      ),
    );
  }

  Widget _buildTagFilterRow() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _tagsFuture,
      builder: (context, snap) {
        final tags = snap.data ?? const [];
        if (tags.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 38.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _tagChip(
                label: 'All',
                selected: _selectedTagFilterId == null,
                color: appTheme.deep_purple_A100,
                onTap: () => setState(() => _selectedTagFilterId = null),
              ),
              SizedBox(width: 8.h),
              ...tags.map((t) {
                final id = (t['id'] ?? '').toString();
                final name = (t['name'] ?? '').toString();
                final hex = (t['color_hex'] ?? '').toString();
                final c = _parseHexColor(hex, fallback: appTheme.deep_purple_A100);
                if (id.isEmpty || name.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: EdgeInsets.only(right: 8.h),
                  child: _tagChip(
                    label: name,
                    selected: _selectedTagFilterId == id,
                    color: c,
                    onTap: () => setState(() => _selectedTagFilterId = id),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaggedStoriesSection({required Map<String, Map<String, dynamic>> byDate}) {
    final filterId = _selectedTagFilterId;
    if (filterId == null) return const SizedBox.shrink();

    final entries = byDate.values.where((e) {
      final tagId = (e['tag_id'] ?? '').toString().trim();
      final storyId = (e['story_id'] ?? '').toString().trim();
      return tagId == filterId && storyId.isNotEmpty;
    }).toList();

    if (entries.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 4.h),
        child: Text(
          'No stories tagged with this yet.',
          style: TextStyleHelper.instance.body12MediumPlusJakartaSans
              .copyWith(color: appTheme.gray_50.withAlpha(153)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Tagged stories'),
        SizedBox(height: 10.h),
        SizedBox(
          height: 120.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: entries.length,
            separatorBuilder: (_, __) => SizedBox(width: 10.h),
            itemBuilder: (context, idx) {
              final storyId = (entries[idx]['story_id'] ?? '').toString().trim();
              return _buildStoryThumb(storyId: storyId);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openTagPicker({required String currentTagId}) async {
    if (!mounted) return;

    // Ensure we have a future to show
    _tagsFuture ??= _svc.fetchUserTags(limit: 200);

    final controller = TextEditingController();
    String selectedHex = '#8B5CF6';
    bool isCreateMode = false;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final swatches = <String>[
              '#8B5CF6', // purple
              '#EF4444', // red
              '#F97316', // orange
              '#F59E0B', // amber
              '#22C55E', // green
              '#06B6D4', // cyan
              '#3B82F6', // blue
              '#EC4899', // pink
            ];

            Widget swatchDot(String hex) {
              final c = _parseHexColor(hex, fallback: appTheme.deep_purple_A100);
              final selected = selectedHex == hex;
              return GestureDetector(
                onTap: () => setModalState(() => selectedHex = hex),
                child: Container(
                  width: 32.h,
                  height: 32.h,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? appTheme.gray_50 : Colors.white.withAlpha(60),
                      width: selected ? 3 : 1.5,
                    ),
                  ),
                ),
              );
            }

            final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
            final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Container(
                constraints: BoxConstraints(maxHeight: maxHeight),
                decoration: BoxDecoration(
                  color: appTheme.gray_900_02,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24.h)),
                ),
                padding: EdgeInsets.fromLTRB(16.h, 12.h, 16.h, 16.h),
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: Column(
                    // Hug content in both modes; scrollables handle overflow.
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                Center(
                  child: Container(
                    width: 40.h,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: appTheme.blue_gray_300,
                      borderRadius: BorderRadius.circular(2.h),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    if (isCreateMode)
                      GestureDetector(
                        onTap: () => setModalState(() => isCreateMode = false),
                        child: Container(
                          width: 40.h,
                          height: 40.h,
                          decoration: BoxDecoration(
                            color: appTheme.blue_gray_900_01,
                            borderRadius: BorderRadius.circular(12.h),
                          ),
                          alignment: Alignment.center,
                          child: Icon(Icons.chevron_left,
                              color: appTheme.gray_50, size: 22.h),
                        ),
                      ),
                    if (isCreateMode) SizedBox(width: 12.h),
                    Expanded(
                      child: Text(
                        isCreateMode ? 'Create a tag' : 'Select a tag',
                        style: TextStyleHelper.instance.title20BoldPlusJakartaSans
                            .copyWith(color: appTheme.gray_50),
                      ),
                    ),
                    if (!isCreateMode) ...[
                      SizedBox(width: 10.h),
                      CustomButton(
                        text: 'Create',
                        onPressed: () => setModalState(() => isCreateMode = true),
                        size: CustomButtonSize.mini,
                        buttonStyle: CustomButtonStyle.outlinePrimary,
                        buttonTextStyle: CustomButtonTextStyle.bodySmall,
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 10.h),
                      if (!isCreateMode) ...[
                        Text(
                          'Tap a tag to apply it to today.',
                          style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                              .copyWith(color: appTheme.gray_50.withAlpha(153)),
                        ),
                        SizedBox(height: 12.h),

                        // ✅ FIX: don't use Expanded here (it creates a huge empty area when tags are few).
                        // Constrain height so list hugs content when short, and scrolls when long.
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                          ),
                          child: FutureBuilder<List<Map<String, dynamic>>>(
                            future: _tagsFuture,
                            builder: (context, snap) {
                              final tags = snap.data ?? const [];
                              if (tags.isEmpty) {
                                return Center(
                                  child: Text(
                                    'No tags yet.',
                                    style: TextStyleHelper.instance
                                        .body12MediumPlusJakartaSans
                                        .copyWith(color: appTheme.gray_50.withAlpha(153)),
                                  ),
                                );
                              }

                              return ListView.separated(
                                shrinkWrap: true,
                                itemCount: tags.length,
                                separatorBuilder: (_, __) => SizedBox(height: 8.h),
                                itemBuilder: (context, idx) {
                                  final t = tags[idx];
                                  final id = (t['id'] ?? '').toString();
                                  final name = (t['name'] ?? '').toString();
                                  final hex = (t['color_hex'] ?? '').toString();
                                  final c =
                                  _parseHexColor(hex, fallback: appTheme.deep_purple_A100);
                                  final selected = id.isNotEmpty && id == currentTagId;

                                  return GestureDetector(
                                    onTap: () => Navigator.pop(context, t),
                                    child: Container(
                                      padding: EdgeInsets.all(14.h),
                                      decoration: BoxDecoration(
                                        color: appTheme.blue_gray_900_01,
                                        borderRadius: BorderRadius.circular(14.h),
                                        border: Border.all(
                                          color: selected
                                              ? appTheme.deep_purple_A100
                                              : appTheme.gray_50.withAlpha(18),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 14.h,
                                            height: 14.h,
                                            decoration: BoxDecoration(
                                              color: c,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          SizedBox(width: 10.h),
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: TextStyleHelper.instance
                                                  .body14BoldPlusJakartaSans
                                                  .copyWith(color: appTheme.gray_50),
                                            ),
                                          ),
                                          if (selected)
                                            Icon(
                                              Icons.check,
                                              color: appTheme.deep_purple_A100,
                                              size: 18.h,
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),

                      ] else ...[
                        // Use a shrink-wrapping ListView so the sheet height is dynamic,
                        // but still scrollable when keyboard is up.
                        ListView(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            TextField(
                              controller: controller,
                              style: TextStyleHelper.instance.body14MediumPlusJakartaSans
                                  .copyWith(color: appTheme.gray_50),
                              decoration: InputDecoration(
                                hintText: 'Tag name (e.g., Gym)',
                                hintStyle: TextStyleHelper.instance
                                    .body14MediumPlusJakartaSans
                                    .copyWith(color: appTheme.gray_50.withAlpha(120)),
                                filled: true,
                                fillColor: appTheme.blue_gray_900_01,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14.h),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              'Color',
                              style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                                  .copyWith(color: appTheme.gray_50),
                            ),
                            SizedBox(height: 10.h),
                            Wrap(
                              spacing: 10.h,
                              runSpacing: 10.h,
                              children: swatches.map(swatchDot).toList(),
                            ),
                            SizedBox(height: 12.h),
                            CustomButton(
                              text: 'Create',
                              onPressed: () async {
                                final created = await _svc.createOrGetUserTag(
                                  controller.text,
                                  colorHex: selectedHex,
                                );
                                if (created == null) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                          'Could not create tag. Try again.'),
                                    ),
                                  );
                                  return;
                                }
                                if (!context.mounted) return;
                                Navigator.pop(context, created);
                              },
                              buttonStyle: CustomButtonStyle.fillPrimary,
                              buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                              height: 44.h,
                            ),
                          ],
                        ),
                      ],
                  ],
                ),
              ),
              ),
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (result == null) return;

    final id = (result['id'] ?? '').toString().trim();
    final name = (result['name'] ?? '').toString().trim();
    if (id.isEmpty) return;

    // If this came from "Create", refresh tag list cache
    if (name.isNotEmpty) {
      _refreshTags();
      setState(() {});
    }

    final ok = await _svc.setTodayTag(tagId: id);
    if (!mounted) return;
    if (ok) {
      ref.read(dailyCapsuleProvider.notifier).refresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not set tag. Try again.'),
        ),
      );
    }
  }

  Widget _buildHistoryHeader() {
    final label = _monthYearLabel(_historyMonth);

    return Row(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _historyMonth = _addMonths(_historyMonth, -1);
            });
          },
          child: Container(
            width: 40.h,
            height: 40.h,
            decoration: BoxDecoration(
              color: appTheme.blue_gray_900_01,
              borderRadius: BorderRadius.circular(12.h),
            ),
            child: Icon(Icons.chevron_left, color: appTheme.gray_50, size: 22.h),
          ),
        ),
        SizedBox(width: 12.h),
        Expanded(
          child: Text(
            label,
            style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                .copyWith(color: appTheme.gray_50),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(width: 12.h),
        GestureDetector(
          onTap: () {
            setState(() {
              _historyMonth = _addMonths(_historyMonth, 1);
            });
          },
          child: Container(
            width: 40.h,
            height: 40.h,
            decoration: BoxDecoration(
              color: appTheme.blue_gray_900_01,
              borderRadius: BorderRadius.circular(12.h),
            ),
            child:
                Icon(Icons.chevron_right, color: appTheme.gray_50, size: 22.h),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader() {
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      children: labels
          .map(
            (t) => Expanded(
              child: Center(
                child: Text(
                  t,
                  style: TextStyleHelper.instance.body12BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50.withAlpha(153)),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMonthGrid({
    required DateTime month,
    required String todayKey,
    required Map<String, Map<String, dynamic>> byDate,
  }) {
    final y = month.year;
    final m = month.month;

    final first = DateTime(y, m, 1);
    final daysInMonth = _daysInMonth(y, m);
    final leadingBlank = first.weekday % 7; // Sunday=0, Monday=1, ... Saturday=6
    final totalCells = ((leadingBlank + daysInMonth + 6) ~/ 7) * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 6.h,
        mainAxisSpacing: 6.h,
        childAspectRatio: 1,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final dayIndex = index - leadingBlank + 1;
        if (dayIndex < 1 || dayIndex > daysInMonth) {
          return const SizedBox.shrink();
        }

        final key = _ymd(y, m, dayIndex);
        final entry = byDate[key];
        final isToday = key == todayKey;
        final selectedFilterId = _selectedTagFilterId;
        final entryTagId = (entry?['tag_id'] ?? '').toString().trim();
        final bool matchesFilter = selectedFilterId != null &&
            entryTagId.isNotEmpty &&
            entryTagId == selectedFilterId;
        final Color borderColor = matchesFilter
            ? _tagColorForId(selectedFilterId)
            : isToday
                ? appTheme.deep_purple_A100
                : appTheme.gray_50.withAlpha(18);

        final type = (entry?['completion_type'] ?? '').toString();
        final mood = (entry?['mood_emoji'] ?? '').toString();
        final storyId = (entry?['story_id'] ?? '').toString().trim();
        final hasStory = storyId.isNotEmpty;

        Future<void> onTap() async {
          if (hasStory) {
            _openStoryViewer(storyId);
            return;
          }
          if ((type == 'mood') && mood.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Mood: $mood'),
              ),
            );
          }
        }

        return GestureDetector(
          onTap: entry == null ? null : onTap,
          child: Container(
            decoration: BoxDecoration(
              color: appTheme.blue_gray_900_01,
              borderRadius: BorderRadius.circular(10.h),
              border: Border.all(
                color: borderColor,
                width: (isToday || matchesFilter) ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.h),
              child: Stack(
                children: [
                  // Story thumbnail as the tile background.
                  if (hasStory)
                    Positioned.fill(
                      child: FutureBuilder<_DailyCapsuleStoryThumbData?>(
                        future: _getStoryThumb(storyId),
                        builder: (context, snap) {
                          final url = (snap.data?.thumbnailUrl ?? '').trim();
                          if (url.isEmpty) {
                            return Container(color: appTheme.gray_900_02);
                          }
                          return CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: appTheme.gray_900_02),
                            errorWidget: (_, __, ___) =>
                                Container(color: appTheme.gray_900_02),
                          );
                        },
                      ),
                    ),

                  // Slight dark overlay for readability when a thumbnail is present.
                  if (hasStory)
                    Positioned.fill(
                      child: Container(color: Colors.black.withAlpha(60)),
                    ),

                  // Day number
                  Positioned(
                    top: 6.h,
                    left: 6.h,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 6.h, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: hasStory
                            ? Colors.black.withAlpha(120)
                            : appTheme.gray_900_02.withAlpha(128),
                        borderRadius: BorderRadius.circular(8.h),
                      ),
                      child: Text(
                        '$dayIndex',
                        style: TextStyleHelper.instance.body12BoldPlusJakartaSans
                            .copyWith(color: appTheme.gray_50),
                      ),
                    ),
                  ),

                  // Mood emoji centered
                  if (entry != null && type == 'mood')
                    Center(
                      child: Text(
                        mood.isNotEmpty ? mood : '🙂',
                        style: TextStyle(fontSize: 18.h),
                      ),
                    ),

                  // Play icon for videos
                  if (hasStory)
                    Positioned(
                      right: 6.h,
                      bottom: 6.h,
                      child: FutureBuilder<_DailyCapsuleStoryThumbData?>(
                        future: _getStoryThumb(storyId),
                        builder: (context, snap) {
                          final isVideo = (snap.data?.mediaType ?? '') == 'video';
                          if (!isVideo) return const SizedBox.shrink();
                          return Container(
                            width: 22.h,
                            height: 22.h,
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(140),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withAlpha(40),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              size: 16.h,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _ymd(int y, int m, int d) {
    return '${y.toString().padLeft(4, '0')}-'
        '${m.toString().padLeft(2, '0')}-'
        '${d.toString().padLeft(2, '0')}';
  }

  int _daysInMonth(int year, int month) {
    final firstNext = (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    return firstNext.subtract(const Duration(days: 1)).day;
  }

  DateTime _addMonths(DateTime base, int delta) {
    int y = base.year;
    int m = base.month + delta;
    while (m <= 0) {
      m += 12;
      y -= 1;
    }
    while (m > 12) {
      m -= 12;
      y += 1;
    }
    return DateTime(y, m, 1);
  }

  String _monthYearLabel(DateTime d) {
    const months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final name = months[(d.month - 1).clamp(0, 11)];
    return '$name ${d.year}';
  }

  Widget _buildCompletedTodayInline(Map<String, dynamic> entry) {
    final type = (entry['completion_type'] ?? '').toString();
    final mood = (entry['mood_emoji'] ?? '').toString();
    final storyId = (entry['story_id'] ?? '').toString().trim();
    final completedAtLabel = _formatCompletedAt(entry['completed_at']);
    final tagId = (entry['tag_id'] ?? '').toString().trim();
    final tagRow = tagId.isEmpty ? null : _tagsById[tagId];
    final String? selectedName =
        (tagRow == null) ? null : (tagRow['name']?.toString());
    final Color tagColor =
        tagId.isEmpty ? appTheme.deep_purple_A100 : _tagColorForId(tagId);

    final title = type == 'mood'
        ? 'Mood captured'
        : (type == 'instant_story' ? 'Instant story posted' : 'Posted to a memory');

    final leading = type == 'mood'
        ? (mood.isNotEmpty ? mood : '🙂')
        : '✅';

    final showInlineStoryPreview = (type == 'instant_story' || type == 'memory_post') &&
        storyId.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: appTheme.gray_900,
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(
          color: appTheme.deep_purple_A100,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48.h,
                height: 48.h,
                decoration: BoxDecoration(
                  color: appTheme.deep_purple_A100.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  leading,
                  style: TextStyle(fontSize: 20.h),
                ),
              ),
              SizedBox(width: 12.h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                          .copyWith(color: appTheme.gray_50),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'You can change it anytime today.',
                      style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                          .copyWith(color: appTheme.gray_50.withAlpha(153)),
                    ),
                    if (completedAtLabel != null) ...[
                      SizedBox(height: 6.h),
                      Text(
                        completedAtLabel,
                        style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                            .copyWith(color: appTheme.gray_50.withAlpha(153)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (showInlineStoryPreview) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: _buildStoryThumb(storyId: storyId),
            ),
            SizedBox(height: 12.h),
          ],
          Container(height: 1, color: appTheme.gray_50.withAlpha(12)),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: tagId.isEmpty
                    ? Text(
                        'Add a tag',
                        style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                            .copyWith(color: appTheme.gray_50.withAlpha(153)),
                      )
                    : Row(
                        children: [
                          _tagChip(
                            label: selectedName ?? 'Tag',
                            selected: true,
                            color: tagColor,
                            onTap: () {},
                          ),
                          SizedBox(width: 8.h),
                          GestureDetector(
                            onTap: () async {
                              final ok = await _svc.clearTodayTag();
                              if (!mounted) return;
                              if (ok) {
                                ref.read(dailyCapsuleProvider.notifier).refresh();
                              }
                            },
                            child: Text(
                              'Clear',
                              style: TextStyleHelper.instance.body12BoldPlusJakartaSans
                                  .copyWith(color: appTheme.blue_gray_300),
                            ),
                          ),
                        ],
                      ),
              ),
              _tagPlusButton(
                onTap: () => _openTagPicker(currentTagId: tagId),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoryThumb({required String storyId, List<String>? storyIds}) {
    return FutureBuilder<_DailyCapsuleStoryThumbData?>(
      future: _getStoryThumb(storyId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _DailyCapsuleCompactStoryCard(
            thumbnailUrl: '',
            avatarUrl: '',
            isVideo: false,
            onTap: () {},
          );
        }

        final data = snap.data;
        if (data == null) return const SizedBox.shrink();

        return _DailyCapsuleCompactStoryCard(
          thumbnailUrl: data.thumbnailUrl,
          avatarUrl: data.contributorAvatarUrl,
          isVideo: data.mediaType == 'video',
          onTap: () => _openStoryViewer(storyId, storyIds: storyIds),
        );
      },
    );
  }

  Future<void> _openStoryViewer(String storyId, {List<String>? storyIds}) async {
    final ids = (storyIds == null || storyIds.isEmpty) ? <String>[storyId] : storyIds.toList();
    if (!ids.contains(storyId)) {
      ids.add(storyId);
    }
    await NavigatorService.pushNamed(
      AppRoutes.appStoryView,
      arguments: FeedStoryContext(
        feedType: 'daily_capsule',
        storyIds: ids,
        initialStoryId: storyId,
      ),
    );

    // If the story was deleted in the viewer, clear cached thumb + refresh entry
    for (final id in ids) {
      _storyThumbFutures.remove(id);
    }
    if (!mounted) return;
    await ref.read(dailyCapsuleProvider.notifier).refresh();
    if (!mounted) return;
    setState(() {});
  }

  Widget _buildLoading() {
    return Center(
      child: CircularProgressIndicator(
        color: appTheme.deep_purple_A100,
      ),
    );
  }

  Widget _buildLoadingScrollable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: _buildLoading(),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyleHelper.instance.body14BoldPlusJakartaSans
          .copyWith(color: appTheme.gray_50),
    );
  }

  Widget _actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    Widget? child,
  }) {
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: appTheme.blue_gray_900_01,
        borderRadius: BorderRadius.circular(16.h),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: appTheme.gray_50, size: 22.h),
              SizedBox(width: 10.h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                          .copyWith(color: appTheme.gray_50),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                          .copyWith(color: appTheme.gray_50.withAlpha(153)),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          if (child != null) ...[
            SizedBox(height: 12.h),
            child,
          ],
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required bool disabled,
    required VoidCallback onTap,
  }) {
    return CustomButton(
      text: label,
      onPressed: disabled ? null : onTap,
      buttonStyle: CustomButtonStyle.fillPrimary,
      buttonTextStyle: CustomButtonTextStyle.bodyMedium,
      height: 36.h,
      width: 96.h,
      padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 10.h),
    );
  }

  Widget _moodRow(DailyCapsuleState state) {
    final emojis = const ['😀', '🙂', '😐', '😔', '😄', '🥳', '😴', '😭'];
    final todayType = (state.todayEntry?['completion_type'] ?? '').toString();
    final todayStoryId = (state.todayEntry?['story_id'] ?? '').toString().trim();
    final bool moodLockedByStory = (todayType == 'instant_story' || todayType == 'memory_post') &&
        todayStoryId.isNotEmpty;

    return Wrap(
      spacing: 10.h,
      runSpacing: 10.h,
      children: emojis.map((e) {
        return GestureDetector(
          onTap: state.isCompleting
              ? null
              : () async {
                  if (moodLockedByStory) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Remove your story first to select a mood.',
                        ),
                      ),
                    );
                    return;
                  }
                  HapticFeedback.selectionClick();
                  // User-initiated completion flow: allow confetti on first completion.
                  _pendingCelebrateCompletion = true;
                  await ref.read(dailyCapsuleProvider.notifier).completeMood(e);
                },
          child: Opacity(
            opacity: (state.isCompleting || moodLockedByStory) ? 0.6 : 1.0,
            child: Container(
              width: 44.h,
              height: 44.h,
              decoration: BoxDecoration(
                color: appTheme.gray_900_02.withAlpha(128),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(e, style: TextStyle(fontSize: 20.h)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _onInstantStory() async {
    final todayEntry = ref.read(dailyCapsuleProvider).todayEntry;
    final existingStoryId = (todayEntry?['story_id'] ?? '').toString().trim();
    if (existingStoryId.isNotEmpty) {
      // User already has a capsule story today. Don't create a new one—open it.
      await _openStoryViewer(existingStoryId);
      return;
    }

    await _svc.upsertSettingsIfNeeded();
    final memoryId = await _svc.ensureDailyCapsuleMemoryId();
    if (!mounted) return;
    if (memoryId == null || memoryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not start Daily Capsule. Try again.'),
        ),
      );
      return;
    }

    // User is starting a completion flow (story). Celebrate once it actually completes.
    _pendingCelebrateCompletion = true;
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => NativeCameraRecordingScreen(
          memoryId: memoryId,
          memoryTitle: DailyCapsuleService.dailyCapsuleMemoryTitle,
          categoryIcon: '🗓️',
          storyEditArgs: const {
            'after_share_route': AppRoutes.appDailyCapsule,
            'daily_capsule_completion_type': 'instant_story',
          },
        ),
      ),
    );
  }

  Future<void> _onPostToMemory() async {
    await _svc.upsertSettingsIfNeeded();

    // IMPORTANT: match the app's main "Create Story" memory retrieval logic.
    // This prevents Daily Capsule from drifting and fixes false "no open memories" cases.
    final raw = await _feedSvc.fetchUserActiveMemories();
    final memories = raw.where((m) {
      final title = (m['title'] ?? '').toString().trim();
      final vis = (m['visibility'] ?? '').toString().trim().toLowerCase();
      return !(title == DailyCapsuleService.dailyCapsuleMemoryTitle && vis == 'private');
    }).toList();
    if (!mounted) return;

    if (memories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No open memories available to post to.'),
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: appTheme.gray_900_02,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.h)),
          ),
          padding: EdgeInsets.fromLTRB(16.h, 12.h, 16.h, 16.h),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.h,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: appTheme.blue_gray_300,
                      borderRadius: BorderRadius.circular(2.h),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Select Memory',
                  style: TextStyleHelper.instance.title20BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Your post will also count as today’s Daily Capsule.',
                  style: TextStyleHelper.instance.body14MediumPlusJakartaSans
                      .copyWith(color: appTheme.gray_50.withAlpha(153)),
                ),
                SizedBox(height: 16.h),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: memories.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10.h),
                    itemBuilder: (context, idx) {
                      final m = memories[idx];
                      final title = (m['title'] ?? 'Memory').toString();
                      final icon = (m['category_icon'] ?? '').toString().trim();
                      final bool iconIsUrl = icon.startsWith('http://') || icon.startsWith('https://');
                      return GestureDetector(
                        onTap: () => Navigator.pop(context, m),
                        child: Container(
                          padding: EdgeInsets.all(14.h),
                          decoration: BoxDecoration(
                            color: appTheme.blue_gray_900_01,
                            borderRadius: BorderRadius.circular(14.h),
                          ),
                          child: Row(
                            children: [
                              if (iconIsUrl)
                                CustomImageView(
                                  imagePath: icon,
                                  width: 20.h,
                                  height: 20.h,
                                  fit: BoxFit.contain,
                                )
                              else if (icon.isNotEmpty)
                                Text(icon, style: TextStyle(fontSize: 18.h))
                              else
                                Icon(
                                  Icons.photo_library_outlined,
                                  color: appTheme.gray_50,
                                  size: 18.h,
                                ),
                              SizedBox(width: 12.h),
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyleHelper
                                      .instance.title16BoldPlusJakartaSans
                                      .copyWith(color: appTheme.gray_50),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    if (selected == null) return;

    final memoryId = (selected['id'] ?? '').toString();
    final title = (selected['title'] ?? '').toString();
    final categoryIcon = (selected['category_icon'] ?? '').toString();

    if (memoryId.isEmpty) return;

    // User is starting a completion flow (story). Celebrate once it actually completes.
    _pendingCelebrateCompletion = true;
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => NativeCameraRecordingScreen(
          memoryId: memoryId,
          memoryTitle: title,
          categoryIcon: categoryIcon.isEmpty ? null : categoryIcon,
          storyEditArgs: const {
            'after_share_route': AppRoutes.appDailyCapsule,
            'daily_capsule_completion_type': 'memory_post',
          },
        ),
      ),
    );
  }
}

class _DailyCapsuleStoryThumbData {
  const _DailyCapsuleStoryThumbData({
    required this.storyId,
    required this.mediaType,
    required this.thumbnailUrl,
    required this.contributorName,
    required this.contributorAvatarUrl,
  });

  final String storyId;
  final String mediaType; // image | video
  final String thumbnailUrl;
  // ignore: unused_field
  final String contributorName;
  final String contributorAvatarUrl;
}

class _DailyCapsuleCompactStoryCard extends StatelessWidget {
  const _DailyCapsuleCompactStoryCard({
    required this.thumbnailUrl,
    required this.avatarUrl,
    required this.isVideo,
    required this.onTap,
  });

  final String thumbnailUrl;
  final String avatarUrl;
  final bool isVideo;
  final VoidCallback onTap;

  bool _isNetworkUrl(String? s) {
    if (s == null) return false;
    final v = s.trim();
    if (v.isEmpty) return false;
    if (v == 'null' || v == 'undefined') return false;
    return v.startsWith('http://') || v.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final bg = thumbnailUrl.trim();
    final avatar = avatarUrl.trim();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90.h,
        height: 120.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.h),
          color: appTheme.gray_900_01,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.h),
                child: _isNetworkUrl(bg)
                    ? CachedNetworkImage(
                        imageUrl: bg,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: appTheme.gray_900_02,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: appTheme.gray_900_02,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.white38,
                            size: 18.h,
                          ),
                        ),
                      )
                    : Container(
                        color: appTheme.gray_900_02,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.white38,
                          size: 18.h,
                        ),
                      ),
              ),
            ),
            if (isVideo)
              Center(
                child: Container(
                  width: 34.h,
                  height: 34.h,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(140),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 22.h,
                  ),
                ),
              ),
            Positioned(
              left: 10.h,
              top: 10.h,
              child: Container(
                width: 32.h,
                height: 32.h,
                padding: EdgeInsets.all(2.h),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF8B5CF6),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: appTheme.gray_900,
                  ),
                  padding: EdgeInsets.all(1.h),
                  child: ClipOval(
                    child: _isNetworkUrl(avatar)
                        ? CachedNetworkImage(
                            imageUrl: avatar,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: appTheme.gray_900_02,
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: appTheme.gray_900_02,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.person,
                                color: Colors.white38,
                                size: 16.h,
                              ),
                            ),
                          )
                        : Container(
                            color: appTheme.gray_900_02,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.person,
                              color: Colors.white38,
                              size: 16.h,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _MonthStickyHeaderDelegate({required this.title});

  final String title;

  @override
  double get minExtent => 44.h;

  @override
  double get maxExtent => 44.h;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: appTheme.gray_900_02,
      padding: EdgeInsets.fromLTRB(16.h, 10.h, 16.h, 10.h),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyleHelper.instance.body14BoldPlusJakartaSans
            .copyWith(color: appTheme.gray_50),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _MonthStickyHeaderDelegate oldDelegate) {
    return oldDelegate.title != title;
  }
}