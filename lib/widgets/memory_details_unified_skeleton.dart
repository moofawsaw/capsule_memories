// // lib/widgets/memory_details_unified_skeleton.dart
//
// import '../core/app_export.dart';
//
// /// One unified skeleton used by BOTH Open + Sealed screens.
// ///
// /// Usage:
// /// - Full-screen (no snapshot yet): MemoryDetailsUnifiedSkeleton.fullscreen()
// /// - Section-refresh (snapshot exists): use the individual section skeleton builders OR
// ///   call MemoryDetailsUnifiedSkeleton.sectionOnly(...)
// ///
// /// This matches the "section skeleton" style you liked and avoids breaking loaded layouts
// /// because it does NOT reuse your real header widget (CustomEventCard) while loading.
// class MemoryDetailsUnifiedSkeleton extends StatelessWidget {
//   const MemoryDetailsUnifiedSkeleton({
//     Key? key,
//     this.includeHeader = true,
//     this.includeTimeline = true,
//     this.includeStoriesTitle = true,
//     this.includeStoriesRow = true,
//     this.includeButtons = true,
//     this.includeFooterHint = true,
//   }) : super(key: key);
//
//   /// Which parts to show
//   final bool includeHeader;
//   final bool includeTimeline;
//   final bool includeStoriesTitle;
//   final bool includeStoriesRow;
//   final bool includeButtons;
//   final bool includeFooterHint;
//
//   /// Full-screen skeleton for first load (no snapshot yet).
//   factory MemoryDetailsUnifiedSkeleton.fullscreen() {
//     return const MemoryDetailsUnifiedSkeleton(
//       includeHeader: true,
//       includeTimeline: true,
//       includeStoriesTitle: true,
//       includeStoriesRow: true,
//       includeButtons: true,
//       includeFooterHint: false,
//     );
//   }
//
//   /// Use when snapshot exists but you're refreshing and want "section skeletons".
//   factory MemoryDetailsUnifiedSkeleton.sectionOnly({
//     bool header = true,
//     bool timeline = true,
//     bool storiesTitle = true,
//     bool storiesRow = true,
//     bool buttons = true,
//   }) {
//     return MemoryDetailsUnifiedSkeleton(
//       includeHeader: header,
//       includeTimeline: timeline,
//       includeStoriesTitle: storiesTitle,
//       includeStoriesRow: storiesRow,
//       includeButtons: buttons,
//       includeFooterHint: false,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       physics: const NeverScrollableScrollPhysics(),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(height: 12.h),
//           if (includeHeader) const _UnifiedHeaderSkeletonCard(),
//           if (includeHeader) SizedBox(height: 16.h),
//           if (includeTimeline) const _UnifiedTimelineSkeletonBlock(),
//           if (includeStoriesTitle || includeStoriesRow) SizedBox(height: 6.h),
//           if (includeStoriesTitle)
//             Padding(
//               padding: EdgeInsets.only(left: 20.h),
//               child: Container(
//                 height: 14.h,
//                 width: 120.h,
//                 decoration: BoxDecoration(
//                   color: appTheme.blue_gray_900,
//                   borderRadius: BorderRadius.circular(6.h),
//                 ),
//               ),
//             ),
//           if (includeStoriesTitle) SizedBox(height: 18.h),
//           if (includeStoriesRow) const _UnifiedStoriesSkeletonRow(),
//           if (includeStoriesRow) SizedBox(height: 18.h),
//           if (includeButtons) _UnifiedActionButtonsSkeleton(),
//           if (includeFooterHint) SizedBox(height: 14.h),
//           if (includeFooterHint)
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: 24.h),
//               child: Container(
//                 height: 14.h,
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   color: appTheme.blue_gray_900,
//                   borderRadius: BorderRadius.circular(6.h),
//                 ),
//               ),
//             ),
//           SizedBox(height: 20.h),
//         ],
//       ),
//     );
//   }
// }
//
// /// Header skeleton card (section-style; does NOT use CustomEventCard)
// class _UnifiedHeaderSkeletonCard extends StatelessWidget {
//   const _UnifiedHeaderSkeletonCard();
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 20.h),
//       child: Container(
//         padding: EdgeInsets.all(16.h),
//         decoration: BoxDecoration(
//           color: appTheme.blue_gray_300.withAlpha(77),
//           borderRadius: BorderRadius.circular(16.h),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   width: 44.h,
//                   height: 44.h,
//                   decoration: BoxDecoration(
//                     color: appTheme.blue_gray_900,
//                     borderRadius: BorderRadius.circular(14.h),
//                   ),
//                 ),
//                 SizedBox(width: 12.h),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Container(
//                         height: 14.h,
//                         width: 180.h,
//                         decoration: BoxDecoration(
//                           color: appTheme.blue_gray_900,
//                           borderRadius: BorderRadius.circular(6.h),
//                         ),
//                       ),
//                       SizedBox(height: 10.h),
//                       Container(
//                         height: 12.h,
//                         width: 140.h,
//                         decoration: BoxDecoration(
//                           color: appTheme.blue_gray_900,
//                           borderRadius: BorderRadius.circular(6.h),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 SizedBox(width: 12.h),
//                 Container(
//                   width: 56.h,
//                   height: 28.h,
//                   decoration: BoxDecoration(
//                     color: appTheme.blue_gray_900,
//                     borderRadius: BorderRadius.circular(999),
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 14.h),
//             Container(
//               height: 12.h,
//               width: 220.h,
//               decoration: BoxDecoration(
//                 color: appTheme.blue_gray_900,
//                 borderRadius: BorderRadius.circular(6.h),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// /// Timeline skeleton block (matches your section skeleton layout spacing)
// class _UnifiedTimelineSkeletonBlock extends StatelessWidget {
//   const _UnifiedTimelineSkeletonBlock();
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: EdgeInsets.only(top: 6.h),
//       padding: EdgeInsets.symmetric(horizontal: 16.h),
//       width: double.maxFinite,
//       child: Column(
//         children: [
//           SizedBox(height: 44.h),
//           Container(
//             height: 220.h,
//             width: double.maxFinite,
//             decoration: BoxDecoration(
//               color: appTheme.blue_gray_300.withAlpha(77),
//               borderRadius: BorderRadius.circular(16.h),
//             ),
//           ),
//           SizedBox(height: 16.h),
//           Container(
//             width: double.maxFinite,
//             height: 1,
//             color: appTheme.blue_gray_900,
//           ),
//           SizedBox(height: 16.h),
//         ],
//       ),
//     );
//   }
// }
//
// /// Stories row skeleton (section style)
// class _UnifiedStoriesSkeletonRow extends StatelessWidget {
//   const _UnifiedStoriesSkeletonRow();
//
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 120.h,
//       child: ListView.separated(
//         padding: EdgeInsets.only(left: 20.h, right: 20.h),
//         scrollDirection: Axis.horizontal,
//         physics: const NeverScrollableScrollPhysics(),
//         itemCount: 4,
//         separatorBuilder: (_, __) => SizedBox(width: 12.h),
//         itemBuilder: (_, __) {
//           return Container(
//             width: 110.h,
//             decoration: BoxDecoration(
//               // color: appTheme.blue_gray_300.withAlpha(77),
//               borderRadius: BorderRadius.circular(14.h),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
//
// /// Buttons skeleton (section style)
// class _UnifiedActionButtonsSkeleton extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 24.h),
//       child: Column(
//         children: [
//           Container(
//             height: 48.h,
//             width: double.infinity,
//             decoration: BoxDecoration(
//               color: appTheme.blue_gray_300.withAlpha(77),
//               borderRadius: BorderRadius.circular(14.h),
//             ),
//           ),
//           SizedBox(height: 12.h),
//           Container(
//             height: 48.h,
//             width: double.infinity,
//             decoration: BoxDecoration(
//               color: appTheme.blue_gray_300.withAlpha(77),
//               borderRadius: BorderRadius.circular(14.h),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
