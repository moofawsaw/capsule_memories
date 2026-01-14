// import '../../core/app_export.dart';
// import '../../widgets/custom_image_view.dart';
// import '../native_camera_recording_screen/native_camera_recording_screen.dart';
// import './models/memory_selection_model.dart';
// import 'notifier/memory_selection_notifier.dart';
//
// class MemorySelectionBottomSheet extends ConsumerStatefulWidget {
//   const MemorySelectionBottomSheet({Key? key}) : super(key: key);
//
//   @override
//   ConsumerState<MemorySelectionBottomSheet> createState() =>
//       _MemorySelectionBottomSheetState();
// }
//
// class _MemorySelectionBottomSheetState
//     extends ConsumerState<MemorySelectionBottomSheet> {
//   String? selectedMemoryId;
//
//   @override
//   void initState() {
//     super.initState();
//     // Load active memories when bottom sheet opens
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       ref.read(memorySelectionProvider.notifier).loadActiveMemories();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: appTheme.gray_900_02,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24.h)),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           _buildHeader(context),
//           _buildSearchBar(context),
//           _buildMemoriesList(context),
//           _buildContinueButton(context),
//           SizedBox(height: 12.h),
//         ],
//       ),
//     );
//   }
//
//   /// Drag handle and header
//   Widget _buildHeader(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 16.h),
//       child: Column(
//         children: [
//           // Drag handle
//           Container(
//             width: 40.h,
//             height: 4.h,
//             decoration: BoxDecoration(
//               color: appTheme.blue_gray_300,
//               borderRadius: BorderRadius.circular(2.h),
//             ),
//           ),
//           SizedBox(height: 20.h),
//           // Header with close button
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Add Story To',
//                 style: TextStyleHelper.instance.title20BoldPlusJakartaSans
//                     .copyWith(color: appTheme.gray_50),
//               ),
//               GestureDetector(
//                 onTap: () => Navigator.pop(context),
//                 child: Container(
//                   padding: EdgeInsets.all(8.h),
//                   decoration: BoxDecoration(
//                     color: appTheme.blue_gray_900_01,
//                     borderRadius: BorderRadius.circular(20.h),
//                   ),
//                   child: Icon(
//                     Icons.close,
//                     size: 20.h,
//                     color: appTheme.gray_50,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// Search bar for filtering memories
//   Widget _buildSearchBar(BuildContext context) {
//     final state = ref.watch(memorySelectionProvider);
//
//     if ((state.activeMemories?.length ?? 0) < 5) {
//       return SizedBox.shrink(); // Hide search for small lists
//     }
//
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: 24.h, vertical: 12.h),
//       child: TextField(
//         style: TextStyleHelper.instance.body14MediumPlusJakartaSans
//             .copyWith(color: appTheme.gray_50),
//         decoration: InputDecoration(
//           hintText: 'Search memories...',
//           hintStyle: TextStyleHelper.instance.body14MediumPlusJakartaSans
//               .copyWith(color: appTheme.blue_gray_300),
//           prefixIcon: Icon(Icons.search, color: appTheme.blue_gray_300),
//           filled: true,
//           fillColor: appTheme.blue_gray_900_01,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12.h),
//             borderSide: BorderSide.none,
//           ),
//           contentPadding:
//               EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h),
//         ),
//         onChanged: (value) {
//           ref.read(memorySelectionProvider.notifier).filterMemories(value);
//         },
//       ),
//     );
//   }
//
//   /// List of active memories
//   Widget _buildMemoriesList(BuildContext context) {
//     return Consumer(
//       builder: (context, ref, _) {
//         final state = ref.watch(memorySelectionProvider);
//
//         if (state.isLoading) {
//           return Container(
//             height: 200.h,
//             alignment: Alignment.center,
//             child: CircularProgressIndicator(color: appTheme.deep_purple_A100),
//           );
//         }
//
//         // Use filtered memories if search is active, otherwise use active memories
//         final memoriesToDisplay = state.searchQuery?.isNotEmpty ?? false
//             ? state.filteredMemories
//             : state.activeMemories;
//
//         if (memoriesToDisplay?.isEmpty ?? true) {
//           return _buildEmptyState(context);
//         }
//
//         return Container(
//           constraints: BoxConstraints(maxHeight: 400.h),
//           child: ListView.separated(
//             shrinkWrap: true,
//             padding: EdgeInsets.symmetric(horizontal: 24.h),
//             itemCount: memoriesToDisplay!.length,
//             separatorBuilder: (context, index) => SizedBox(height: 12.h),
//             itemBuilder: (context, index) {
//               final memory = memoriesToDisplay[index];
//               final isSelected = selectedMemoryId == memory.id;
//               final isPublic = memory.visibility == 'public';
//
//               // Debug logging
//               print(
//                   '🔍 Memory: ${memory.title}, Visibility: ${memory.visibility}, isPublic: $isPublic');
//
//               return GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     selectedMemoryId = memory.id;
//                   });
//                 },
//                 child: Container(
//                   padding: EdgeInsets.all(16.h),
//                   decoration: BoxDecoration(
//                     color: appTheme.blue_gray_900_01,
//                     borderRadius: BorderRadius.circular(12.h),
//                     border: Border.all(
//                       color: isSelected
//                           ? appTheme.deep_purple_A100
//                           : appTheme.blue_gray_300.withAlpha(51),
//                       width: isSelected ? 2 : 1,
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       // Category icon
//                       if (memory.categoryIcon?.isNotEmpty ?? false)
//                         CustomImageView(
//                           imagePath: memory.categoryIcon!,
//                           width: 40.h,
//                           height: 40.h,
//                           fit: BoxFit.contain,
//                         ),
//                       SizedBox(width: 12.h),
//                       // Memory details
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               memory.title ?? 'Untitled Memory',
//                               style: TextStyleHelper
//                                   .instance.title16BoldPlusJakartaSans
//                                   .copyWith(color: appTheme.gray_50),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                             SizedBox(height: 4.h),
//                             Row(
//                               children: [
//                                 Icon(
//                                   Icons.access_time,
//                                   size: 14.h,
//                                   color: appTheme.blue_gray_300,
//                                 ),
//                                 SizedBox(width: 4.h),
//                                 Text(
//                                   memory.timeRemaining ?? '',
//                                   style: TextStyleHelper
//                                       .instance.body12MediumPlusJakartaSans
//                                       .copyWith(color: appTheme.blue_gray_300),
//                                 ),
//                                 SizedBox(width: 12.h),
//                                 Icon(
//                                   Icons.people,
//                                   size: 14.h,
//                                   color: appTheme.blue_gray_300,
//                                 ),
//                                 SizedBox(width: 4.h),
//                                 Text(
//                                   '${memory.memberCount ?? 0} members',
//                                   style: TextStyleHelper
//                                       .instance.body12MediumPlusJakartaSans
//                                       .copyWith(color: appTheme.blue_gray_300),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                       // Visibility icon
//                       Icon(
//                         isPublic ? Icons.public : Icons.lock,
//                         size: 20.h,
//                         color: isPublic ? Colors.green : Colors.pink,
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         );
//       },
//     );
//   }
//
//   /// Empty state when no active memories
//   Widget _buildEmptyState(BuildContext context) {
//     return Container(
//       height: 200.h,
//       alignment: Alignment.center,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.folder_open,
//             size: 64.h,
//             color: appTheme.blue_gray_300,
//           ),
//           SizedBox(height: 16.h),
//           Text(
//             'No Active Memories',
//             style: TextStyleHelper.instance.title16BoldPlusJakartaSans
//                 .copyWith(color: appTheme.gray_50),
//           ),
//           SizedBox(height: 8.h),
//           Text(
//             'Create a memory first to add stories',
//             style: TextStyleHelper.instance.body14MediumPlusJakartaSans
//                 .copyWith(color: appTheme.blue_gray_300),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// Continue button
//   Widget _buildContinueButton(BuildContext context) {
//     return Container(
//       margin: EdgeInsets.fromLTRB(24.h, 16.h, 24.h, 0),
//       child: Column(
//         children: [
//           ElevatedButton(
//             onPressed: selectedMemoryId != null
//                 ? () {
//                     final state = ref.read(memorySelectionProvider);
//                     final selectedMemory = state.activeMemories?.firstWhere(
//                       (m) => m.id == selectedMemoryId,
//                       orElse: () => MemoryItem(),
//                     );
//
//                     // Close bottom sheet and navigate to camera
//                     Navigator.pop(context);
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => NativeCameraRecordingScreen(
//                           memoryId: selectedMemoryId!,
//                           memoryTitle: selectedMemory?.title ?? '',
//                           categoryIcon: selectedMemory?.categoryIcon,
//                         ),
//                       ),
//                     );
//                   }
//                 : null,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: appTheme.deep_purple_A100,
//               disabledBackgroundColor: appTheme.blue_gray_300,
//               padding: EdgeInsets.symmetric(vertical: 16.h),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12.h),
//               ),
//               minimumSize: Size(double.infinity, 48.h),
//             ),
//             child: Text(
//               'Continue',
//               style: TextStyleHelper.instance.title16BoldPlusJakartaSans
//                   .copyWith(
//                       color: selectedMemoryId != null
//                           ? appTheme.gray_50
//                           : appTheme.gray_900),
//             ),
//           ),
//           SizedBox(height: 12.h),
//           Text(
//             'Stories will be added to the selected memory timeline',
//             style: TextStyleHelper.instance.body12MediumPlusJakartaSans
//                 .copyWith(color: appTheme.blue_gray_300),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
// }
