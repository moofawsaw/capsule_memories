// lib/presentation/add_memory_upload_screen/add_memory_upload_screen.dart
// Only change here is: DO NOT NAVIGATE unless uploadSuccess == true.
// If there is an error, bottom sheet stays open automatically.

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

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
                    Text(
                      '${_formatReadableDateTime(start)}  →  ${_formatReadableDateTime(end)}',
                      style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                          .copyWith(color: appTheme.blue_gray_300, height: 1.25),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      '(${_formatReadableDate(start)} to ${_formatReadableDate(end)})',
                      style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                          .copyWith(color: appTheme.blue_gray_300, height: 1.25),
                    ),
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

  Widget _buildUploadSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(addMemoryUploadNotifier);

        final bool isImageSelected = state.selectedFile != null &&
            (state.selectedFile!.path?.toLowerCase().contains(
              RegExp(r'\.(jpg|jpeg|png|gif|bmp|webp)$'),
            ) ==
                true);

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
                if (isImageSelected)
                  Container(
                    height: 120.h,
                    width: 120.h,
                    margin: EdgeInsets.only(bottom: 12.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.h),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.h),
                      child: kIsWeb
                          ? Image.network(
                        state.selectedFile!.path ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildUploadIcon(),
                      )
                          : Image.file(
                        File(state.selectedFile!.path ?? ''),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildUploadIcon(),
                      ),
                    ),
                  )
                else if (state.selectedFile != null)
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
                        CustomImageView(
                          imagePath: ImageConstant.imgIconWhiteA700,
                          height: 20.h,
                          width: 20.h,
                        ),
                        SizedBox(width: 8.h),
                        Flexible(
                          child: Text(
                            state.selectedFile!.name,
                            style: TextStyleHelper
                                .instance.body14MediumPlusJakartaSans,
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

                if (state.selectedFile != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: Text(
                      (state.isWithinMemoryWindow == true)
                          ? 'Ready to upload (within memory window)'
                          : 'Not eligible to upload (outside memory window)',
                      textAlign: TextAlign.center,
                      style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                          .copyWith(
                        color: (state.isWithinMemoryWindow == true)
                            ? appTheme.gray_50
                            : appTheme.red_500,
                      ),
                    ),
                  ),

                if (state.errorMessage != null && state.errorMessage!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: Text(
                      state.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                          .copyWith(color: appTheme.red_500, height: 1.25),
                    ),
                  ),

                Text(
                  state.selectedFile != null ? 'File Selected' : 'Choose file',
                  style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                ),
                SizedBox(height: 4.h),
                Text(
                  state.selectedFile != null
                      ? '${(state.selectedFile!.size / (1024 * 1024)).toStringAsFixed(1)} MB'
                      : 'Photo or video up to 50MB',
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
      iconPath: ImageConstant.imgFrameDeepPurpleA100,
      backgroundColor: appTheme.color41C124,
      height: 62.h,
      width: 62.h,
      borderRadius: 30.h,
      padding: EdgeInsets.all(12.h),
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
                  buttonStyle: CustomButtonStyle.fillDark,
                  buttonTextStyle: CustomButtonTextStyle.bodySmallPrimary,
                ),
              ),
              Expanded(
                child: CustomButton(
                  text: (state.isUploading ?? false)
                      ? 'Uploading...'
                      : 'Add to Memory',
                  leftIcon: (state.isUploading ?? false)
                      ? null
                      : ImageConstant.imgIconWhiteA700,
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
      if (!kIsWeb) {
        try {
          final XFile? picked = await (_imagePicker as dynamic).pickMedia();
          if (picked != null) {
            final int bytes = await picked.length();
            if (bytes > _maxBytes) {
              notifier.setError('File size must be less than 50MB');
              return;
            }

            final file = PlatformFile(
              name: picked.name,
              path: picked.path,
              size: bytes,
            );

            notifier.setSelectedFile(file);
            await notifier.validateFileMetadata();
            return;
          }
        } catch (_) {
          // fall through
        }
      }

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.media,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        if (file.size > _maxBytes) {
          notifier.setError('File size must be less than 50MB');
          return;
        }

        notifier.setSelectedFile(file);
        await notifier.validateFileMetadata();
      }
    } catch (e) {
      notifier.setError('Failed to select media: ${e.toString()}');
    }
  }

  void _onTapCancel(BuildContext context) {
    NavigatorService.goBack();
  }

  /// ✅ Only redirect if story creation was a success.
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

    if (after.uploadSuccess == true) {
      NavigatorService.pushNamed(AppRoutes.appHome);
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
