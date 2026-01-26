import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

class DailyCapsuleService {
  DailyCapsuleService._();

  static final DailyCapsuleService instance = DailyCapsuleService._();

  SupabaseClient? get _client => SupabaseService.instance.client;

  static const String dailyCapsuleMemoryTitle = 'Daily Capsule';

  /// Device offset in minutes from UTC (ex: PST = -480).
  int get deviceUtcOffsetMinutes => DateTime.now().timeZoneOffset.inMinutes;

  DateTime get _nowLocal => DateTime.now();

  String get todayLocalDateYmd {
    final now = _nowLocal;
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  /// Compute next reminder time around 8pm local.
  /// Stored as UTC in DB.
  DateTime computeNextReminderUtc({
    int hourLocal = 20,
    int minuteLocal = 0,
    int jitterHalfSpanMinutes = 15,
  }) {
    final now = _nowLocal;

    // Base time is today at 20:00 local; if already past ~20:15, schedule tomorrow.
    final jitter = Random().nextInt(jitterHalfSpanMinutes * 2 + 1) - jitterHalfSpanMinutes;
    final targetMinute = (minuteLocal + jitter).clamp(0, 59);

    final todayTarget = DateTime(now.year, now.month, now.day, hourLocal, targetMinute);
    final scheduledLocal = now.isAfter(todayTarget.add(const Duration(minutes: 15)))
        ? DateTime(now.year, now.month, now.day + 1, hourLocal, targetMinute)
        : todayTarget;

    return scheduledLocal.toUtc();
  }

  Future<void> upsertSettingsIfNeeded() async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;

    final nextReminderAt = computeNextReminderUtc();

    try {
      await client.from('daily_capsule_settings').upsert(
        {
          'user_id': userId,
          'utc_offset_minutes': deviceUtcOffsetMinutes,
          'reminder_enabled': true,
          'reminder_hour': 20,
          'reminder_minute': 0,
          'next_reminder_at': nextReminderAt.toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id',
      );
    } catch (e) {
      // Best-effort only; do not block UI.
      debugPrint('⚠️ upsertSettingsIfNeeded failed: $e');
    }
  }

  /// Returns the per-user hidden Daily Capsule memory ID.
  /// Creates it if missing.
  Future<String?> ensureDailyCapsuleMemoryId() async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return null;

    try {
      Map<String, dynamic>? existing;
      try {
        final raw = await client
            .from('memories')
            .select('id')
            .eq('creator_id', userId)
            .eq('is_daily_capsule', true)
            .maybeSingle();
        existing = (raw is Map) ? Map<String, dynamic>.from(raw as Map) : null;
      } on PostgrestException catch (e) {
        final msg = e.message.toLowerCase();
        final code = (e.code ?? '').toString();
        final isMissing =
            code == '42703' || (msg.contains('is_daily_capsule') && msg.contains('does not exist'));
        if (!isMissing) rethrow;
        // Backward-compat: fall back to title match until migration applied.
        final raw = await client
            .from('memories')
            .select('id')
            .eq('creator_id', userId)
            .eq('title', dailyCapsuleMemoryTitle)
            .eq('visibility', 'private')
            .maybeSingle();
        existing = (raw is Map) ? Map<String, dynamic>.from(raw as Map) : null;
      }

      final id = existing?['id']?.toString();
      if (id != null && id.isNotEmpty) return id;

      final nowUtc = DateTime.now().toUtc();
      final farFuture = DateTime.utc(2200, 1, 1);

      Map<String, dynamic> created;
      try {
        final raw = await client
            .from('memories')
            .insert({
              'title': dailyCapsuleMemoryTitle,
              'creator_id': userId,
              'visibility': 'private',
              'duration': '3_days',
              'state': 'open',
              'expires_at': farFuture.toIso8601String(),
              'start_time': nowUtc.toIso8601String(),
              'end_time': farFuture.toIso8601String(),
              'is_daily_capsule': true,
            })
            .select('id')
            .single();
        created = (raw as Map).cast<String, dynamic>();
      } on PostgrestException catch (e) {
        final msg = e.message.toLowerCase();
        final code = (e.code ?? '').toString();
        final isMissing =
            code == '42703' || (msg.contains('is_daily_capsule') && msg.contains('does not exist'));
        if (!isMissing) rethrow;
        final raw = await client
            .from('memories')
            .insert({
              'title': dailyCapsuleMemoryTitle,
              'creator_id': userId,
              'visibility': 'private',
              'duration': '3_days',
              'state': 'open',
              'expires_at': farFuture.toIso8601String(),
              'start_time': nowUtc.toIso8601String(),
              'end_time': farFuture.toIso8601String(),
            })
            .select('id')
            .single();
        created = (raw as Map).cast<String, dynamic>();
      }

      return created['id']?.toString();
    } on PostgrestException catch (e) {
      debugPrint('❌ ensureDailyCapsuleMemoryId failed: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ ensureDailyCapsuleMemoryId failed: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchTodayEntry() async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return null;

    try {
      final res = await client
          .from('daily_capsule_entries')
          .select()
          .eq('user_id', userId)
          .eq('local_date', todayLocalDateYmd)
          .maybeSingle();
      if (res == null) return null;
      return Map<String, dynamic>.from(res);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchArchive({int limit = 60}) async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return [];

    try {
      final res = await client
          .from('daily_capsule_entries')
          .select()
          .eq('user_id', userId)
          .order('local_date', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(res as List? ?? const []);
    } catch (_) {
      return [];
    }
  }

  int computeStreakFromEntries({
    required String todayYmd,
    required List<Map<String, dynamic>> entriesDesc,
  }) {
    // entriesDesc sorted by local_date desc
    int streak = 0;
    DateTime expected;

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return DateTime(v.year, v.month, v.day);
      final s = v.toString();
      final dt = DateTime.tryParse(s);
      if (dt == null) return null;
      return DateTime(dt.year, dt.month, dt.day);
    }

    try {
      final parts = todayYmd.split('-');
      if (parts.length != 3) return 0;
      expected = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (_) {
      return 0;
    }

    for (final e in entriesDesc) {
      final d = parseDate(e['local_date']);
      if (d == null) continue;
      if (d.year == expected.year && d.month == expected.month && d.day == expected.day) {
        streak += 1;
        expected = expected.subtract(const Duration(days: 1));
        continue;
      }
      // Stop on first gap or future date mismatch.
      break;
    }
    return streak;
  }

  Future<void> completeMood(String emoji) async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;

    // Allow changing today's capsule: upsert on (user_id, local_date)
    await client.from('daily_capsule_entries').upsert(
      {
        'user_id': userId,
        'local_date': todayLocalDateYmd,
        'utc_offset_minutes': deviceUtcOffsetMinutes,
        'completion_type': 'mood',
        'mood_emoji': emoji,
        // IMPORTANT:
        // Do NOT clear story_id here. If the user already created a capsule story today,
        // we keep it "remembered" unless they explicitly delete the story.
        'completed_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'user_id,local_date',
    );

    // Schedule next reminder (best-effort)
    unawaited(upsertSettingsIfNeeded());
  }

  Future<void> completeWithStory({
    required String completionType,
    required String storyId,
    String? memoryId,
  }) async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;

    // Allow changing today's capsule: upsert on (user_id, local_date)
    await client.from('daily_capsule_entries').upsert(
      {
        'user_id': userId,
        'local_date': todayLocalDateYmd,
        'utc_offset_minutes': deviceUtcOffsetMinutes,
        'completion_type': completionType,
        // Clear mood if switching from mood to a story-based capsule
        'mood_emoji': null,
        'story_id': storyId,
        'memory_id': memoryId,
        'completed_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'user_id,local_date',
    );

    unawaited(upsertSettingsIfNeeded());
  }

  bool _isMissingColumn(PostgrestException e, String columnName) {
    final msg = (e.message).toLowerCase();
    final details = (e.details ?? '').toString().toLowerCase();
    final hint = (e.hint ?? '').toString().toLowerCase();
    final code = (e.code ?? '').toString();
    final col = columnName.toLowerCase();

    if (code == '42703') return true;
    if (msg.contains('column') && msg.contains(col) && msg.contains('does not exist')) return true;
    if (details.contains('column') && details.contains(col) && details.contains('does not exist')) {
      return true;
    }
    if (hint.contains('column') && hint.contains(col) && hint.contains('does not exist')) return true;
    return false;
  }

  /// Memories user can post to from Daily Capsule (excludes the hidden Daily Capsule memory).
  Future<List<Map<String, dynamic>>> fetchEligibleMemoriesForPosting() async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return [];

    try {
      // creator memories
      dynamic creator;
      try {
        creator = await client
            .from('memories')
            .select('id, title, category_icon, end_time, visibility, is_daily_capsule')
            .eq('creator_id', userId)
            .eq('state', 'open')
            .eq('is_daily_capsule', false)
            .order('created_at', ascending: false);
      } on PostgrestException catch (e) {
        // Backward-compat: if migration not applied yet, retry without is_daily_capsule.
        if (!_isMissingColumn(e, 'is_daily_capsule')) rethrow;
        creator = await client
            .from('memories')
            .select('id, title, category_icon, end_time, visibility')
            .eq('creator_id', userId)
            .eq('state', 'open')
            .order('created_at', ascending: false);
      }

      // contributed memories
      final contributed = await client
          .from('memory_contributors')
          .select('memory_id')
          .eq('user_id', userId);

      final ids = <String>{
        ...(contributed as List? ?? const [])
            .map((r) => (r as Map)['memory_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty),
      }.toList();

      List<dynamic> joined = [];
      if (ids.isNotEmpty) {
        try {
          joined = await client
              .from('memories')
              .select('id, title, category_icon, end_time, visibility, is_daily_capsule')
              .inFilter('id', ids)
              .eq('state', 'open')
              .eq('is_daily_capsule', false)
              .order('created_at', ascending: false);
        } on PostgrestException catch (e) {
          if (!_isMissingColumn(e, 'is_daily_capsule')) rethrow;
          joined = await client
              .from('memories')
              .select('id, title, category_icon, end_time, visibility')
              .inFilter('id', ids)
              .eq('state', 'open')
              .order('created_at', ascending: false);
        }
      }

      final all = <Map<String, dynamic>>[
        ...List<Map<String, dynamic>>.from(creator as List? ?? const []),
        ...List<Map<String, dynamic>>.from(joined as List? ?? const []),
      ];

      // De-dupe by id
      final seen = <String>{};
      final deduped = <Map<String, dynamic>>[];
      for (final m in all) {
        final id = (m['id'] ?? '').toString();
        if (id.isEmpty || seen.contains(id)) continue;

        // Backward-compat: if we couldn't filter by is_daily_capsule in SQL,
        // make a best-effort exclusion by title + private visibility.
        final title = (m['title'] ?? '').toString().trim();
        final vis = (m['visibility'] ?? '').toString().trim();
        if (title == dailyCapsuleMemoryTitle && vis == 'private') {
          continue;
        }

        seen.add(id);
        deduped.add(m);
      }
      return deduped;
    } catch (_) {
      return [];
    }
  }
}

