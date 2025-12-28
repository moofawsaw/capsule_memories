import '../../core/app_export.dart';
import '../../presentation/memories_dashboard_screen/models/memory_item_model.dart';
import './memory_nav_args.dart';

/// Validated navigation wrapper for memory card taps site-wide
///
/// This ensures consistent MemoryNavArgs structure across all memory navigations
/// preventing data inconsistencies and dummy content fallbacks.
///
/// Usage:
/// ```dart
/// MemoryNavigationWrapper.navigateToTimeline(
///   context: context,
///   memoryId: 'memory-123',
///   title: 'Summer Trip',
///   date: 'Jun 15, 2025',
///   // ... other snapshot data
/// );
/// ```
class MemoryNavigationWrapper {
  /// Navigate to timeline with validated MemoryNavArgs
  ///
  /// Prevents inconsistent data passing by enforcing structured navigation.
  /// All memory card taps must use this wrapper to maintain consistency.
  static void navigateToTimeline({
    required BuildContext context,
    required String memoryId,
    String? title,
    String? date,
    String? location,
    String? categoryIcon,
    List<String>? participantAvatars,
    bool isPrivate = false,
    bool isSealed = false,
  }) {
    // Validate memory ID
    if (memoryId.isEmpty) {
      print('❌ NAVIGATION WRAPPER: Cannot navigate without memory ID');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to open memory - missing ID'),
          backgroundColor: appTheme.red_500,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Create validated MemoryNavArgs
    final navArgs = MemoryNavArgs(
      memoryId: memoryId,
      snapshot: MemorySnapshot(
        title: title ?? 'Memory',
        date: date ?? '',
        location: location,
        categoryIcon: categoryIcon,
        participantAvatars: participantAvatars,
        isPrivate: isPrivate,
      ),
    );

    print('✅ NAVIGATION WRAPPER: Passing validated MemoryNavArgs');
    print('   - Memory ID: ${navArgs.memoryId}');
    print('   - Snapshot title: ${navArgs.snapshot?.title}');

    // Navigate based on memory status
    if (isSealed) {
      NavigatorService.pushNamed(
        AppRoutes.appTimelineSealed,
        arguments: navArgs,
      );
    } else {
      NavigatorService.pushNamed(
        AppRoutes.appTimeline,
        arguments: navArgs,
      );
    }
  }

  /// Navigate to timeline from MemoryItemModel (used in /memories)
  ///
  /// Converts memory item model to validated MemoryNavArgs structure.
  static void navigateFromMemoryItem({
    required BuildContext context,
    required dynamic memoryItem,
  }) {
    // Handle MemoryItemModel type explicitly
    if (memoryItem is MemoryItemModel) {
      _navigateFromMemoryItemModel(context, memoryItem);
      return;
    }

    // Handle Map type
    if (memoryItem is Map<String, dynamic>) {
      navigateFromMap(context: context, memoryData: memoryItem);
      return;
    }

    // Unknown type - show error
    print(
        '❌ NAVIGATION WRAPPER: Invalid memory item type: ${memoryItem.runtimeType}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unable to open memory - invalid data type'),
        backgroundColor: appTheme.red_500,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Internal: Navigate from MemoryItemModel
  static void _navigateFromMemoryItemModel(
    BuildContext context,
    MemoryItemModel memoryItem,
  ) {
    final memoryId = memoryItem.id;
    if (memoryId == null || memoryId.isEmpty) {
      print('❌ NAVIGATION WRAPPER: Invalid memory item - missing ID');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to open memory - invalid data'),
          backgroundColor: appTheme.red_500,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    navigateToTimeline(
      context: context,
      memoryId: memoryId,
      title: memoryItem.title,
      date: memoryItem.date,
      location: memoryItem.location,
      categoryIcon: memoryItem.categoryIconUrl,
      participantAvatars: memoryItem.participantAvatars,
      isPrivate: memoryItem.visibility == 'private',
      isSealed: memoryItem.isSealed ?? false,
    );
  }

  /// Navigate to timeline from Map (used in /feed)
  ///
  /// Validates and restructures flat Map into proper MemoryNavArgs format.
  /// Prevents the issue where feed passes flat Map without nested 'snapshot' key.
  static void navigateFromMap({
    required BuildContext context,
    required Map<String, dynamic> memoryData,
  }) {
    // Validate memory ID
    final memoryId = memoryData['id'] as String?;
    if (memoryId == null || memoryId.isEmpty) {
      print('❌ NAVIGATION WRAPPER: Cannot navigate from map without ID');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to open memory - missing ID'),
          backgroundColor: appTheme.red_500,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Extract snapshot data from flat or nested structure
    final title = memoryData['title'] as String?;
    final date = memoryData['date'] as String?;
    final location = memoryData['location'] as String?;
    final categoryIcon = memoryData['category_icon'] as String? ??
        memoryData['categoryIconUrl'] as String?;
    final participantAvatars = _extractAvatarsFromMap(memoryData);
    final visibility = memoryData['visibility'] as String?;
    final isSealed =
        memoryData['is_sealed'] == true || memoryData['isSealed'] == true;

    navigateToTimeline(
      context: context,
      memoryId: memoryId,
      title: title,
      date: date,
      location: location,
      categoryIcon: categoryIcon,
      participantAvatars: participantAvatars,
      isPrivate: visibility == 'private',
      isSealed: isSealed,
    );
  }

  /// Helper: Extract avatar list from map
  static List<String>? _extractAvatarsFromMap(Map<String, dynamic> map) {
    // Try different possible field names for avatars
    final avatarsData = map['contributor_avatars'] ??
        map['profileImages'] ??
        map['participantAvatars'] ??
        map['participant_avatars'];

    if (avatarsData == null) return null;

    if (avatarsData is List) {
      return avatarsData.map((e) => e.toString()).toList();
    }

    return null;
  }
}
