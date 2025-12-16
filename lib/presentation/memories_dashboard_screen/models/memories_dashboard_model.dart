import '../../../core/app_export.dart';
import 'story_item_model.dart';
import 'memory_item_model.dart';

/// This class is used in the [memories_dashboard_screen] screen.

// ignore_for_file: must_be_immutable
class MemoriesDashboardModel extends Equatable {
  MemoriesDashboardModel({
    this.storyItems,
    this.memoryItems,
    this.liveMemoryItems,
    this.sealedMemoryItems,
    this.allCount,
    this.liveCount,
    this.sealedCount,
  }) {
    storyItems = storyItems ?? [];
    memoryItems = memoryItems ?? [];
    liveMemoryItems = liveMemoryItems ?? [];
    sealedMemoryItems = sealedMemoryItems ?? [];
    allCount = allCount ?? 1;
    liveCount = liveCount ?? 1;
    sealedCount = sealedCount ?? 1;
  }

  List<StoryItemModel>? storyItems;
  List<MemoryItemModel>? memoryItems;
  List<MemoryItemModel>? liveMemoryItems;
  List<MemoryItemModel>? sealedMemoryItems;
  int? allCount;
  int? liveCount;
  int? sealedCount;

  MemoriesDashboardModel copyWith({
    List<StoryItemModel>? storyItems,
    List<MemoryItemModel>? memoryItems,
    List<MemoryItemModel>? liveMemoryItems,
    List<MemoryItemModel>? sealedMemoryItems,
    int? allCount,
    int? liveCount,
    int? sealedCount,
  }) {
    return MemoriesDashboardModel(
      storyItems: storyItems ?? this.storyItems,
      memoryItems: memoryItems ?? this.memoryItems,
      liveMemoryItems: liveMemoryItems ?? this.liveMemoryItems,
      sealedMemoryItems: sealedMemoryItems ?? this.sealedMemoryItems,
      allCount: allCount ?? this.allCount,
      liveCount: liveCount ?? this.liveCount,
      sealedCount: sealedCount ?? this.sealedCount,
    );
  }

  @override
  List<Object?> get props => [
        storyItems,
        memoryItems,
        liveMemoryItems,
        sealedMemoryItems,
        allCount,
        liveCount,
        sealedCount,
      ];
}
