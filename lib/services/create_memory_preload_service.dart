import './groups_service.dart';
import './supabase_service.dart';

/// Preloads Create Memory dependencies (groups + categories).
///
/// This is intended to run during app bootstrap so the Create Memory bottom sheet
/// opens instantly (no skeleton/loading). It is safe to call multiple times.
class CreateMemoryPreloadService {
  CreateMemoryPreloadService._();

  static final CreateMemoryPreloadService instance =
      CreateMemoryPreloadService._();

  static const Duration _ttl = Duration(minutes: 15);

  List<Map<String, dynamic>> _cachedGroups = const [];
  List<Map<String, dynamic>> _cachedCategories = const [];
  bool _groupsLoaded = false;
  bool _categoriesLoaded = false;
  DateTime? _lastWarmAt;
  Future<void>? _inflight;

  List<Map<String, dynamic>> get cachedGroups => _cachedGroups;
  List<Map<String, dynamic>> get cachedCategories => _cachedCategories;

  bool get groupsLoaded => _groupsLoaded;
  bool get categoriesLoaded => _categoriesLoaded;

  bool get hasGroups => _cachedGroups.isNotEmpty;
  bool get hasCategories => _cachedCategories.isNotEmpty;

  /// Allows feature flows (like Create Memory) to keep the groups cache in-sync
  /// when realtime membership changes occur, without forcing a full warm (groups + categories).
  void updateGroupsCache(List<Map<String, dynamic>> groups) {
    _cachedGroups = groups;
    _groupsLoaded = true;
  }

  bool get isFresh =>
      _lastWarmAt != null && DateTime.now().difference(_lastWarmAt!) < _ttl;

  Future<void> warm({bool force = false}) {
    if (!force && _inflight != null) return _inflight!;
    if (!force && isFresh && hasGroups && hasCategories) {
      return Future.value();
    }

    _inflight = _warmInternal().whenComplete(() => _inflight = null);
    return _inflight!;
  }

  Future<void> _warmInternal() async {
    final client = SupabaseService.instance.client;
    if (client == null) return;

    try {
      // Groups (fast path via existing service)
      final groups = await GroupsService.fetchUserGroups();
      _cachedGroups =
          groups; // cache even if empty (avoids refetch on first open)
      _groupsLoaded = true;
    } catch (e) {
      // ignore: avoid_print
      print('CreateMemoryPreloadService: groups preload failed: $e');
      _groupsLoaded = false;
    }

    try {
      // Categories (mirror CreateMemoryNotifier mapping)
      final response = await client
          .from('memory_categories')
          .select('id, name, tagline, icon_name, icon_url')
          .eq('is_active', true)
          .order('display_order', ascending: true);

      final categories = (response as List)
          .map<Map<String, dynamic>>((category) => {
                'id': category['id'] as String,
                'name': category['name'] as String,
                'tagline': category['tagline'] as String?,
                'icon_name': category['icon_name'] as String?,
                'icon_url': category['icon_url'] as String?,
              })
          .toList();

      _cachedCategories = categories; // cache even if empty
      _categoriesLoaded = true;
    } catch (e) {
      // ignore: avoid_print
      print('CreateMemoryPreloadService: categories preload failed: $e');
      _categoriesLoaded = false;
    }

    _lastWarmAt = DateTime.now();
  }
}
