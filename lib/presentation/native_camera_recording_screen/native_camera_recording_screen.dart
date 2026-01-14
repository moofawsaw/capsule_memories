// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:image_picker/image_picker.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// import '../../core/app_export.dart';
// import '../../widgets/custom_image_view.dart';
// import '../post_story_screen/post_story_screen.dart';
//
// class NativeCameraRecordingScreen extends ConsumerStatefulWidget {
//   final String memoryId;
//   final String memoryTitle;
//   final String? categoryIcon;
//
//   const NativeCameraRecordingScreen({
//     Key? key,
//     required this.memoryId,
//     required this.memoryTitle,
//     this.categoryIcon,
//   }) : super(key: key);
//
//   @override
//   ConsumerState<NativeCameraRecordingScreen> createState() =>
//       _NativeCameraRecordingScreenState();
// }
//
// class _NativeCameraRecordingScreenState
//     extends ConsumerState<NativeCameraRecordingScreen> {
//   final ImagePicker _imagePicker = ImagePicker();
//   bool _isRecording = false;
//
//   bool _didStart = false;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_didStart) return;
//       _didStart = true;
//       _startVideoRecording();
//     });
//   }
//
//
//   Future<void> _startVideoRecording() async {
//     try {
//       // Request camera permission
//       if (!kIsWeb) {
//         final status = await Permission.camera.request();
//         if (!status.isGranted) {
//           _showError('Camera permission is required to record stories');
//           Navigator.pop(context);
//           return;
//         }
//       }
//
//       setState(() {
//         _isRecording = true;
//       });
//
//       // Open native camera for video recording
//       final XFile? video = await _imagePicker.pickVideo(
//         source: ImageSource.camera,
//         maxDuration: const Duration(seconds: 60), // 60 second limit
//       );
//
//       setState(() {
//         _isRecording = false;
//       });
//
//       if (video != null) {
//         // Video recorded successfully - navigate to story edit screen
//         _navigateToStoryEdit(video);
//       } else {
//         // User cancelled recording - go back
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       setState(() {
//         _isRecording = false;
//       });
//       _showError('Failed to record video: ${e.toString()}');
//       Navigator.pop(context);
//     }
//   }
//
//   void _navigateToStoryEdit(XFile video) {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (context) => PostStoryScreen(),
//         settings: RouteSettings(
//           arguments: {
//             'memory_id': widget.memoryId,
//             'memory_title': widget.memoryTitle,
//             'category_icon': widget.categoryIcon,
//             'video_path': video.path,
//             'is_video': true,
//           },
//         ),
//       ),
//     );
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: appTheme.red_500,
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: Stack(
//           children: [
//             // Camera loading state
//             if (_isRecording)
//               Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     CircularProgressIndicator(color: appTheme.deep_purple_A100),
//                     SizedBox(height: 24.h),
//                     Text(
//                       'Opening Camera...',
//                       style: TextStyleHelper.instance.title16BoldPlusJakartaSans
//                           .copyWith(color: appTheme.gray_50),
//                     ),
//                   ],
//                 ),
//               ),
//
//             // Header with back button and memory title
//             if (!_isRecording)
//               Positioned(
//                 top: 0,
//                 left: 0,
//                 right: 0,
//                 child: Container(
//                   padding: EdgeInsets.all(16.h),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       begin: Alignment.topCenter,
//                       end: Alignment.bottomCenter,
//                       colors: [
//                         Colors.black.withAlpha(179),
//                         Colors.transparent,
//                       ],
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       GestureDetector(
//                         onTap: () => Navigator.pop(context),
//                         child: Container(
//                           padding: EdgeInsets.all(8.h),
//                           decoration: BoxDecoration(
//                             color: Colors.black.withAlpha(128),
//                             borderRadius: BorderRadius.circular(20.h),
//                           ),
//                           child: Icon(
//                             Icons.arrow_back,
//                             color: appTheme.gray_50,
//                             size: 24.h,
//                           ),
//                         ),
//                       ),
//                       SizedBox(width: 12.h),
//                       if (widget.categoryIcon != null)
//                         CustomImageView(
//                           imagePath: widget.categoryIcon!,
//                           width: 24.h,
//                           height: 24.h,
//                           fit: BoxFit.contain,
//                         ),
//                       SizedBox(width: 8.h),
//                       Expanded(
//                         child: Text(
//                           widget.memoryTitle,
//                           style: TextStyleHelper
//                               .instance.title16BoldPlusJakartaSans
//                               .copyWith(color: appTheme.gray_50),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
