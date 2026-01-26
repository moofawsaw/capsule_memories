import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import '../../core/models/feed_story_context.dart';
import '../../services/avatar_helper_service.dart';
import '../../services/daily_capsule_service.dart';
import '../../services/story_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/standard_title_bar.dart';
import '../memory_feed_dashboard_screen/widgets/native_camera_recording_screen.dart';
import 'notifier/daily_capsule_notifier.dart';
import 'notifier/daily_capsule_state.dart';

class DailyCapsuleScreen extends ConsumerStatefulWidget {
  const DailyCapsuleScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DailyCapsuleScreen> createState() => _DailyCapsuleScreenState();
}

class _DailyCapsuleScreenState extends ConsumerState<DailyCapsuleScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final _svc = DailyCapsuleService.instance;
  final Map<String, Future<_DailyCapsuleStoryThumbData?>> _storyThumbFutures = {};
  DateTime _historyMonth = DateTime(DateTime.now().year, DateTime.now().month);

  late final ConfettiController _streakConfetti;
  ProviderSubscription<DailyCapsuleState>? _capsuleSub;
  bool _pendingCelebrateCompletion = false;
  bool _wasCompleted = false;
  String? _celebratedLocalDateYmd;

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

  @override
  void dispose() {
    _capsuleSub?.close();
    _capsuleSub = null;
    _streakConfetti.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // If user just shared a story, we’ll land back here and refresh.
      ref.read(dailyCapsuleProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dailyCapsuleProvider);
    final completedToday = state.todayEntry != null;

    return Scaffold(
      backgroundColor: appTheme.gray_900_02,
      body: DefaultTabController(
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
            if (todayStoryId.isNotEmpty) ...[
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

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(16.h, 4.h, 16.h, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8.h),
          _buildHistoryHeader(),
          SizedBox(height: 10.h),
          _buildWeekdayHeader(),
          SizedBox(height: 8.h),
          _buildMonthGrid(
            month: _historyMonth,
            todayKey: todayKey,
            byDate: byDate,
          ),
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
                backgroundColor: appTheme.gray_900_01,
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
                color: isToday
                    ? appTheme.deep_purple_A100
                    : appTheme.gray_50.withAlpha(18),
                width: isToday ? 2 : 1,
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

    final title = type == 'mood'
        ? 'Mood captured'
        : (type == 'instant_story' ? 'Instant story posted' : 'Posted to a memory');

    final leading = type == 'mood'
        ? (mood.isNotEmpty ? mood : '🙂')
        : '✅';

    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: appTheme.blue_gray_900_01,
        borderRadius: BorderRadius.circular(16.h),
      ),
      child: Row(
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryThumb({required String storyId}) {
    return FutureBuilder<_DailyCapsuleStoryThumbData?>(
      future: _getStoryThumb(storyId),
      builder: (context, snap) {
        final data = snap.data;
        if (data == null) {
          return _DailyCapsuleCompactStoryCard(
            thumbnailUrl: '',
            avatarUrl: '',
            isVideo: false,
            onTap: () => _openStoryViewer(storyId),
          );
        }

        return _DailyCapsuleCompactStoryCard(
          thumbnailUrl: data.thumbnailUrl,
          avatarUrl: data.contributorAvatarUrl,
          isVideo: data.mediaType == 'video',
          onTap: () => _openStoryViewer(storyId),
        );
      },
    );
  }

  void _openStoryViewer(String storyId) {
    NavigatorService.pushNamed(
      AppRoutes.appStoryView,
      arguments: FeedStoryContext(
        feedType: 'daily_capsule',
        storyIds: [storyId],
        initialStoryId: storyId,
      ),
    );
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

    return Wrap(
      spacing: 10.h,
      runSpacing: 10.h,
      children: emojis.map((e) {
        return GestureDetector(
          onTap: state.isCompleting
              ? null
              : () async {
                  HapticFeedback.selectionClick();
                  // User-initiated completion flow: allow confetti on first completion.
                  _pendingCelebrateCompletion = true;
                  await ref.read(dailyCapsuleProvider.notifier).completeMood(e);
                },
          child: Opacity(
            opacity: state.isCompleting ? 0.6 : 1.0,
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
      _openStoryViewer(existingStoryId);
      return;
    }

    await _svc.upsertSettingsIfNeeded();
    final memoryId = await _svc.ensureDailyCapsuleMemoryId();
    if (!mounted) return;
    if (memoryId == null || memoryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not start Daily Capsule. Try again.'),
          backgroundColor: appTheme.red_500,
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

    final memories = await _svc.fetchEligibleMemoriesForPosting();
    if (!mounted) return;

    if (memories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No open memories available to post to.'),
          backgroundColor: appTheme.gray_900_01,
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
                      final icon = (m['category_icon'] ?? '').toString();
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
                              if (icon.isNotEmpty)
                                Text(icon, style: TextStyle(fontSize: 18.h))
                              else
                                Icon(Icons.photo_library_outlined,
                                    color: appTheme.gray_50, size: 18.h),
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
