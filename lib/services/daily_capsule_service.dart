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
  static const String userTagTable = 'user_tags';
  static const String _dailyCapsuleCategoryEmoji = '🗓️';

  Future<void> _ensureContributorForMemory({
    required String memoryId,
    required String userId,
  }) async {
    final client = _client;
    if (client == null) return;
    final mid = memoryId.trim();
    final uid = userId.trim();
    if (mid.isEmpty || uid.isEmpty) return;
    try {
      await client.from('memory_contributors').insert({
        'memory_id': mid,
        'user_id': uid,
        'joined_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // best-effort; ignore duplicates / RLS / schema variants
    }
  }

  Future<String?> _fetchDefaultCategoryId() async {
    final client = _client;
    if (client == null) return null;
    try {
      // Prefer a "Custom" category if it exists; else fall back to first active category.
      dynamic row;
      try {
        row = await client
            .from('memory_categories')
            .select('id')
            .eq('is_active', true)
            .ilike('name', '%custom%')
            .maybeSingle();
      } catch (_) {
        row = null;
      }
      if (row is Map && (row['id'] ?? '').toString().trim().isNotEmpty) {
        return row['id']?.toString();
      }

      row = await client
          .from('memory_categories')
          .select('id')
          .eq('is_active', true)
          .order('display_order', ascending: true)
          .limit(1)
          .maybeSingle();
      if (row is Map && (row['id'] ?? '').toString().trim().isNotEmpty) {
        return row['id']?.toString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Device offset in minutes from UTC (ex: PST = -480).
  int get deviceUtcOffsetMinutes => DateTime.now().timeZoneOffset.inMinutes;

  DateTime get _nowLocal => DateTime.now();

  String _normalizeTagName(String input) {
    var t = input.trim();
    if (t.startsWith('#')) t = t.substring(1).trim();
    // collapse internal whitespace
    t = t.replaceAll(RegExp(r'\s+'), ' ');
    return t;
  }

  String _normalizeTagKey(String input) => _normalizeTagName(input).toLowerCase();

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
            .select('id, category_id, category_icon')
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
            .select('id, category_id, category_icon')
            .eq('creator_id', userId)
            .eq('title', dailyCapsuleMemoryTitle)
            .eq('visibility', 'private')
            .maybeSingle();
        existing = (raw is Map) ? Map<String, dynamic>.from(raw as Map) : null;
      }

      final id = existing?['id']?.toString();
      if (id != null && id.isNotEmpty) {
        // Ensure the creator is a contributor (so member count + memory info works everywhere).
        unawaited(_ensureContributorForMemory(memoryId: id, userId: userId));

        // Backfill category_id for existing Daily Capsule memory so UIs can render category icons.
        final existingCategoryId = (existing?['category_id'] ?? '').toString().trim();
        if (existingCategoryId.isEmpty) {
          final categoryId = await _fetchDefaultCategoryId();
          if (categoryId != null && categoryId.isNotEmpty) {
            try {
              await client.from('memories').update({
                'category_id': categoryId,
                'category_icon': _dailyCapsuleCategoryEmoji,
              }).eq('id', id);
            } catch (_) {
              // best-effort
            }
          } else {
            // At least provide a local/emoji icon for places that use category_icon directly.
            try {
              await client.from('memories').update({
                'category_icon': _dailyCapsuleCategoryEmoji,
              }).eq('id', id);
            } catch (_) {}
          }
        } else {
          // Ensure category_icon is populated (best-effort)
          final existingIcon = (existing?['category_icon'] ?? '').toString().trim();
          if (existingIcon.isEmpty) {
            try {
              await client.from('memories').update({
                'category_icon': _dailyCapsuleCategoryEmoji,
              }).eq('id', id);
            } catch (_) {}
          }
        }
        return id;
      }

      final nowUtc = DateTime.now().toUtc();
      final farFuture = DateTime.utc(2200, 1, 1);
      final categoryId = await _fetchDefaultCategoryId();

      Map<String, dynamic> created;
      try {
        final raw = await client
            .from('memories')
            .insert({
              'title': dailyCapsuleMemoryTitle,
              'creator_id': userId,
              if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
              'category_icon': _dailyCapsuleCategoryEmoji,
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
              if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
              'category_icon': _dailyCapsuleCategoryEmoji,
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

      final newId = created['id']?.toString();
      if (newId != null && newId.trim().isNotEmpty) {
        unawaited(_ensureContributorForMemory(memoryId: newId, userId: userId));
      }
      return newId;
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

  Future<List<Map<String, dynamic>>> fetchUserTags({int limit = 100}) async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return [];

    try {
      try {
        final res = await client
            .from(userTagTable)
            .select('id, name, normalized_name, color_hex, created_at')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(limit);
        return List<Map<String, dynamic>>.from(res as List? ?? const []);
      } on PostgrestException catch (e) {
        // Backward-compat: if color_hex hasn't been migrated yet.
        if (!_isMissingColumn(e, 'color_hex')) rethrow;
        final res = await client
            .from(userTagTable)
            .select('id, name, normalized_name, created_at')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(limit);
        return List<Map<String, dynamic>>.from(res as List? ?? const []);
      }
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> createOrGetUserTag(
    String name, {
    String? colorHex,
  }) async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return null;

    final normalized = _normalizeTagName(name);
    if (normalized.isEmpty) return null;

    final key = _normalizeTagKey(normalized);
    final safeColor = (colorHex ?? '#8B5CF6').toString().trim();

    try {
      // Upsert by (user_id, normalized_name) and return row.
      try {
        final res = await client
            .from(userTagTable)
            .upsert(
              {
                'user_id': userId,
                'name': normalized,
                'normalized_name': key,
                'color_hex': safeColor,
                'created_at': DateTime.now().toUtc().toIso8601String(),
              },
              onConflict: 'user_id,normalized_name',
            )
            .select('id, name, normalized_name, color_hex, created_at')
            .single();
        return Map<String, dynamic>.from(res as Map);
      } on PostgrestException catch (e) {
        // Backward-compat: if color_hex hasn't been migrated yet.
        if (!_isMissingColumn(e, 'color_hex')) rethrow;
        final res = await client
            .from(userTagTable)
            .upsert(
              {
                'user_id': userId,
                'name': normalized,
                'normalized_name': key,
                'created_at': DateTime.now().toUtc().toIso8601String(),
              },
              onConflict: 'user_id,normalized_name',
            )
            .select('id, name, normalized_name, created_at')
            .single();
        return Map<String, dynamic>.from(res as Map);
      }
    } catch (_) {
      // If schema isn't applied yet, fail silently.
      return null;
    }
  }

  Future<bool> setTodayTag({required String tagId}) async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return false;

    try {
      await client
          .from('daily_capsule_entries')
          .update({'tag_id': tagId})
          .eq('user_id', userId)
          .eq('local_date', todayLocalDateYmd);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> clearTodayTag() async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return false;

    try {
      await client
          .from('daily_capsule_entries')
          .update({'tag_id': null})
          .eq('user_id', userId)
          .eq('local_date', todayLocalDateYmd);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<String>> fetchStoryIdsForTag(String tagId, {int limit = 200}) async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return [];

    try {
      final res = await client
          .from('daily_capsule_entries')
          .select('story_id')
          .eq('user_id', userId)
          .eq('tag_id', tagId)
          .not('story_id', 'is', null)
          .order('local_date', ascending: false)
          .limit(limit);

      final ids = <String>[];
      for (final r in (res as List? ?? const [])) {
        final id = (r as Map)['story_id']?.toString();
        if (id != null && id.isNotEmpty) ids.add(id);
      }
      return ids;
    } catch (_) {
      return [];
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

    // If the user hasn't completed *today* yet, the streak should still reflect
    // consecutive completions up through yesterday (or the most recent day).
    // Example: user completed yesterday, it's now just after midnight -> streak should be 1.
    if (entriesDesc.isNotEmpty) {
      final first = parseDate(entriesDesc.first['local_date']);
      if (first != null) {
        final todayOnly = DateTime(expected.year, expected.month, expected.day);
        final diffDays = todayOnly.difference(first).inDays;
        // If newest entry is exactly yesterday (diffDays == 1), start from yesterday.
        // If newest entry is today (diffDays == 0), keep expected as today.
        // Otherwise (gap or future), keep expected as today; loop below will yield 0.
        if (diffDays == 1) {
          expected = expected.subtract(const Duration(days: 1));
        }
      }
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

