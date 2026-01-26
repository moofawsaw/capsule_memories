import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import '../../services/daily_capsule_service.dart';
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
    with WidgetsBindingObserver {
  final _svc = DailyCapsuleService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dailyCapsuleProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
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
              child: TabBarView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildTodayTab(state),
                  _buildArchiveTab(state),
                ],
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
    return Container(
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
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: EdgeInsets.all(3.h),
      decoration: BoxDecoration(
        color: appTheme.gray_900_02.withAlpha(128),
        borderRadius: BorderRadius.circular(22.h),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          color: appTheme.deep_purple_A100,
          borderRadius: BorderRadius.circular(18.h),
        ),
        dividerColor: Colors.transparent,
        labelColor: appTheme.gray_900_02,
        unselectedLabelColor: appTheme.gray_50,
        labelStyle: TextStyleHelper.instance.body14BoldPlusJakartaSans,
        unselectedLabelStyle: TextStyleHelper.instance.body14RegularPlusJakartaSans,
        tabs: const [
          Tab(text: 'Today'),
          Tab(text: 'Archive'),
        ],
      ),
    );
  }

  Widget _buildTodayTab(DailyCapsuleState state) {
    final completed = state.todayEntry != null;

    if (state.isLoading) {
      return _buildLoading();
    }

    if (completed) {
      return _buildCompletedToday(state.todayEntry!);
    }

    return RefreshIndicator(
      color: appTheme.deep_purple_A100,
      backgroundColor: appTheme.gray_900_01,
      displacement: 30,
      onRefresh: () => ref.read(dailyCapsuleProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(16.h, 4.h, 16.h, 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
      ),
    );
  }

  Widget _buildArchiveTab(DailyCapsuleState state) {
    if (state.isLoading) {
      return _buildLoading();
    }

    final entries = state.archiveEntries;
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.h),
          child: Text(
            'No Daily Capsules yet. Start today.',
            style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                .copyWith(color: appTheme.gray_50.withAlpha(153)),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: appTheme.deep_purple_A100,
      backgroundColor: appTheme.gray_900_01,
      displacement: 30,
      onRefresh: () => ref.read(dailyCapsuleProvider.notifier).refresh(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(16.h, 4.h, 16.h, 24.h),
        itemCount: entries.length,
        separatorBuilder: (_, __) => SizedBox(height: 10.h),
        itemBuilder: (context, index) {
          final e = entries[index];
          final date = (e['local_date'] ?? '').toString();
          final type = (e['completion_type'] ?? '').toString();
          final mood = (e['mood_emoji'] ?? '').toString();
          final hasStory = (e['story_id'] ?? '').toString().isNotEmpty;

          final leading = type == 'mood'
              ? (mood.isNotEmpty ? mood : '🙂')
              : (hasStory ? '🎞️' : '✅');

          final label = type == 'mood'
              ? 'Mood'
              : (type == 'instant_story' ? 'Instant story' : 'Memory post');

          return Container(
            padding: EdgeInsets.all(14.h),
            decoration: BoxDecoration(
              color: appTheme.blue_gray_900_01,
              borderRadius: BorderRadius.circular(14.h),
              border: Border.all(color: appTheme.gray_50.withAlpha(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42.h,
                  height: 42.h,
                  decoration: BoxDecoration(
                    color: appTheme.gray_900_02.withAlpha(128),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    leading,
                    style: TextStyle(fontSize: 18.h),
                  ),
                ),
                SizedBox(width: 12.h),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        date,
                        style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                            .copyWith(color: appTheme.gray_50),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        label,
                        style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                            .copyWith(color: appTheme.gray_50.withAlpha(153)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompletedToday(Map<String, dynamic> entry) {
    final type = (entry['completion_type'] ?? '').toString();
    final mood = (entry['mood_emoji'] ?? '').toString();

    final title = type == 'mood'
        ? 'Mood captured'
        : (type == 'instant_story' ? 'Instant story posted' : 'Posted to a memory');

    final leading = type == 'mood'
        ? (mood.isNotEmpty ? mood : '🙂')
        : '✅';

    return RefreshIndicator(
      color: appTheme.deep_purple_A100,
      backgroundColor: appTheme.gray_900_01,
      displacement: 30,
      onRefresh: () => ref.read(dailyCapsuleProvider.notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(16.h, 4.h, 16.h, 24.h),
        children: [
          Container(
            padding: EdgeInsets.all(16.h),
            decoration: BoxDecoration(
              color: appTheme.blue_gray_900_01,
              borderRadius: BorderRadius.circular(16.h),
              border: Border.all(color: appTheme.deep_purple_A100.withAlpha(60)),
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
                        'Come back tomorrow to keep the streak going.',
                        style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                            .copyWith(color: appTheme.gray_50.withAlpha(153)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
        border: Border.all(color: appTheme.gray_50.withAlpha(18)),
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
                border: Border.all(color: appTheme.gray_50.withAlpha(24)),
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
    final state = ref.read(dailyCapsuleProvider);
    if (state.todayEntry != null) return;

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
    final state = ref.read(dailyCapsuleProvider);
    if (state.todayEntry != null) return;

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
                            border:
                                Border.all(color: appTheme.gray_50.withAlpha(18)),
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

