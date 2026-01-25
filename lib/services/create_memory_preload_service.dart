import './groups_service.dart';
import './supabase_service.dart';

/// Preloads Create Memory dependencies (groups + categories) AFTER initial paint.
/// This avoids jank on the first bottom-sheet open while keeping splash fast.
class CreateMemoryPreloadService {
  CreateMemoryPreloadService._();

  static final CreateMemoryPreloadService instance = CreateMemoryPreloadService._();

  static const Duration _ttl = Duration(minutes: 15);

  List<Map<String, dynamic>> _cachedGroups = const [];
  List<Map<String, dynamic>> _cachedCategories = const [];
  DateTime? _lastWarmAt;
  Future<void>? _inflight;

  List<Map<String, dynamic>> get cachedGroups => _cachedGroups;
  List<Map<String, dynamic>> get cachedCategories => _cachedCategories;

  bool get hasGroups => _cachedGroups.isNotEmpty;
  bool get hasCategories => _cachedCategories.isNotEmpty;

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
      if (groups.isNotEmpty) _cachedGroups = groups;
    } catch (e) {
      // ignore: avoid_print
      print('CreateMemoryPreloadService: groups preload failed: $e');
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

      if (categories.isNotEmpty) _cachedCategories = categories;
    } catch (e) {
      // ignore: avoid_print
      print('CreateMemoryPreloadService: categories preload failed: $e');
    }

    _lastWarmAt = DateTime.now();
  }
}

