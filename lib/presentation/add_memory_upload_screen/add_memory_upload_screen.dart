// lib/presentation/add_memory_upload_screen/add_memory_upload_screen.dart
// ✅ Change: after successful upload, close sheet and return to the memory timeline.
// ✅ Rule: DO NOT NAVIGATE unless uploadSuccess == true.
// ✅ If error, bottom sheet stays open automatically.

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_header_section.dart';
import '../../widgets/custom_image_view.dart';
import 'notifier/add_memory_upload_notifier.dart';

class AddMemoryUploadScreen extends ConsumerStatefulWidget {
  final String memoryId;
  final DateTime memoryStartDate;
  final DateTime memoryEndDate;

  AddMemoryUploadScreen({
    Key? key,
    required this.memoryId,
    required this.memoryStartDate,
    required this.memoryEndDate,
  }) : super(key: key);

  @override
  AddMemoryUploadScreenState createState() => AddMemoryUploadScreenState();
}

class AddMemoryUploadScreenState extends ConsumerState<AddMemoryUploadScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  static const int _maxBytes = 50 * 1024 * 1024;

  final DateFormat _readableDate = DateFormat('MMM d, yyyy');
  final DateFormat _readableDateTime = DateFormat('MMM d, yyyy • h:mm a');

  // ✅ Badge format: no year, show month/day + time
  final DateFormat _badgeDateTime = DateFormat('MMM d • h:mm a');

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '—';

    const int kb = 1024;
    const int mb = 1024 * 1024;

    if (bytes < kb) {
      return '$bytes B';
    } else if (bytes < mb) {
      final v = bytes / kb;
      return '${v.toStringAsFixed(v < 10 ? 1 : 0)} KB';
    } else {
      final v = bytes / mb;
      return '${v.toStringAsFixed(v < 10 ? 1 : 0)} MB';
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(addMemoryUploadNotifier.notifier).setMemoryDetails(
        memoryId: widget.memoryId,
        startDate: widget.memoryStartDate,
        endDate: widget.memoryEndDate,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.maxFinite,
        decoration: BoxDecoration(
          color: appTheme.gray_900_02,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.h),
            topRight: Radius.circular(20.h),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12.h),
            Container(
              width: 48.h,
              height: 5.h,
              decoration: BoxDecoration(
                color: appTheme.colorFF3A3A,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.h),
                child: _buildContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Force a correct size (fixes 0.0 MB) + preserve bytes if present
  Future<PlatformFile> _withAccurateSize(PlatformFile file) async {
    if (file.size > 0) return file;

    final bytesLen = file.bytes?.length ?? 0;
    if (bytesLen > 0) {
      return PlatformFile(
        name: file.name,
        path: file.path,
        size: bytesLen,
        bytes: file.bytes,
        identifier: file.identifier,
      );
    }

    final p = file.path;
    if (p == null || p.isEmpty || kIsWeb) return file;

    try {
      final f = File(p);
      if (await f.exists()) {
        final len = await f.length();
        if (len > 0) {
          return PlatformFile(
            name: file.name,
            path: p,
            size: len,
            bytes: file.bytes,
            identifier: file.identifier,
          );
        }

        final data = await f.readAsBytes();
        if (data.isNotEmpty) {
          return PlatformFile(
            name: file.name,
            path: p,
            size: data.length,
            bytes: file.bytes,
            identifier: file.identifier,
          );
        }
      }
    } catch (_) {}

    return file;
  }

  /// ✅ Ensure we have a readable local file path for metadata validation + upload.
  /// Fixes "Unable to read file" when picker returns content:// or inaccessible paths.
  Future<PlatformFile> _ensureReadableLocalPath(PlatformFile file) async {
    if (kIsWeb) return file;

    final String? p = file.path;
    final Uint8List? b = file.bytes;

    if (p != null && p.isNotEmpty) {
      try {
        final f = File(p);
        if (await f.exists()) return file;
      } catch (_) {}
    }

    if (b != null && b.isNotEmpty) {
      try {
        final dir = await getTemporaryDirectory();
        final safeName = file.name.isNotEmpty
            ? file.name
            : 'upload_${DateTime.now().millisecondsSinceEpoch}';
        final outPath = '${dir.path}/$safeName';
        final outFile = File(outPath);
        await outFile.writeAsBytes(b, flush: true);

        final len = await outFile.length();
        return PlatformFile(
          name: safeName,
          path: outPath,
          size: len > 0 ? len : file.size,
          bytes: b,
          identifier: file.identifier, // ✅ keep original content:// here
        );
      } catch (_) {
        return file;
      }
    }

    return file;
  }

  bool _looksLikeImage(String nameOrPath) {
    final v = nameOrPath.toLowerCase();
    return RegExp(r'\.(jpg|jpeg|png|gif|bmp|webp)$').hasMatch(v);
  }

  Widget _buildSelectedImagePreview(PlatformFile file) {
    final bytes = file.bytes;

    // ✅ Prefer bytes when available (works on web and fixes unreadable path previews)
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildUploadIcon(),
      );
    }

    // ✅ Fallback to file path when readable
    if (!kIsWeb) {
      final p = file.path;
      if (p != null && p.isNotEmpty) {
        return Image.file(
          File(p),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildUploadIcon(),
        );
      }
    }

    return _buildUploadIcon();
  }

  TextSpan _buildWindowSpan(DateTime dt) {
    final local = dt.toLocal();

    final String monthDay = DateFormat('MMM d').format(local); // bold
    final String time = DateFormat(' • h:mm a').format(local); // regular

    return TextSpan(
      children: [
        TextSpan(
          text: monthDay,
          style: TextStyleHelper.instance.body14BoldPlusJakartaSans
              .copyWith(color: appTheme.blue_gray_300, height: 1.25),
        ),
        TextSpan(
          text: time,
          style: TextStyleHelper.instance.body14RegularPlusJakartaSans
              .copyWith(color: appTheme.blue_gray_300, height: 1.25),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(addMemoryUploadNotifier);

        final memoryName =
        (state.memoryName != null && state.memoryName!.trim().isNotEmpty)
            ? state.memoryName!.trim()
            : 'this memory';

        final start = state.memoryStartDate ?? widget.memoryStartDate;
        final end = state.memoryEndDate ?? widget.memoryEndDate;

        return Column(
          children: [
            CustomHeaderSection(
              title: 'Add to Memory',
              description:
              'Upload a photo or video from your device to add to "$memoryName"',
              margin: EdgeInsets.only(top: 32.h, left: 42.h, right: 42.h),
            ),
            Padding(
              padding: EdgeInsets.only(top: 10.h, left: 42.h, right: 42.h),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 14.h, vertical: 10.h),
                decoration: BoxDecoration(
                  color: appTheme.gray_900,
                  borderRadius: BorderRadius.circular(12.h),
                  border: Border.all(color: appTheme.colorFF3A3A, width: 1.h),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Acceptable capture window',
                      style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                          .copyWith(color: appTheme.gray_50),
                    ),
                    SizedBox(height: 6.h),
                    RichText(
                      text: TextSpan(
                        children: [
                          _buildWindowSpan(start),
                          TextSpan(
                            text: '  →  ',
                            style: TextStyleHelper
                                .instance.body14RegularPlusJakartaSans
                                .copyWith(
                              color: appTheme.blue_gray_300,
                              height: 1.25,
                            ),
                          ),
                          _buildWindowSpan(end),
                        ],
                      ),
                    ),
                    SizedBox(height: 6.h),
                  ],
                ),
              ),
            ),
            _buildUploadSection(context),
            _buildActionButtons(context),
          ],
        );
      },
    );
  }

  // ✅ Badge: no year, month/day + time only
  Widget _buildCaptureWindowBadge(DateTime start, DateTime end) {
    final startLocal = start.toLocal();
    final endLocal = end.toLocal();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 8.h),
      decoration: BoxDecoration(
        color: appTheme.gray_900,
        borderRadius: BorderRadius.circular(999.h),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: 16.h,
            color: appTheme.blue_gray_300,
          ),
          SizedBox(width: 6.h),
          Text(
            '${_badgeDateTime.format(startLocal)} – ${_badgeDateTime.format(endLocal)}',
            textAlign: TextAlign.center,
            style: TextStyleHelper.instance.body14MediumPlusJakartaSans
                .copyWith(color: appTheme.blue_gray_300),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(addMemoryUploadNotifier);

        final selected = state.selectedFile;

        final bool isImageSelected = selected != null &&
            (_looksLikeImage(selected.path ?? '') || _looksLikeImage(selected.name));

        return GestureDetector(
          onTap: _pickMediaFromGallery,
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: 26.h),
            padding: EdgeInsets.symmetric(vertical: 34.h),
            decoration: BoxDecoration(
              color: appTheme.colorF716A8,
              border: Border.all(
                color: appTheme.deep_purple_A100,
                width: 2.h,
              ),
              borderRadius: BorderRadius.circular(12.h),
            ),
            child: Column(
              children: [
                if (isImageSelected && selected != null)
                  Container(
                    height: 120.h,
                    width: 120.h,
                    margin: EdgeInsets.only(bottom: 12.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.h),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.h),
                      child: _buildSelectedImagePreview(selected),
                    ),
                  )
                else if (selected != null)
                  Container(
                    padding: EdgeInsets.all(16.h),
                    margin: EdgeInsets.only(bottom: 12.h),
                    decoration: BoxDecoration(
                      color: appTheme.gray_900,
                      borderRadius: BorderRadius.circular(8.h),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.insert_drive_file_outlined,
                          size: 20.h,
                          color: appTheme.gray_50,
                        ),
                        SizedBox(width: 8.h),
                        Flexible(
                          child: Text(
                            selected.name,
                            style:
                            TextStyleHelper.instance.body14MediumPlusJakartaSans,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  _buildUploadIcon(),
                if (state.captureTimestamp != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Text(
                      'Captured: ${_formatReadableDateTime(state.captureTimestamp!)}',
                      textAlign: TextAlign.center,
                      style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                          .copyWith(color: appTheme.gray_50),
                    ),
                  ),
                if (selected != null) ...[
                  Padding(
                    padding: EdgeInsets.only(bottom: 6.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (state.isWithinMemoryWindow != true) ...[
                          Icon(
                            Icons.info_outline,
                            size: 16.h,
                            color: appTheme.red_500,
                          ),
                          SizedBox(width: 6.h),
                        ],
                        Text(
                          (state.isWithinMemoryWindow == true)
                              ? 'Ready to upload'
                              : 'Outside memory window',
                          textAlign: TextAlign.center,
                          style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                              .copyWith(
                            color: (state.isWithinMemoryWindow == true)
                                ? appTheme.gray_50
                                : appTheme.red_500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state.errorMessage != null && state.errorMessage!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(
                        left: 18.h,
                        right: 18.h,
                        bottom: 10.h,
                      ),
                      child: Text(
                        state.errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                            .copyWith(color: appTheme.red_500, height: 1.35),
                      ),
                    ),
                  // ✅ Badge (no year)
                  if (state.isWithinMemoryWindow == false &&
                      state.memoryStartDate != null &&
                      state.memoryEndDate != null) ...[
                    SizedBox(height: 6.h),
                    _buildCaptureWindowBadge(
                      state.memoryStartDate!,
                      state.memoryEndDate!,
                    ),
                    SizedBox(height: 10.h),
                  ],
                ],
                Text(
                  selected != null ? 'File Selected' : 'Choose file',
                  style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                ),
                SizedBox(height: 4.h),
                Text(
                  selected != null ? _formatFileSize(selected.size) : 'Photo or video up to 50MB',
                  style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                      .copyWith(color: appTheme.blue_gray_300),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUploadIcon() {
    return CustomIconButton(
      icon: Icons.upload_file,
      backgroundColor: appTheme.color41C124,
      height: 62.h,
      width: 62.h,
      borderRadius: 30.h,
      padding: EdgeInsets.all(12.h),
      iconColor: appTheme.deep_purple_A100,
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(addMemoryUploadNotifier);

        final bool canUpload = state.selectedFile != null &&
            (state.isWithinMemoryWindow == true) &&
            (state.isUploading ?? false) == false;

        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: 20.h, bottom: 12.h),
          child: Row(
            spacing: 12.h,
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Cancel',
                  onPressed: () => _onTapCancel(context),
                  buttonStyle: CustomButtonStyle.outlineDark,
                  buttonTextStyle: CustomButtonTextStyle.bodySmallPrimary,
                ),
              ),
              Expanded(
                child: CustomButton(
                  text: (state.isUploading ?? false) ? 'Uploading...' : 'Add to Memory',
                  leftIcon: (state.isUploading ?? false) ? null : Icons.add,
                  onPressed: canUpload ? () => _onTapAddToMemory(context) : null,
                  buttonStyle: CustomButtonStyle.fillPrimary,
                  buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                  isDisabled: !canUpload,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickMediaFromGallery() async {
    final notifier = ref.read(addMemoryUploadNotifier.notifier);

    try {
      // =========================
      // 1) Try ImagePicker first (mobile)
      // =========================
      if (!kIsWeb) {
        try {
          final XFile? picked = await (_imagePicker as dynamic).pickMedia();
          if (picked != null) {
            // bytes (also fixes "unable to read file" when path is content://)
            Uint8List? data;
            try {
              data = await picked.readAsBytes();
            } catch (_) {}

            int bytes = 0;
            try {
              bytes = await picked.length();
            } catch (_) {}

            if (bytes <= 0 && data != null) {
              bytes = data.length;
            }

            if (bytes > _maxBytes) {
              notifier.setError('File size must be less than 50MB');
              return;
            }

            // Prefer a readable local file path:
            // - if picked.path is readable, keep it
            // - else write bytes into temp and use that path
            String? usablePath = picked.path;
            bool pathOk = false;

            if (usablePath.isNotEmpty) {
              try {
                final f = File(usablePath);
                pathOk = await f.exists();
              } catch (_) {
                pathOk = false;
              }
            }

            if (!pathOk && data != null && data.isNotEmpty) {
              try {
                final dir = await getTemporaryDirectory();
                final name = picked.name.isNotEmpty
                    ? picked.name
                    : 'upload_${DateTime.now().millisecondsSinceEpoch}';
                final outPath = '${dir.path}/$name';
                final outFile = File(outPath);
                await outFile.writeAsBytes(data, flush: true);
                usablePath = outPath;
                bytes = await outFile.length();
              } catch (_) {
                // if temp write fails, continue with original path
              }
            }

            var raw = PlatformFile(
              name: picked.name,
              path: usablePath,
              size: bytes,
              bytes: data, // keep for preview fallback
            );

            raw = await _withAccurateSize(raw);
            raw = await _ensureReadableLocalPath(raw);

            notifier.setSelectedFile(raw);
            await notifier.validateFileMetadata();
            return;
          }
        } catch (_) {
          // fall through
        }
      }

      // =========================
      // 2) Fallback to FilePicker (web + desktop + some mobile cases)
      // =========================
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.media,
        allowMultiple: false,
        withData: true, // ✅ allows file.bytes on platforms that support it
      );

      if (result != null && result.files.isNotEmpty) {
        var raw = result.files.first;

        raw = await _withAccurateSize(raw);

        if (raw.size > _maxBytes) {
          notifier.setError('File size must be less than 50MB');
          return;
        }

        // ✅ Ensure local readable path (mobile) / keep bytes (web)
        raw = await _ensureReadableLocalPath(raw);

        notifier.setSelectedFile(raw);
        await notifier.validateFileMetadata();
      }
    } catch (e) {
      notifier.setError('Failed to select media: ${e.toString()}');
    }
  }

  void _onTapCancel(BuildContext context) {
    NavigatorService.goBack();
  }

  /// ✅ Only redirect if upload was a success.
  /// If error occurs, bottom sheet stays open.
  Future<void> _onTapAddToMemory(BuildContext context) async {
    final state = ref.read(addMemoryUploadNotifier);

    if (state.selectedFile == null) {
      ref.read(addMemoryUploadNotifier.notifier).setError('Please select a file first');
      return;
    }

    if (state.isWithinMemoryWindow != true) {
      ref.read(addMemoryUploadNotifier.notifier).setError(
        state.errorMessage ??
            'This media is outside the memory window and cannot be uploaded.',
      );
      return;
    }

    await ref.read(addMemoryUploadNotifier.notifier).uploadFile();

    final after = ref.read(addMemoryUploadNotifier);

    // ✅ DO NOT NAVIGATE unless uploadSuccess == true
    if (after.uploadSuccess == true) {
      // 1) Close the upload bottom sheet
      NavigatorService.goBack();

      // 2) Then ensure we're on the memory timeline for this memory
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final nav = NavigatorService.navigatorKey.currentState;
        if (nav == null) return;

        bool foundTimeline = false;

        nav.popUntil((route) {
          if (route.settings.name == AppRoutes.appTimeline) {
            foundTimeline = true;
            return true;
          }
          return false;
        });

        // If timeline isn't in the stack, push it with the correct memoryId
        if (!foundTimeline) {
          NavigatorService.pushNamed(
            AppRoutes.appTimeline,
            arguments: {'memoryId': widget.memoryId},
          );
        }
      });
    }
    // else: do nothing; error remains visible and sheet stays open
  }

  String _formatReadableDate(DateTime dt) {
    return _readableDate.format(dt.toLocal());
  }

  String _formatReadableDateTime(DateTime dt) {
    return _readableDateTime.format(dt.toLocal());
  }
}